#! /bin/bash
echo "starting script..."
echo "var WGET_SMTP is $WGET_SMTP"
echo "var SMTP is $SMTP"
echo "var SMTP_SERVER is $SMTP_SERVER"

echo ""
if [ "$SMTP" = "true" ]; then
echo "Sending default files"
SMTPFILES_DEFAULT=(scripts/smtpfiles/*)	
echo "Sending e-mail"
for i in "${SMTPFILES_DEFAULT[@]}"; do
   echo "next file is $i"
   swaks -n --to dummy@nothing.org --server $SMTP_SERVER --attach $i
   sleep 1
done
                sleep 2
else
                echo "Skipping SMTP"
                sleep 2
fi

echo ""
if [ "$WGET_SMTP" = "true" ]; then
echo "Downloading files.."
wget --limit-rate 100k -nv -i scripts/wget_examples-files.txt -P downloads/wget_swaks/
fi

echo ""
if [ "$SMTP" = "true" ]; then
echo "Sending downloaded files"
SMTPFILES_WGET=(downloads/wget_swaks/*)	
echo "Sending e-mail"
for i in "${SMTPFILES_WGET[@]}"; do
   echo "next file is $i"
   swaks -n --to dummy@nothing.org --server $SMTP_SERVER --attach $i
   sleep 1
done
                sleep 2
else
                echo "Skipping SMTP"
                sleep 2
fi