#!/bin/sh

# Script created for sending email using curl to send a post request to gmail's servers. Must supply needed details (gmail credentials, title, reciever) by editing script and can be supplied with either text files (for adding a message to the email) or images (will be send as attachment) as commandline arguments. Supported file types is .txt, .png, .jpeg and .jpg

# Should be self-explanatory. senderAdress has to be a gmail
senderAddress=""
senderPassword=""
recieverAddres=""
emailSubjec=""

# Most be the full or relative path to a normal text file containting the message of the email. Can be left blank if no message is required/wanted
messageFile=""

tempDir="$(mktemp -d)"

cd "$tempDir"

trap "rm -rf $tempDir" INT TERM EXIT

for file in 

# Rest:
#echo "$(curl https://pastebin.com/raw/3MK3bBFT)\n\n$(cat /home/bertmad/Screenshots/Full/2021-06-05_21-56-08.png | base64 -w 0)\n--MULTIPART-MIXED-BOUNDARY--" > message2
#curl --ssl-reqd \\
#  --url 'smtps://smtp.gmail.com:465' \\
#  --user 'steveglambert31@gmail.com:=Ndx;vHMc,ACReBKu$.Vu"ckdQ8lcc' \\
#  --mail-from 'steveglambert31@gmail.com' \\
#  --mail-rcpt 'skrivtilbertram@gmail.com' \\
#  --upload-file message2
#[bertmad@bertmad ~]$ cat message2
#From: "User Name" <username@gmail.com>
#To: "John Smith" <john@example.com>
#Subject: This is a test
#Reply-To: $mail_reply_to
#Cc: $mail_cc
#MIME-Version: 1.0
#Content-Type: multipart/mixed; boundary=\"MULTIPART-MIXED-BOUNDARY\"
#
#--MULTIPART-MIXED-BOUNDARY
#Content-Type: multipart/alternative; boundary=\"MULTIPART-ALTERNATIVE-BOUNDARY\"
#
#--MULTIPART-MIXED-BOUNDARY
#Content-Type: image/png
#Content-Transfer-Encoding: base64
#Content-Disposition: inline
#Content-Id: <admin.png>
#
#{image}
#
#--MULTIPART-MIXED-BOUNDARY--

