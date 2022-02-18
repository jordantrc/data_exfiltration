#!/usr/bin/env python
#
# Generates dummy credit card data to be used
# for testing dlp functionality. The script
# assumes a folder called data with
# four files is present in the local
# directory - 
# data/family_names.txt
# data/first_names.txt
# data/cities_states.csv
# data/street_names.txt
# The script randomly selects combinations from
# these files for the cardholder names.
#
# Usage: dummy_cc_data.py <format> <count>
# Acceptable formats are 'csv', 'tsv', 'excel'

import csv
import random
import string
import sys
import openpyxl
from datetime import date


class CreditCardGenerator:
    
    def __init__(self, fmt):
        self.format = fmt
        self.writer = None
        self.workbook = None

        # header list
        header_fields = [
            "family_name",
            "first_name",
            "address_line_1",
            "address_line_2",
            "city",
            "state",
            "zip_code",
            "ssn",
            "account_number",
            "expiration",
            "cvv"
        ]

        # setup output files
        if self.format == 'csv':
            self.fd = open('output.csv', 'w', newline='')
            self.writer = csv.writer(self.fd)
            self.writer.writerow(header_fields)
        elif self.format == 'tsv':
            self.fd = open('output.tsv', 'w', newline='')
            self.writer = csv.writer(self.fd, delimiter="\t")
            self.writer.writerow(header_fields)
        elif self.format == 'excel':
            self.workbook = openpyxl.Workbook()
            print(self.workbook)
            self.worksheet = self.workbook.active
            print(self.worksheet)
            self.worksheet.append(header_fields)
        else:
            print("[-] unsupported format %s" % self.format)
            sys.exit(1)

        # read in family and first names, street names, cities/states
        with open('data/family_names.txt', 'r') as fd:
            self.family_names = fd.read().splitlines()
        with open('data/first_names.txt', 'r') as fd:
            self.first_names = fd.read().splitlines()
        with open('data/street_names.txt', 'r') as fd:
            self.street_names = fd.read().splitlines()
        self.cities_states = []
        self.city_pop = []
        with open('data/cities_states.csv', 'r', newline='') as csv_fd:
            reader = csv.reader(csv_fd)
            for row in reader:
                self.cities_states.append([row[0], row[2]])
                self.city_pop.append(int(row[3]))
        # adjust city_pop list to be percentage of whole
        total_pop = float(sum(self.city_pop))
        self.city_pop = [ float(x / total_pop) for x in self.city_pop ]


    def generate_card_numbers(self):
        # generate the card number itself
        brand_choices = ['amex', 'mc', 'visa']
        brand_weights = [0.03, 0.34, 0.63]
        brand_iins = [
                    ['34', '37'],
                    ['51', '52', '53', '54', '55'],
                    ['4']
                    ]
        card_brand_index = random.choices([0, 1, 2], weights=brand_weights, k=1)[0]
        card_length = 16  # includes check digit
        card_number = random.choice(brand_iins[card_brand_index])
        brand = brand_choices[card_brand_index]
        
        while len(card_number) < card_length - 1:
            digit = random.choice(string.digits)
            card_number = card_number + digit
        
        # generate the check digit
        card_number_rev = card_number[::-1]
        digits = [int(d) for d in str(card_number_rev)]
        doubled_digits = []
        for i, d in enumerate(digits):
            if i % 2 == 0:
                doubled_digits.append(int(d) * 2)
            else:
                doubled_digits.append(int(d))
        sum_digits = []
        for i, d in enumerate(doubled_digits):
            if i % 2 == 0 and d > 9:
                sum_digit = d - 9
            else:
                sum_digit = d
            sum_digits.append(sum_digit)
        sum_digits_sum = sum(sum_digits)
        check_digit = (sum_digits_sum * 9) % 10
        card_number = card_number + str(check_digit)

        # generate the expiration
        current_year = date.today().year
        months = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12']
        years = list(range(current_year, current_year + 5))
        expiration = random.choice(months) + "/" + str(random.choice(years))[2:4]

        # generate the cvv
        if brand in ['visa', 'mc']:
            cvv_list = random.choices(string.digits, k=3)
        elif brand == 'amex':
            cvv_list = random.choices(string.digits, k=4)
        cvv = ''.join(cvv_list)

        return (card_number, expiration, cvv)


    def generate_address(self):
        street_number = random.randint(1, 20000)
        street_name = random.choice(self.street_names)
        city, state = random.choices(self.cities_states, weights=self.city_pop, k=1)[0]
        apt_number = ''
        if random.random() < 0.25:
            apt = random.randint(1, 50)
            apt_number = "APT. " + str(apt)
        address_line_1 = "%s %s" % (street_number, street_name)
        address_line_2 = apt_number
        zip_code = str(random.randint(10000, 99999))

        return (address_line_1, address_line_2, city.upper(), state.upper(), zip_code)


    def create_write_card_record(self):
        first_name = random.choice(self.first_names)
        family_name = random.choice(self.family_names)
        account_number, expiration, cvv = self.generate_card_numbers()
        address_line_1, address_line_2, city, state, zip_code = self.generate_address()
        ssn_1 = random.randint(100, 999)
        ssn_2 = random.randint(10, 99)
        ssn_3 = random.randint(1000, 9999)
        ssn = "%s-%s-%s" % (ssn_1, ssn_2, ssn_3)

        record = [
            family_name,
            first_name,
            address_line_1,
            address_line_2,
            city,
            state,
            zip_code,
            ssn,
            account_number,
            expiration,
            cvv
        ]

        # write the record to the output file
        if self.format == 'csv' or self.format == 'tsv':
            self.writer.writerow(record)
        elif self.format == 'excel':
            self.worksheet.append(record)
    
    def cleanup(self):
        # close files
        if self.writer is not None:
            self.fd.close()
        if self.workbook is not None:
            self.workbook.save("output.xlsx")


def main():
    # get command line arguments
    if len(sys.argv) != 3:
        print("Usage: %s <format> <count>" % sys.argv[0])
        print("Example: %s csv 10000" % sys.argv[0])
        sys.exit(1)
    
    file_format = sys.argv[1]
    count = int(sys.argv[2])

    generator = CreditCardGenerator(file_format)

    for i in range(count):
        generator.create_write_card_record()
        if i % (count / 10) == 0:
            print("[*] %d records generated" % i)
    print("[*] %d records generated" % (i + 1))

    generator.cleanup()


if __name__ == "__main__":
    main()