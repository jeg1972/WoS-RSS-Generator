#!/bin/sh

##############################################
# Wonder Of Stuff RSS Generator and Uploader #
##############################################
# Version 0.1 - John Gardner                 #
# Version 0.2 - John Gardner                 #
##############################################
# This script expects that the YouTube video #
# has been converted to MP3 by using the     #
# service: http://www.listentoyoutube.com    #
##############################################
# This script will ask the user for info     #
# about the latest Vodcast, update the text  #
# db, create the RSS feed and upload it all  #'
# to an AWS S3 bucket.                       #
# In order to make this work you only need to#
# specify the following variables;           #
# FLAT_DB - Path to text based DB file       #
# OUTPUT - Path and name of RSS XML file out #
# MP3_PATH - Path of MP3 file to upload      #    
############################################## 

# Variables to be configured on first run
FLAT_DB=./rss_s3_db
OUTPUT=wonderofstuff_rss.xml
MP3_PATH=/home/johnga/Downloads/
BUCKET=s3://wonderofstuff/
TDATE=$(date +%a", "%d" "%b" "%Y" "%H":"%M":"%S" "%z)

# Input all the details of the Vodcast
details() {
	rm -f /tmp/dbfile

	clear

	echo "WONDER OF STUFF RSS GENERATOR"
	echo "============================="
	echo ""

	echo "What is the title of the Vodcast?\n"

	read TITLE
	echo ""

	echo "What is the name of the MP3 file?\n"

	read FILENAME
	echo ""

	FILENAME=$( printf "%s\n" "$FILENAME" | sed 's/ /%20/g' )

	echo $TITLE";"$FILENAME";"$TDATE >> /tmp/dbfile
	cat $FLAT_DB >> /tmp/dbfile
	cp /tmp/dbfile $FLAT_DB
}

# Generate the RSS XML File
generate() {
rm -f $OUTPUT
cat <<SOURCE >> $OUTPUT
<rss xmlns:atom="http://www.w3.org/2005/Atom" xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">
	<channel>
<atom:link href="http://wonderofstuff.s3-website-eu-west-1.amazonaws.com/wonderofstuff_rss.xml" rel="self" type="application/rss+xml" />
<title>The Wonder Of Stuff</title>
<description>Vodcast about Science, Engineering and Technology and anything else we find interesting.</description>
<link>http://wonderofstuff.blogspot.com</link>
<language>en-gb</language>
<copyright>Copyright 2015</copyright>
SOURCE

echo "<lastBuildDate>"$TDATE"</lastBuildDate>" >> $OUTPUT
echo "<pubDate>"$TDATE"</pubDate>" >> $OUTPUT

cat <<SOURCE >> $OUTPUT
<docs>http://wonderofstuff.blogspot.com</docs>
<webMaster>wonderofstuff@gmail.com (John Gardner)</webMaster>
<ttl>60</ttl>
<itunes:author>Ross Davidson, John Gardner, Richard Smith</itunes:author>
<itunes:subtitle>
Vodcast about Science, Engineering and Technology and anything else we find interesting.
</itunes:subtitle>
<itunes:summary>
Vodcast about Science, Engineering and Technology and anything else we find interesting.
</itunes:summary>
<itunes:owner>
<itunes:name>Ross Davidson, John Gardner, Richard Smith</itunes:name>
<itunes:email>wonderofstuff@gmail.com</itunes:email>
</itunes:owner>
<itunes:explicit>No</itunes:explicit>
<itunes:image href="http://2.bp.blogspot.com/-0SpkgXsjaAk/VNeZGkR2ZpI/AAAAAAAAAM8/zaAR7Sqw8a4/s1600/wos.png"/>
<itunes:category text="Science &amp; Medicine">
</itunes:category>
<itunes:category text="Technology">
</itunes:category>
<itunes:category text="Comedy">
</itunes:category>

SOURCE

while read BLOGITEM; do

ITEM1=`echo $BLOGITEM | cut -d ";" -f 1`
ITEM2=`echo $BLOGITEM | cut -d ";" -f 2`
ITEM3=`echo $BLOGITEM | cut -d ";" -f 3`

echo $ITEM1

echo "<item>" >> $OUTPUT
echo "<title>$ITEM1</title>" >> $OUTPUT
echo "<link>http://wonderofstuff.blogspot.co.uk/</link>" >> $OUTPUT
echo "<guid>http://wonderofstuff.s3-website-eu-west-1.amazonaws.com/$ITEM2</guid>" >> $OUTPUT
echo "<description></description>" >> $OUTPUT
echo "<enclosure url=\"http://wonderofstuff.s3-website-eu-west-1.amazonaws.com/$ITEM2\" length=\"0\" type=\"audio/mpeg\"/>" >> $OUTPUT
echo "<category>Podcasts</category>" >> $OUTPUT
echo "<pubDate>$ITEM3</pubDate>" >> $OUTPUT
echo "<itunes:author>Ross Davidson, John Gardner, Richard Smith</itunes:author>" >> $OUTPUT
echo "<itunes:explicit>No</itunes:explicit>" >> $OUTPUT
echo "<itunes:subtitle>$ITEM1</itunes:subtitle>" >> $OUTPUT
echo "<itunes:summary>$ITEM1</itunes:summary>" >> $OUTPUT
echo "<itunes:duration>0:45</itunes:duration>" >> $OUTPUT
echo "<itunes:keywords>Science, Engineering, Technology</itunes:keywords>" >> $OUTPUT
echo "</item>" >> $OUTPUT

done <$FLAT_DB

cat <<SOURCE >> $OUTPUT

</channel>
</rss>

SOURCE
}

# Upload to AWS S3 Bucket
upload() {
	aws s3 cp $OUTPUT $BUCKET
	aws s3 cp $FLAT_DB $BUCKET
}

#details
#generate
upload
