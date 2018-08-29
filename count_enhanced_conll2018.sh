#!/bin/bash

DIV=test
TREEBANKS="ar_padt cs_cac cs_fictree cs_pdt nl_alpino nl_lassysmall en_ewt en_pud fi_tdt lv_lvtb pl_lfg sk_snk sv_pud sv_talbanken"
[[ $# -ge 1 ]] && DIV=$1 && shift
[[ $# -ge 1 ]] && TREEBANKS="$*"
for CODE in ${TREEBANKS}; do
  GOLD=../data/ud-treebanks-v2.2/*/${CODE}-ud-${DIV}.conllu
  PRED=parsed/conll2018/${DIV}/${CODE}.conllu
  DIV=train && PRED=${GOLD}
  printf '%-16s' ${CODE}
  python tupa/scripts/conll18_ud_eval.py ${GOLD} ${PRED} -c | grep '^E*LAS' | cut -d'|' -f3 | paste -s
done

