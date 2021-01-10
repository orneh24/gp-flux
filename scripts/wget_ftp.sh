#! /bin/bash
# Downloads files via FTP

# Choose 6 of the files listed
shuf -n 6 scripts/wget_ftp_files.txt > scripts/wget_ftp_files_filtered.txt
mapfile -t FTPFILES < scripts/wget_ftp_files_filtered.txt
for file in "${FTPFILES[@]}"
do
   echo "next FPT wget will be to $file"
   wget --limit-rate 200k -nv $file -P scripts/downloads/wget_ftp/
   sleep 1
done