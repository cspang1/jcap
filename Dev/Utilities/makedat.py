from __future__ import print_function
from itertools import zip_longest
import os
import sys
import argparse
import re

def byteify(iterable, n, fillvalue=None):
    args = [iter(iterable)] * n
    return zip_longest(*args, fillvalue=fillvalue)

def parse_hex(src,bytes_per_gp, regex):
    bytelist = []
    regex = re.compile(regex)
    for line in src:
        for result in re.findall(regex, line):
            result = result.replace("_","")
            for byte in byteify(result,bytes_per_gp,"0"):
                byte = "".join(byte)[::-1]
                for element in byteify(byte,2,"0"):
                    element = bytes.fromhex("".join(element)[::-1])
                    bytelist.append(element)
    return bytelist

def parse_colors(resource_file):
    return parse_hex(resource_file,2,r'(?<=\$)[0-9A-F]{2}')

def parse_tiles(resource_file):
    return parse_hex(resource_file,8,r'(?<=\$)[0-9A-F_]{15}')

def parse_tile_maps(resource_file):
    return parse_hex(resource_file,4,r'(?<=\$)[0-9A-F_]{5}')

def main(arguments):

    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('-c','--color_palette', help="Use color palette encoding", action='store_true')
    group.add_argument('-t','--tile_palette', help="Use tile palette encoding", action='store_true')
    group.add_argument('-m','--tile_map', help="Use tile map encoding", action='store_true')
    parser.add_argument('infile', help="Input file", type=argparse.FileType('r'))
    parser.add_argument('outfile', help="Output file", type=argparse.FileType('wb'))

    args = parser.parse_args(arguments)

    with open(args.infile.name, args.infile.mode) as resource_file, open(args.outfile.name, args.outfile.mode) as dat_file:
        if args.color_palette:
            result = parse_colors(resource_file)
        if args.tile_palette:
            result = parse_tiles(resource_file)
        if args.tile_map:
            result = parse_tile_maps(resource_file)
        dat_file.writelines(line for line in result)

if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))