#! /bin/bash
echo "starting script..."
echo ""

# Check for variable spelling, case-sensitive and variants
[[ ! -z "$gp_username" ]] && GP_USERNAME=$gp_username
[[ ! -z "$user" ]] && GP_USERNAME=$user
[[ ! -z "$gp_password" ]] && GP_PASSWORD=$gp_password
[[ ! -z "$pass" ]] && GP_PASSWORD=$pass
[[ ! -z "$gp_gateway" ]] && GP_GATEWAY=$gp_gateway
[[ ! -z "$gateway" ]] && GP_GATEWAY=$gateway
[[ ! -z "$nameserver" ]] && NAMESERVER=$nameserver
[[ ! -z "$nmap_target" ]] && NMAP_TARGET=$nmap_target
[[ ! -z "$smtp" ]] && SMTP=$smtp
[[ ! -z "$iftop" ]] && IFTOP=$iftop
[[ ! -z "$ftp" ]] && FTP=$ftp
[[ ! -z "$wget_syslog" ]] && WGET_SYSLOG=$wget_syslog
[[ ! -z "$wget_smtp" ]] && WGET_SMTP=$wget_smtp
[[ ! -z "$curl_pandb_url" ]] && CURL_PANDB_URL=$curl_pandb_url
[[ ! -z "$hipreport" ]] && HIPREPORT=$hipreport
[[ ! -z "$badcert" ]] && BADCERT=$badcert
[[ ! -z "$timeout" ]] && TIMEOUT=$timeout
[[ ! -z "$minimal" ]] && MINIMAL=$minimal

if [ "$MINIMAL" = "true" ]; then
		NMAP="false"
		SMTP="false"
		FTP="false"
		WGET_FTP="false"
		WGET_SMTP="false"
		WGET_SYSLOG="false"
		CURL_PANDB_URL="false"
		BITTORRENT="false"
		echo "Minimal ENV true, skipping all non-HTTP"
else
		echo ""
fi

# Check if HIP report should be used
if [ "$HIPREPORT" = "true" ]; then
		echo "Preparing HIP report script"
		HIPREPORT="--csd-wrapper scripts/hipreport.sh"
		sleep 1
else
		echo "Skipping HIP report"
		HIPREPORT=""
fi

echo "Updating CA certificates*"
cp certificates/*.crt /usr/local/share/ca-certificates/ 2>/dev/null
cp certificates/*.cert /usr/local/share/ca-certificates/ 2>/dev/null
chmod 644 /usr/local/share/ca-certificates/* 2>/dev/null && update-ca-certificates 2>/dev/null
echo "Set Python Request to use local cert store"
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
echo "Checking for local certificates (docker_machine_cert.crt/.key)"
cp --force certificates/docker_machine_cert.crt . 2>/dev/null
cp --force certificates/docker_machine_cert.key . 2>/dev/null

if [ "$GP_USERNAME" = "CHANGE_ME" ]; then
echo "Username missing"
echo "Enter username and press [ENTER]"
read GP_USERNAME
else
echo "Username: $GP_USERNAME"
fi
if [ "$GP_PASSWORD" = "CHANGE_ME" ]; then
echo "Password missing"
echo "Enter password and press [ENTER]"
read -s GP_PASSWORD
else
echo "Password filled out"
fi
if [ "$GP_GATEWAY" = "CHANGE_ME" ]; then
echo "Portal missing"
echo "Enter GlobalProtect Gateway and press [ENTER]"
read GP_GATEWAY
else
echo "GP Portal: $GP_GATEWAY"
fi

echo $GP_PASSWORD > gp_password.txt
# If BAD_CERT var is true, try to input cert manually
if [ "$BADCERT" = "true" ]; then
FILENAME=${2:-${HOST%%.*}}
HOST=$GP_GATEWAY
echo "Trying to fetch untrusted certificate"
# For file naming, see https://support.ssl.com/Knowledgebase/Article/View/19/0/der-vs-crt-vs-cer-vs-pem-certificates-and-how-to-convert-them
# For HTTP Public Key Pinning (HPKP), see https://developer.mozilla.org/en-US/docs/Web/HTTP/Public_Key_Pinning
CERTIFICATE_PEM="${FILENAME}_certificate.ascii.crt"
CERTIFICATE_DER="${FILENAME}_certificate.crt"
PUBKEY_PEM="${FILENAME}_pubkey.ascii.key"
PUBKEY_DER="${FILENAME}_pubkey.key"
PUBKEY_SHA256="${FILENAME}_pubkey.sha256"
PUBKEY_PIN256="${FILENAME}_pubkey.ascii.pin256"
echo "Q" | openssl s_client -connect "${HOST}":443 -servername "${HOST}" 2>/dev/null | openssl x509 -outform pem > "${CERTIFICATE_PEM}"
openssl x509 -outform der < "${CERTIFICATE_PEM}" > "${CERTIFICATE_DER}"
openssl x509 -pubkey -noout < "${CERTIFICATE_PEM}"> "${PUBKEY_PEM}"
openssl pkey -pubin -outform der < "${PUBKEY_PEM}" > "${PUBKEY_DER}"
openssl dgst -sha256 -binary < "${PUBKEY_DER}" > "${PUBKEY_SHA256}"
openssl enc -base64 < "${PUBKEY_SHA256}" > "${PUBKEY_PIN256}"
GP_CERT=$( cat "${PUBKEY_PIN256}" )

echo "Certificate untrusted. Trying to connect..."
openconnect --background --protocol=gp $GP_GATEWAY --user=$GP_USERNAME --passwd-on-stdin < gp_password.txt --servercert pin-sha256:$GP_CERT --certificate=docker_machine_cert.crt --sslkey=docker_machine_cert.key $HIPREPORT
else
echo "Connecting..."
openconnect --background --protocol=gp $GP_GATEWAY --user=$GP_USERNAME --passwd-on-stdin < gp_password.txt --certificate=docker_machine_cert.crt --sslkey=docker_machine_cert.key $HIPREPORT
echo ""
fi

sleep 5
OPERSTATE=$(ifconfig tun0 | grep "UP,")
if [ -z "$OPERSTATE" ]; then
        echo "Interface tun0 is DOWN. Exiting script"
		echo "Did you remember to use --privileged?"
		exit 1
else
        echo "Interface tun0 is UP. Proceeding"

fi

if [ "$NMAP" = "true" ]; then
		NAMESERVER="$(egrep -o -m 1 '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}' /etc/resolv.conf)"
		echo "Starting nmap to nameserver $NAMESERVER"
		nohup nmap -v -A $NAMESERVER 1> logs/nmap_nameserver_stdout.log 2> logs/nmap_nameserver_stderr.log &
else
		echo "Skipping nmap nameserver"
		sleep 1
fi


echo ""
if [ "$SMTP" = "true" ]; then
		echo "Starting wget/smtp in background"
		nohup ./scripts/wget_swaks.sh 1> logs/wget_swaks_stdout.log 2> logs/wget_swaks_stderr.log &
		sleep 1
else
		echo "Skipping wget/SMTP"
		sleep 1
fi

echo ""
if [ "$WGET_SYSLOG" = "true" ]; then
		echo "Starting wget/syslog in background"
		nohup ./scripts/wget_syslog.sh 1> logs/wget_syslog_stdout.log 2> logs/wget_syslog_stderr.log &
		sleep 1
else
		echo "Skipping wget/syslog"
		sleep 1
fi

echo ""
if [ "$WGET_FTP" = "true" ]; then
		echo "Starting wget/FTP download in background"
		nohup ./scripts/wget_ftp.sh 1> logs/wget_ftp_stdout.log 2> logs/wget_ftp_stderr.log &
		sleep 1
else
		echo "Skipping wget/FTP"
		sleep 1
fi

echo ""
if [ "$CURL_PANDB_URL" = "true" ]; then
		echo "Starting PAN-DB URL Filtering category curl"
		nohup ./scripts/curl_pandb_url.sh 1> logs/curl_pandb_url_stdout.log 2> logs/curl_pandb_url_stderr.log &
		sleep 1
else
		echo "Skipping PAN-DB curl"
		sleep 1
fi

echo ""
if [ -z "$NMAP_TARGET" ]; then
		echo "No nmap_target set. Skipping nmap scan"
		sleep 1
else
		echo "nmap_target specified. Starting nmap scan"
		nohup nmap -v -A $NMAP_TARGET 1> logs/nmap_target_stdout.log 2> logs/nmap_target_stderr.log &
		sleep 1
fi

echo ""
if [ "$BITTORRENT" = "true" ]; then
		echo "Starting bittorrent client"
		transmission-daemon --config-dir transmission-daemon/ --logfile logs/transmission-daemon.log
		sleep 1
else
		echo "Skipping bittorrent"
		sleep 1
fi

echo ""
if [ "$IFTOP" = "true" ]; then
		echo "Starting webcrawl in background, iftop -i tun0 in foreground"
		echo "Timeout value $TIMEOUT"
		sleep 4
		nohup python3 scripts/noisy/noisy.py --config scripts/noisy/config.json --timeout $TIMEOUT &
		iftop -i tun0 -P
		echo "Timeout reached. Killing VPN"
		pkill -f openconnect
		sleep 1
else
		echo "Starting webcrawl in foreground. Timeout value $TIMEOUT"
		sleep 1
		python3 scripts/noisy/noisy.py --config scripts/noisy/config.json --timeout $TIMEOUT
		echo "Timeout reached. Killing VPN"
		pkill -f openconnect
		sleep 1
fi