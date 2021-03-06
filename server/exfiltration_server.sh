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

usage() {
    echo "Usage:"
    echo "exfiltration_server.sh [-s source] [service switch] [service parameters] [[service switch] [service parameters]]..."
    echo "  -h  print this help message and exit"
    echo "  -o  only accept connections from the given source address"
    echo "service switches and options:"
    echo "  -d  run a DNS service"
    echo "      service parameters:"
    echo "          <interface>:<domain> - exfiltration domain"
    echo "  -f  run an FTP service"
    echo "      service parameters:"
    echo "          <username>:<password> - username and password combination that"
    echo "                                can access the server to upload"
    echo "  -t  run an HTTP service"
    echo "      service parameters:"
    echo "          <username>:<password> - username and password combination that"
    echo "                                can access the server to upload"
    echo "  -s  run a HTTPS service"
    echo "      service parameters:"
    echo "          <username>:<password> - username and password combination that"
    echo "                                can access the server to upload"
    echo "  -i  listen for ICMP packets"
    echo "      service parameters:"
    echo "          <interface>"
    exit 1
}

if [ $EUID -ne 0 ]; then
    echo "[-] script must be run as root"
    exit 1
fi

source_ip=""
while getopts "ho:d:f:h:s:i:" OPTION; do
	case "$OPTION" in
		o ) source_ip="$OPTARG";;
        h ) usage;;
		d ) enable_dns=true; dns_param="$OPTARG";;
		f ) enable_ftp=true; ftp_param="$OPTARG";;
		t ) enable_http=true; http_param="$OPTARG";;
		s ) enable_https=true; https_param="$OPTARG";;
		i ) enable_icmp=true; icmp_interf="$OPTARG";;
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
    if [ "$?" -eq "1" ]; then
        echo "[-] $u is not installed or not in PATH"
        exit 1
    fi
done

if [ ! -z "$source_ip" ]; then
    source_filter="src host $source_ip and"
else
    source_filter=""
fi

# start servers as background processes
if [ "$enable_dns" = true ]; then
    interface=$(echo "$dns_param" | cut -d ":" -f 1)
    domain=$(echo "$dns_param" | cut -d ":" -f 2)
    echo "[*] starting DNS listener for domain $domain"
    echo "[*] once complete, use the below command to get original file:"
    echo "[*] cat dns_data | awk '{print \$12}' | cut -d '.' -f 1 | sort | grep '-' | uniq | cut -d '-' -f 2 | xxd -p -r > file"
    tshark -i $interface -f "$source_filter udp port 53" -Y "dns.qry.type == 1 and dns.flags.response == 0 and dns.qry.name matches '$domain'" >> dns_data &
fi

if [ "$enable_ftp" = true ]; then
    creds="$ftp_param"
    username=$(echo "$creds" | cut -d ":" -f 1)
    password=$(echo "$creds" | cut -d ":" -f 2)
    echo "[*] starting FTP server with credential $username:$password"
    python3 ftp_server.py -u $username -p $password . &
fi

if [ "$enable_icmp" = true ]; then
    interface=$icmp_interf
    echo "[*] starting ICMP listener"
    echo "[*] once complete, use the icmp_pcap_extract.py script"
    tcpdump -i $interface -w icmp_data.pcap $source_filter icmp 
fi

# wait for children to exit
wait