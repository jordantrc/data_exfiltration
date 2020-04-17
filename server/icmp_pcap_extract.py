#!/usr/bin/env python3
#
# Usage: icmp_pcap_extract.py <input file> <output file>
#
#

import sys
from scapy.all import *


def main():
    if len(sys.argv) != 3:
        print("Usage: icmp_pcap_extract.py <input file> <output file>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = sys.argv[2]

    packets = rdpcap(input_file)
    fd_out = open(output_file, "wb")

    for p in packets:
        if p.haslayer(ICMP):
            data = p[ICMP][Raw].load
            fd_out.write(data)
    
    fd_out.close()


if __name__ == "__main__":
    main()