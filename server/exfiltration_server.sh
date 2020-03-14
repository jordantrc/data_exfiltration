#!/usr/bin/env bash
#
# Usage:
# exfiltration_server.sh <service>,<service>
#   service is one or more of:
#       all - start all services
#       dns - start DNS service
#       ftp - start FTP service
#       http - start HTTP service
#       http/s - start HTTP/S service
#       icmp - start ICMP "service"
#
# Credit to Red Canary for their Atomic Red tool, specifically T1048:
# https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1048/T1048.yaml
#

if [ $# -ne 1 ]; then
    echo "Usage:"
    echo "exfiltration_server.sh [-s source] [service switch] [service parameters] [[service switch] [service parameters]]..."
    echo "  -s  only accept connections from the given source address"
    echo "service switches and options:"
    echo "  -d  run a DNS service"
    echo "      service parameters:"
    echo "          <domain> - exfiltration domain"
    echo "  -f  run an FTP service"
    echo "      service parameters:"
    echo "          <username:password> - username and password combination that"
    echo "                                can access the server to upload"
    echo "  -h  run an HTTP service"
    echo "      service parameters:"
    echo "          <username:password> - username and password combination that"
    echo "                                can access the server to upload"
    echo "  -s  run a HTTPS service"
    echo "      service parameters:"
    echo "          <username:password> - username and password combination that"
    echo "                                can access the server to upload"
    echo "  -i  listen for ICMP packets"
    exit(1)

source_ip=""
while getopts "s:d:f:h:s:i" OPTION; do
	case "$OPTION" in
		s ) source_ip="$OPTARG";;
		d ) dns_param="$OPTARG";;
		f ) ftp_param="$OPTARG";;
		h ) http_param="$OPTARG";;
		s ) https_param="$OPTARG";;
		i ) icmp_listen=true;;
		\?) echo "Unknown option: -$OPTARG" >&2; exit 1;;
		: ) echo "Missing argument for -$OPTARG" >&2; exit 1;;
		* ) echo "Invalid option provided: -$OPTARG" >&2; exit 1;;
	esac
done

# check for prerequisite utilities
utils=( "tshark" )
for u in "${utils[@]}"; do
    echo "[*] testing for $u"
    command -v "$u"
    if "$?" -eq "1"; then
        echo "[-] $u is not installed or not in PATH"
        exit(2)
    fi
done

# trap ctrl+c to shutdown PIDs
pids=()
trap ctrl_c INT
function ctrl_c() {
    echo "[*] shutting down exfil servers"
    for p in "${pids[@]}"; do
        sudo kill "$p"
    done
    exit(0)
}

# start servers as background processes
if [ "$enable_dns" = true ]; then
    domain="$dns_param"
    echo "[*] starting DNS server for domain $domain"
    sudo tshark -f "udp port 53" -Y "dns.qry.type == 1 and dns.flags.response == 0 and dns.qry.name matches "$domain"" >> dns_data &
    pids+=($!)
fi

if [ "$enable_ftp" = true ]; then
    creds="$ftp_param"
    username=$(echo "$creds" | cut -d ":" -f 1)
    password=$(echo "$creds" | cut -d ":" -f 2)
    echo "[*] starting FTP server with credential $username:$password"
    if [ "${#source_ip}" -gt 0 ]; then
        sudo python ftp_server.py -s $source_ip -u $username -p $password . &
        pids+=($!)
    else
        sudo python ftp_server.py -u $username -p $password . &
        pids+=($!)
    fi
fi