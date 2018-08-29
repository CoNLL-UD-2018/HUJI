import argparse
import os
from glob import glob
from ufal.udpipe import Model, Pipeline, ProcessingError

desc = """Parse .conllu file(s) using UDPipe and save to .conllu files"""

def main(args):
    model = Model.load(args.model)
    if not model:
        raise ValueError("Invalid model: '%s'" % args.model)
    os.makedirs(args.out_dir, exist_ok=True)
    pipeline = Pipeline(model, "tokenize" if args.txt else "conllu", Pipeline.DEFAULT, Pipeline.DEFAULT, "conllu")
    for pattern in args.filenames:
        for in_file in glob(pattern) or [pattern]:
            basename = os.path.basename(in_file)
            out_file = os.path.join(args.out_dir, os.path.splitext(basename)[0] + ".conllu")
            error = ProcessingError()
            with open(in_file, encoding="utf-8") as f:
                processed = pipeline.process(f.read(), error)
            if error.occurred():
                raise RuntimeError(error.message)
            with open(out_file, "w", encoding="utf-8") as f:
                f.write(processed)
            if not args.quiet:
                print("Wrote '%s'" % out_file)

if __name__ == '__main__':
    argparser = argparse.ArgumentParser(description=desc)
    argparser.add_argument("model", help="udpipe model to load")
    argparser.add_argument("filenames", nargs="+", help=".conllu file names to annotate")
    argparser.add_argument("-t", "--txt", action="store_true", help="assume input is untokenized text")
    argparser.add_argument("-o", "--out-dir", default=".", help="directory to write parsed files to")
    argparser.add_argument("-q", "--quiet", action="store_true", help="do not print anything")
    main(argparser.parse_args())

