from __future__ import print_function
import os
import sys
import argparse
import re
from random import seed
from random import randint

def main(arguments):

    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('infile', help="Input file", type=argparse.FileType('r'))
    parser.add_argument('-o', '--outfile', help="Output file",
                        default=sys.stdout, type=argparse.FileType('w'))

    args = parser.parse_args(arguments)
    
    tile_arr = ["43", "3F"]

    seed(1453)
    regex = re.compile(r'43{1}|3F{1}')
    with open(args.infile.name, args.infile.mode) as original, open(args.outfile.name, args.outfile.mode) as reverse:
        for line in original:
            for match in re.finditer(regex,line):
                if match is not None:
                    s = match.start()
                    e = match.end()
                    line = line[:s] + tile_arr[randint(0, 1)] + line[e:]
            reverse.write(line)

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))