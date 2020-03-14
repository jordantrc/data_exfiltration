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
# Lots of credit to Red Canary for their Atomic Red tool, specifically T1048:
# https://github.com/redcanaryco/atomic-red-team/blob/master/atomics/T1048/T1048.yaml
#

if [ $# -ne 1 ]; then
    echo "Usage:"
    echo "exfiltration_server.sh [-s source] [service switch] [service parameters]"
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

services_input=$1
IFS=',' read -r -a services <<< "$services_input"

# here come the if-elses
if [[ "${services[@]}" =~ "all" ]]; then
    enable_dns=true
    enable_ftp=true
    enable_http=true
    enable_https=true
    enable_icmp=true
elif [[ "${services[@]}" =~ "dns" ]]; then
    enable_dns=true
elif [[ "${services[@]}" =~ "ftp" ]]; then
    enable_ftp=true
elif [[ "${services[@]}" =~ "http" ]]; then
    enable_http=true
elif [[ "${services[@]}" =~ "https" ]]; then
    enable_https=true
elif [[ "${services[@]}" =~ "icmp" ]]; then
    enable_icmp=true
else
    echo "[-] no valid services found in service list, exiting"
    exit(1)
fi

if [ "$enable_dns" = true ]; then
    sudo tshark -f "udp port 53" -Y "dns.qry.type == 1 and dns.flags.response == 0 and dns.qry.name matches ".domain"" >> dns_data.txt
