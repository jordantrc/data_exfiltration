# tester to generate check digit for an account number

import sys

def check_digit(account):
    account_rev = account[::-1]
    digits = [int(d) for d in str(account_rev)]
    doubled_digits = []
    for i, d in enumerate(digits):
        if i % 2 == 0:
            doubled_digits.append(int(d) * 2)
        else:
            doubled_digits.append(int(d))
    print("doubled digits = %s" % doubled_digits[::-1])
    sum_digits = []
    for i, d in enumerate(doubled_digits):
        if i % 2 == 0 and d > 9:
            sum_digit = d - 9
        else:
            sum_digit = d
        sum_digits.append(sum_digit)
    print("sum digits = %s" % sum_digits[::-1])
    
    sum_digits_sum = sum(sum_digits)
    print("sum digits sum = %s" % sum_digits_sum)
    check_digit = (sum_digits_sum * 9) % 10
    
    return check_digit

def main():
    account = sys.argv[1]
    digit = check_digit(account)
    print("Check digit = %d" % digit)

if __name__ == "__main__":
    main()