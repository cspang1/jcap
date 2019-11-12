from __future__ import print_function
import os
import sys
import argparse
import re

def main(arguments):

    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('infile', help="Input file", type=argparse.FileType('r'))
    parser.add_argument('-o', '--outfile', help="Output file",
                        default=sys.stdout, type=argparse.FileType('w'))

    args = parser.parse_args(arguments)

    regex = re.compile(r'(?<=\$)[0-9A-F_]{15}')
    with open(args.infile.name, args.infile.mode) as original, open(args.outfile.name, args.outfile.mode) as stripped:
        for line in original:
            result = re.search(r'(?<=\$)[0-9A-F_]{15}', line)
            if result:
                result = result.group(0).replace("_","")
                stripped.write(result)

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))