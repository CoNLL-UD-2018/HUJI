#!/bin/bash

DIV=test
TREEBANKS="af_afribooms grc_perseus grc_proiel ar_padt hy_armtdp eu_bdt br_keb bg_btb bxr_bdt ca_ancora hr_set cs_cac cs_fictree cs_pdt cs_pud da_ddt nl_alpino nl_lassysmall en_ewt en_gum en_lines en_pud et_edt fo_oft fi_ftb fi_pud fi_tdt fr_gsd fr_sequoia fr_spoken gl_ctg gl_treegal de_gsd got_proiel el_gdt he_htb hi_hdtb hu_szeged zh_gsd id_gsd ga_idt it_isdt it_postwita ja_gsd ja_modern kk_ktb ko_gsd ko_kaist kmr_mg la_ittb la_perseus la_proiel lv_lvtb pcm_nsc sme_giella no_bokmaal no_nynorsk no_nynorsklia fro_srcmf cu_proiel fa_seraji pl_lfg pl_sz pt_bosque ro_rrt ru_syntagrus ru_taiga sr_set sk_snk sl_ssj sl_sst es_ancora sv_lines sv_pud sv_talbanken th_pud tr_imst uk_iu hsb_ufal ur_udtb ug_udt vi_vtb"
[[ $# -ge 1 ]] && [[ $1 == --enhanced ]] && ENHANCED=1 && shift
[[ $# -ge 1 ]] && DIV=$1 && shift
[[ $# -ge 1 ]] && TREEBANKS="$*"
for CODE in ${TREEBANKS}; do
  printf '%-16s' ${CODE}
  GOLD=../data/ud-treebanks-v2.2/*/${CODE}-ud-${DIV}.conllu
  PRED=parsed/conll2018/${DIV}/${CODE}.conllu
  [ ${DIV} == train ] && PRED=${GOLD}
  if [ -f ${GOLD} -a -f ${PRED} ]; then
    if [ -n "${ENHANCED}" ]; then
      if grep -q ':\S*|' ${GOLD}; then
        TEMP=$(mktemp)
        python ../semstr/semstr/evaluate.py ${PRED} ${GOLD} -s ${TEMP} >& ${CODE}.${DIV}.txt
        tail -1 ${TEMP} | cut -d, -f4-6
      else
        printf '\r'
      fi
    else
      python tupa/scripts/conll18_ud_eval.py ${GOLD} ${PRED} |& sed -n '/^LAS\>\|UDError:/{s/[^:]*://;p}'
    fi
  else
    echo " nan"
  fi
done
echo

