#! /bin/bash
# Downloads media files with youtube-dl
# https://ytdl-org.github.io

# Choose 10 of the files listed
shuf -n 10 scripts/youtube-dl.txt > scripts/youtube-dl-filtered.txt
python3 /usr/local/bin/youtube-dl --rate-limit 200k --max-filesize 200m -o "/opt/gp-flux/downloads/youtube-dl/%(title)s.%(ext)s" -a scripts/youtube-dl-filtered.txt