#!/bin/bash

DIV=test
TREEBANKS="af_afribooms grc_perseus grc_proiel ar_padt hy_armtdp eu_bdt br_keb bg_btb bxr_bdt ca_ancora hr_set cs_cac cs_fictree cs_pdt cs_pud da_ddt nl_alpino nl_lassysmall en_ewt en_gum en_lines en_pud et_edt fo_oft fi_ftb fi_pud fi_tdt fr_gsd fr_sequoia fr_spoken gl_ctg gl_treegal de_gsd got_proiel el_gdt he_htb hi_hdtb hu_szeged zh_gsd id_gsd ga_idt it_isdt it_postwita ja_gsd ja_modern kk_ktb ko_gsd ko_kaist kmr_mg la_ittb la_perseus la_proiel lv_lvtb pcm_nsc sme_giella no_bokmaal no_nynorsk no_nynorsklia fro_srcmf cu_proiel fa_seraji pl_lfg pl_sz pt_bosque ro_rrt ru_syntagrus ru_taiga sr_set sk_snk sl_ssj sl_sst es_ancora sv_lines sv_pud sv_talbanken th_pud tr_imst uk_iu hsb_ufal ur_udtb ug_udt vi_vtb"
[[ $# -ge 1 ]] && [[ $1 == --enhanced ]] && ENHANCED="Enhanced " && TREEBANKS="ar_padt cs_cac cs_fictree cs_pdt nl_alpino nl_lassysmall en_ewt en_pud fi_tdt lv_lvtb pl_lfg sk_snk sv_pud sv_talbanken" && shift
[[ $# -ge 1 ]] && DIV=$1 && shift
[[ $# -ge 1 ]] && TREEBANKS="$*"
for CODE in ${TREEBANKS}; do
  #printf '%-16s' ${CODE}
  LOG=`grep -rl ${CODE}-ud parsed/conll2018/${DIV}.log`
  #printf '%-16s' ${LOG##*/}
  if [ -n "${LOG}" ]; then
    grep -h "^${ENHANCED}LAS" ${LOG} | sed 's/.*: //'
  else
    echo nan
  fi
done

