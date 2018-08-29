#!/usr/bin/env bash
#SBATCH --mem=20G
#SBATCH --time=7-0

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 COMMAND TREEBANK_DIR [SUFFIX]"
  exit 1
fi
COMMAND="$1"
shift
TREEBANK_DIR=$(readlink -f $1)  # Subdirectory of ../data/release-2.2-st-train-dev-data/ud-treebanks-v2.2/
shift
if [ ! -d ${TREEBANK_DIR} ]; then
    echo Not a directory: ${TREEBANK_DIR}
    exit 1
fi
if [[ "$COMMAND" == models/* ]]; then
  COMMAND=${COMMAND#*/}
  SUFFIX=${COMMAND##*-}
  COMMAND=${COMMAND%-*}
elif [[ $# -lt 1 ]]; then
  SUFFIX=`date '+%Y%m%d'`
else
  SUFFIX="$1"
  shift
fi
echo "$COMMAND" "$TREEBANK_DIR" "$SUFFIX"

. ./activate_conll2018.sh

TREEBANK_DIR_BASENAME=$(basename ${TREEBANK_DIR})
TRAIN_FILE=${TREEBANK_DIR}/*-ud-train.conllu
TRAIN_FILE_BASENAME=$(basename ${TRAIN_FILE})
DEV_FILE=${TREEBANK_DIR}/*-ud-dev.conllu

LANG=${TRAIN_FILE_BASENAME%_*}
MODEL_NAME=${TRAIN_FILE_BASENAME%%-*}-${COMMAND}
LANG_WORD_VECTORS=../word_vectors/cc.$LANG.300.vec

CONVERTED_TRAIN_DIR=../converted/ud-treebanks-v2.2/${TREEBANK_DIR_BASENAME}/train
CONVERTED_DEV_DIR=../converted/ud-treebanks-v2.2/${TREEBANK_DIR_BASENAME}/dev
if [ -f ${DEV_FILE} ]; then
  DEV_FLAG="-d ${CONVERTED_DEV_DIR}"
else
  DEV_FLAG=""
fi
TRAIN_SIZE=`ls ${CONVERTED_TRAIN_DIR} | wc -l`

case "$LANG" in
    en) UCCA_TRAIN_LANG=${UCCA_TRAIN} ;;
    de) UCCA_TRAIN_LANG=${UCCA_DE_TRAIN} ;;
    fr) UCCA_TRAIN_LANG=${UCCA_FR_TRAIN} ;;
esac

case "$COMMAND" in
    ucca-amr)    ARGS=(-t ${CONVERTED_TRAIN_DIR} ${UCCA_TRAIN_LANG} ${AMR_TRAIN}             --use-gold-node-labels -u ucca amr     --layers=1 --hyperparams "conllu --layers=2 --lstm-layers=2 --lstm-layer-dim=300 --embedding-layer-dim=300" "shared --lstm-layers=2 --lstm-layer-dim=300 --embedding-layer-dim=300") ;;
    ucca-amr-dm) ARGS=(-t ${CONVERTED_TRAIN_DIR} ${UCCA_TRAIN_LANG} ${AMR_TRAIN} ${DM_TRAIN} --use-gold-node-labels -u ucca amr sdp --layers=1 --hyperparams "conllu --layers=2 --lstm-layers=2 --lstm-layer-dim=300 --embedding-layer-dim=300" "shared --lstm-layers=2 --lstm-layer-dim=300 --embedding-layer-dim=300") ;;
    ucca-dm)     ARGS=(-t ${CONVERTED_TRAIN_DIR} ${UCCA_TRAIN_LANG} ${DM_TRAIN}                                     -u ucca sdp     --layers=1 --hyperparams "conllu --layers=2 --lstm-layers=2 --lstm-layer-dim=300 --embedding-layer-dim=300" "shared --lstm-layers=2 --lstm-layer-dim=300 --embedding-layer-dim=300") ;;
    ucca)        ARGS=(-t ${CONVERTED_TRAIN_DIR} ${UCCA_TRAIN_LANG}                                                 -u ucca         --layers=1 --hyperparams "conllu --layers=2 --lstm-layers=2 --lstm-layer-dim=300 --embedding-layer-dim=300" "shared --lstm-layers=2 --lstm-layer-dim=300 --embedding-layer-dim=300") ;;
    amr)         ARGS=(-t ${CONVERTED_TRAIN_DIR} ${AMR_TRAIN}                                --use-gold-node-labels -u amr          --layers=1 --hyperparams "conllu --layers=2 --lstm-layers=2 --lstm-layer-dim=300 --embedding-layer-dim=300" "shared --lstm-layers=2 --lstm-layer-dim=300 --embedding-layer-dim=300") ;;
    amr-dm)      ARGS=(-t ${CONVERTED_TRAIN_DIR} ${AMR_TRAIN} ${DM_TRAIN}                    --use-gold-node-labels -u amr sdp      --layers=1 --hyperparams "conllu --layers=2 --lstm-layers=2 --lstm-layer-dim=300 --embedding-layer-dim=300" "shared --lstm-layers=2 --lstm-layer-dim=300 --embedding-layer-dim=300") ;;
    dm)          ARGS=(-t ${CONVERTED_TRAIN_DIR} ${DM_TRAIN}                                                        -u sdp          --layers=1 --hyperparams "conllu --layers=2 --lstm-layers=2 --lstm-layer-dim=300 --embedding-layer-dim=300" "shared --lstm-layers=2 --lstm-layer-dim=300 --embedding-layer-dim=300") ;;
    *) echo "Invalid command: $COMMAND"; exit 1 ;;
esac
tupa "${ARGS[@]}" --verbose=1 --eval-test -m "models/conll2018/$MODEL_NAME-$SUFFIX" \
  -W --seed $RANDOM --max-length=300 --dep-dim 0 --omit-features=d ${DEV_FLAG} --lang $LANG \
  --word-vectors ${LANG_WORD_VECTORS} --vocab - --max-training-per-format=${TRAIN_SIZE} $*
