#!/usr/bin/env bash
#SBATCH --mem=20G
#SBATCH --time=7-0

if [[ $# -lt 1 ]]; then
  SUFFIX=`date '+%Y%m%d'`
else
  SUFFIX="$1"
  shift
fi
echo "$SUFFIX"

. ./activate_conll2018.sh

tupa --verbose=1 -W --seed=$RANDOM ${DYNET_FLAGS} -I 5 --max-length=300 \
  -t ../converted/ud-treebanks-v2.2/*/train \
  -d ../converted/ud-treebanks-v2.2/*/dev \
  --word-dim-external=0 --word-dim=0 --lemma-dim=0 --tag-dim=0 --prefix-dim=0 --suffix-dim=0 --vocab=- \
  --dep-dim=0 --omit-features=d --max-height=100 \
  -m "models/conll2018/xx-$SUFFIX" $*
