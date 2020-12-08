#! /bin/bash
# Get list of URL categories and example sites from PANW
curl -k 'https://knowledgebase.paloaltonetworks.com/KCSArticleDetail?id=kA10g000000Cm5hCAC' | grep -Eo '(www[.]\w+[.]\w+)' > scripts/urlfilter_category_sites_latest.txt
mapfile -t urlCategorySites < scripts/urlfilter_category_sites_latest.txt
# Retain cached copy in case new curl fails
mapfile -t urlCategorySitesCached < scripts/urlfilter_category_sites_cached.txt

# Use curl to browse sites
for url in "${urlCategorySites[@]}"
do
   echo "next curl will be to $url"
   curl -kL -m 10 $url
   sleep 1
done

# Repeat for the cached copy if latest curl failed
for url in "${urlCategorySitesCached[@]}"
do
   echo "next curl will be to $url"
   curl -kL -m 10 $url
   sleep 1
done