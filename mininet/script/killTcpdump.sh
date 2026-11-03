#!/bin/bash

#inject="base"
inject="spoof"

filename="/home/hugo/Dropbox/Public/ndev.txt"
i=0

#while IFS='' read -r line || [[ -n "$line" ]]; do
#    echo "Text read from file: $line"
#done < "$filename"
    
while IFS='' read -r line || [ -n "$line" ]; do
    echo "Text read from file: $line"
    if [ $i == 0 ]
    then
        HOST=$line
    fi

    i=`expr $i + 1`
done < "$filename"

echo $HOST


i=0

while [ $i -lt 60 ]
do
   echo "waiting for $i minutes"
   i=`expr $i + 1`
   sleep 1m
done

sudo pkill -f tcpdump


cp ../log/$HOST-$inject.pcap /home/hugo/Dropbox/Experiments/181127_Spoof/NetworkInjection/$HOST/

