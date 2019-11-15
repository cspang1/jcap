from __future__ import print_function
from itertools import zip_longest
import os
import sys
import argparse
import re

def byteify(iterable, n, fillvalue=None):
    args = [iter(iterable)] * n
    return zip_longest(*args, fillvalue=fillvalue)

def main(arguments):

    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('infile', help="Input file", type=argparse.FileType('r'))
    parser.add_argument('-o', '--outfile', help="Output file",
                        default=sys.stdout, type=argparse.FileType('wb'))

    args = parser.parse_args(arguments)

    regex = re.compile(r'(?<=\$)[0-9A-F_]{15}')
    with open(args.infile.name, args.infile.mode) as original, open(args.outfile.name, args.outfile.mode) as stripped:
        for line in original:
            result = re.search(r'(?<=\$)[0-9A-F_]{15}', line)
            if result:
                result = result.group(0).replace("_","")
                for byte in byteify(result,8,"0"):
                    byte = "".join(byte)[::-1]
                    for element in byteify(byte,2,"0"):
                        element = bytes.fromhex("".join(element)[::-1])
                        stripped.write(element)

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))