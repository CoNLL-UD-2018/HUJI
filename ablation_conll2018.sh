#!/usr/bin/env bash
#SBATCH --mem=20G
#SBATCH --time=0-3

if [[ -z "${SLURM_ARRAY_TASK_ID}" ]]; then
  echo Run this as:
  echo "sbatch --array=1-7 ablation_conll2018.sh [dev]"
  exit 1
fi
DIV=test
[[ $# -ge 1 ]] && DIV=$1
MODEL=$(sed -n ${SLURM_ARRAY_TASK_ID}p ablation.txt)
echo ${MODEL}

. ./activate_conll2018.sh

rm -f "parsed/conll2018/${DIV}.ablation/${MODEL}.conllu"
python -m tupa parsed/conll2018/${DIV}-udpipe/en_ewt-ud-${DIV}.conllu -o parsed/conll2018/${DIV}.ablation -j ${MODEL} -m models/conll2018/${MODEL} --verbose=1 --max-length=300 --vocab=- --dep-dim=0 --omit-features=d --max-height=100 -e --formats conllu || exit 1
python tupa/scripts/conll18_ud_eval.py ../data/ud-treebanks-v2.2/UD_English-EWT/en_ewt-ud-${DIV}.conllu parsed/conll2018/${DIV}.ablation/${MODEL}.conllu

python -m tupa parsed/conll2018/${DIV}-udpipe/en_ewt-ud-${DIV}.conllu -o parsed/conll2018/${DIV}.ablation.xml/${MODEL} -m models/conll2018/${MODEL} --verbose=1 --max-length=300 --vocab=- --dep-dim=0 --omit-features=d --max-height=100 -e --formats xml
