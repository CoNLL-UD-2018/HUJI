#!/usr/bin/env python3

import argparse
import os
from glob import glob

from tqdm import tqdm
from ucca.ioutil import read_files_and_dirs, write_passage
from ucca.textutil import annotate_all

from scheme.convert import FROM_FORMAT, UCCA_EXT

desc = """Read passages in any format, and write back with spaCy annotations."""


def main(args):
    specs = [(pattern, args.out_dir, args.lang) for pattern in args.filenames]
    if args.list_file:
        with open(args.list_file, encoding="utf-8") as f:
            specs += [l.strip().split() for l in f if not l.startswith("#")]
    for pattern, out_dir, lang in specs:
        os.makedirs(out_dir, exist_ok=True)
        filenames = glob(pattern)
        if not filenames:
            raise IOError("Not found: " + pattern)
        passages = read_files_and_dirs(filenames, converters=FROM_FORMAT)
        for passage in annotate_all(passages if args.verbose else
                                    tqdm(passages, unit=" passages", desc="Annotating " + out_dir),
                                    as_array=args.as_array, replace=True, lang=lang, verbose=args.verbose):
            write_passage(passage, outdir=out_dir, verbose=args.verbose, binary=args.binary)


if __name__ == '__main__':
    argparser = argparse.ArgumentParser(description=desc)
    argparser.add_argument("filenames", nargs="*", help="passage file names to annotate")
    argparser.add_argument("-f", "--list-file", help="file whose rows are <PATTERN> <OUT-DIR> <LANGUAGE>")
    argparser.add_argument("-o", "--out-dir", default=".", help="directory to write annotated files to")
    argparser.add_argument("-a", "--as-array", action="store_true", help="save annotations as array in passage level")
    argparser.add_argument("-b", "--binary", action="store_true", help="write in binary format (.%s)" % UCCA_EXT[1])
    argparser.add_argument("-l", "--lang", default="en", help="small two-letter language code to use for NLP model")
    argparser.add_argument("-v", "--verbose", action="store_true", help="print tagged text for each passage")
    main(argparser.parse_args())
