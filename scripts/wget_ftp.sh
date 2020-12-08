#! /bin/bash
# Downloads files via FTP
echo "Starting FTP download"
wget --limit-rate 200k -nv -i scripts/wget_ftp_files.txt -P downloads/wget_ftp/
echo "Done"