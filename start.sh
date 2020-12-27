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


OPENCONNECT_LOG="logs/openconnect.log"
OPENCONNECT_ERROR_AUTHFAIL=": auth-failed"
OPENCONNECT_ERROR_CLIENTCERTIFICATE="Valid client certificate is required"
OPENCONNECT_ERROR_PRIVILEGED="Failed to bind local tun device (TUNSETIFF): Operation not permitted"

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
echo "Gateway missing"
echo "Enter GlobalProtect Gateway and press [ENTER]"
read GP_GATEWAY
else
echo "GP Gateway: $GP_GATEWAY"
fi

echo $GP_PASSWORD > gp_password.txt

# Split Gateway hostname and port in different vars
HOST="$(echo $GP_GATEWAY | cut -d: -f1)"
PORT="$(echo $GP_GATEWAY | cut -d: -f2 -s)"
if [ -z "$PORT" ]; then
echo "No port specified, we wil try :443"
                PORT=443
                sleep 1
fi

if [ "$BADCERT" = "true" ]; then
# Get all certs in chain, from GW
openssl s_client -showcerts -verify 5 -connect ${HOST}:${PORT} < /dev/null | awk '/BEGIN/,/END/{ if(/BEGIN/){a++}; out="cert"a".crt"; print >out}'
# Re-run CA update. should be optimized
echo "Updating CA certificates*"
cp *.crt /usr/local/share/ca-certificates/ 2>/dev/null
chmod 644 /usr/local/share/ca-certificates/* 2>/dev/null && update-ca-certificates 2>/dev/null
echo "Set Python Request to use local cert store"
export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

echo "Certificate untrusted. Trying to connect..."
openconnect --background --protocol=gp $GP_GATEWAY --user=$GP_USERNAME --passwd-on-stdin < gp_password.txt --certificate=docker_machine_cert.crt --sslkey=docker_machine_cert.key $HIPREPORT --verbose &> logs/openconnect.log
else
echo "Connecting..."
openconnect --background --protocol=gp $GP_GATEWAY --user=$GP_USERNAME --passwd-on-stdin < gp_password.txt --certificate=docker_machine_cert.crt --sslkey=docker_machine_cert.key $HIPREPORT --verbose &> logs/openconnect.log
echo ""
fi

sleep 5
OPERSTATE=$(ifconfig tun0 | grep "UP,")
if [ -z "$OPERSTATE" ]; then
        echo "Interface tun0 is DOWN. Checking for known errors"
		if grep -q "$OPENCONNECT_ERROR_AUTHFAIL" "$OPENCONNECT_LOG"; then
         echo "Authentication failed, verify user credentials"
        fi
		if grep -q "$OPENCONNECT_ERROR_CLIENTCERTIFICATE" "$OPENCONNECT_LOG"; then
         echo "Machine certificate missing"
        fi
		if grep -q "$OPENCONNECT_ERROR_PRIVILEGED" "$OPENCONNECT_LOG"; then
         echo "Could not create tun0 device. Did you remember to use --privileged in docker run command?"
        fi		
		echo "Exiting container"
		exit 1
else
        echo "Interface tun0 is UP. Proceeding"

fi

if [ "$NMAP" = "true" ]; then
		NAMESERVER="$(egrep -o -m 1 '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}' /etc/resolv.conf)"
		echo "Starting nmap to nameserver $NAMESERVER"
		nohup nmap -v -A $NAMESERVER &> logs/nmap_nameserver &
else
		echo "Skipping nmap nameserver"
		sleep 1
fi


echo ""
if [ "$SMTP" = "true" ]; then
		echo "Starting wget/smtp in background"
		nohup ./scripts/wget_swaks.sh &> logs/wget_swaks &
		sleep 1
else
		echo "Skipping wget/SMTP"
		sleep 1
fi

echo ""
if [ "$WGET_SYSLOG" = "true" ]; then
		echo "Starting wget/syslog in background"
		nohup ./scripts/wget_syslog.sh &> logs/wget_syslog.log &
		sleep 1
else
		echo "Skipping wget/syslog"
		sleep 1
fi

echo ""
if [ "$WGET_FTP" = "true" ]; then
		echo "Starting wget/FTP download in background"
		nohup ./scripts/wget_ftp.sh &> logs/wget_ftp.log &
		sleep 1
else
		echo "Skipping wget/FTP"
		sleep 1
fi

echo ""
if [ "$CURL_PANDB_URL" = "true" ]; then
		echo "Starting PAN-DB URL Filtering category curl"
		nohup ./scripts/curl_pandb_url.sh &> logs/curl_pandb_url.log &
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
		nohup nmap -v -A $NMAP_TARGET &> logs/nmap_target.log &
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