#! /bin/bash
echo "[INFO] Bypassing GP..."

if [ "$NMAP" = "true" ]; then
		NAMESERVER="$(egrep -o -m 1 '[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}' /etc/resolv.conf)"
		echo "[INFO] Starting nmap to nameserver $NAMESERVER"
		nohup nmap -v -A $NAMESERVER &> logs/nmap_nameserver &
else
		echo "[INFO] Skipping nmap nameserver"
		sleep 1
fi

if [ "$SMTP" = "true" ]; then
		echo "[INFO] Starting wget/smtp in background"
		nohup ./scripts/wget_swaks.sh &> logs/wget_swaks.log &
		sleep 1
else
		echo "[INFO] Skipping wget/SMTP"
		sleep 1
fi

if [ "$WGET_SYSLOG" = "true" ]; then
		echo "[INFO] Starting wget/syslog in background"
		nohup ./scripts/wget_syslog.sh &> logs/wget_syslog.log &
		sleep 1
else
		echo "[INFO] Skipping wget/syslog"
		sleep 1
fi

if [ "$WGET_FTP" = "true" ]; then
		echo "[INFO] Starting wget/FTP download in background"
		nohup ./scripts/wget_ftp.sh &> logs/wget_ftp.log &
		sleep 1
else
		echo "[INFO] Skipping wget/FTP"
		sleep 1
fi

if [ "$YOUTUBE_DL" = "true" ]; then
		echo "[INFO] Starting youtube-dl in background"
		nohup ./scripts/youtube-dl.sh &> logs/youtube-dl.log &
		sleep 1
else
		echo "[INFO] Skipping youtube-dl"
		sleep 1
fi

if [ "$CURL_PANDB_URL" = "true" ]; then
		echo "[INFO] Starting PAN-DB URL Filtering category curl"
		nohup ./scripts/curl_pandb_url.sh &> logs/curl_pandb_url.log &
		sleep 1
else
		echo "[INFO] Skipping PAN-DB curl"
		sleep 1
fi

if [ -z "$NMAP_TARGET" ]; then
		sleep 1
else
		echo "[INFO] nmap_target specified. Starting nmap scan"
		nohup nmap -v -A $NMAP_TARGET &> logs/nmap_target.log &
		sleep 1
fi

if [ "$BITTORRENT" = "true" ]; then
		echo "[INFO] Starting bittorrent client"
		transmission-daemon --config-dir transmission-daemon/ --logfile logs/transmission-daemon.log
		sleep 1
else
		echo "[INFO] Skipping bittorrent"
		sleep 1
fi

if [ "$IFTOP" = "true" ]; then
		echo "[INFO] Starting webcrawl in background, iftop -i tun0 in foreground"
		echo "[INFO] Timeout value $TIMEOUT"
		sleep 4
		nohup python3 scripts/noisy/noisy.py --config scripts/noisy/config.json --timeout $TIMEOUT &
		iftop -i tun0 -P
		echo "[INFO] Timeout reached. Killing VPN"
		pkill -f openconnect
		sleep 1
else
		echo "[INFO] Starting webcrawl in foreground. Timeout value $TIMEOUT"
		sleep 1
		python3 scripts/noisy/noisy.py --config scripts/noisy/config.json --timeout $TIMEOUT
		echo "[INFO] Timeout reached. Killing VPN"
		pkill -f openconnect
		sleep 1
fi