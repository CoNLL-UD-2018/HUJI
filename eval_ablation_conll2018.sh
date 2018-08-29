#!/bin/bash

DIV=test
[[ $# -ge 1 ]] && DIV=$1 && shift
for PRED in parsed/conll2018/${DIV}.ablation/en_ewt*.conllu; do
  GOLD=../data/ud-treebanks-v2.2/*/en_ewt-ud-${DIV}.conllu
  MODEL=${PRED%.*}
  printf '%s\t' ${MODEL##*/}
  python tupa/scripts/conll18_ud_eval.py ${GOLD} ${PRED} -v | grep '^E*LAS' | cut -d'|' -f4 --output-delimiter="\t" | paste -s
done

