#!/usr/bin/env python3
#
# Usage:
# ftp_server.py [options] <directory to serve>
# Valid options:
#   -s <source ip address>
#   -u <username>
#   -p <password>

import argparse
import os
import sys
from pyftpdlib import servers
from pyftpdlib.authorizers import DummyAuthorizer
from pyftpdlib.handlers import FTPHandler


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-u", help="username")
    parser.add_argument("-p", help="password")
    parser.add_argument("dir", nargs=1, help="directory to serve")
    args = parser.parse_args()

    # collect arguments
    username = args.u
    password = args.p
    directory = args.dir[0]

    if not os.path.isdir(directory):
        print("[-] %s is not a directory" % directory)
        sys.exit(1)

    print("[+] using credentials %s:%s" % (username, password))
    print("[+] starting FTP server")
    
    # configure authorization
    authorizer = DummyAuthorizer()
    authorizer.add_user(username=username, password=password, homedir=directory, perm="lw")
    
    # address and handler information
    address = ("0.0.0.0", 21)
    handler = FTPHandler
    handler.authorizer = authorizer

    server = servers.FTPServer(address, handler=handler)
    server.serve_forever()


if __name__ == "__main__":
    main()