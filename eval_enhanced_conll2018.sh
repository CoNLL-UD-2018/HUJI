#!/bin/bash

DIV=test
TREEBANKS="ar_padt cs_cac cs_fictree cs_pdt nl_alpino nl_lassysmall en_ewt en_pud fi_tdt lv_lvtb pl_lfg sk_snk sv_pud sv_talbanken"
[[ $# -ge 1 ]] && DIV=$1 && shift
[[ $# -ge 1 ]] && TREEBANKS="$*"
printf '%-21s%-15s%-15s%s\n' treebank precision recall f1
for CODE in ${TREEBANKS}; do
  GOLD=../data/ud-treebanks-v2.2/*/${CODE}-ud-${DIV}.conllu
  PRED=parsed/conll2018/${DIV}/${CODE}.conllu
  printf '%-16s' ${CODE}
  python tupa/scripts/conll18_ud_eval.py ${GOLD} ${PRED} -v | grep '^ELAS' | cut -d'|' -f2-4 --output-delimiter='    '
done

