#!/usr/bin/env bash
#SBATCH --mem=20G
#SBATCH --time=1-0

if [[ -z "${SLURM_ARRAY_TASK_ID}" ]]; then
  if [[ $# -lt 2 ]]; then
    echo Run this as:
    echo "sbatch --array=1-121%5 run_conll2018.sh test"
    exit 1
  else
    TREEBANK_DIR=$1
    shift
  fi
else
  TREEBANK_DIR=$(readlink -f $(sed -n ${SLURM_ARRAY_TASK_ID}p waiting.txt))
fi
DIV=test
[[ $# -ge 1 ]] && DIV=$1
if [ ! -d ${TREEBANK_DIR} ]; then
  echo Not a directory: ${TREEBANK_DIR}
  exit 1
fi
echo ${TREEBANK_DIR}  # Subdirectory of ../data/ud-treebanks-v2.2/
echo ${SLURM_ARRAY_TASK_ID}

. ./activate_conll2018.sh
. ./activate_models_conll2018.sh

TREEBANK_DIR_BASENAME=$(basename ${TREEBANK_DIR})
TEST_FILE=${TREEBANK_DIR}/*-ud-${DIV}.conllu
TEST_FILE_TXT=${TREEBANK_DIR}/*-ud-${DIV}.txt
TEST_FILE_BASENAME=$(basename ${TEST_FILE})
LANG=${TEST_FILE_BASENAME%_*}
CODE=${TEST_FILE_BASENAME%%-*}
if [[ "${CODE}" == "*" ]]; then
  echo ${DIV} file not found
  exit 1
fi

# Find suffix of UDPipe model to run
PREPROCESS_DIR=parsed/conll2018/${DIV}-udpipe
TREEBANK_CODE=`echo ${TREEBANK_DIR_BASENAME#UD_} | tr '[:upper:]' '[:lower:]'`
for UDPIPE_CODE in $TREEBANK_CODE "${UDPIPE_DEFAULT_MODELS[$TREEBANK_CODE]}" mixed-ud; do
  UDPIPE_MODEL=../udpipe/models/$UDPIPE_CODE-ud-2.2-conll18-180430.udpipe
  if [ -f "$UDPIPE_MODEL" ]; then
    echo using $UDPIPE_MODEL for $TREEBANK_CODE
    break
  fi
done

# Preprocess with UDPipe
python udpipe.py $UDPIPE_MODEL $TEST_FILE_TXT -o $PREPROCESS_DIR -t || exit 1

# Find suffix of model to run
MODELS_DIR=models/conll2018
OUTPUT_DIR=parsed/conll2018/${DIV}
GLOBAL_DEFAULT=xx
MODEL=$MODELS_DIR/$CODE-${MODELS[$CODE]}
DEFAULT=${DEFAULT_MODELS[$LANG]}
DEFAULT_MODEL=$MODELS_DIR/$DEFAULT-${MODELS[$DEFAULT]}
if [ -f "$MODEL.json" ]; then
  echo model $MODEL found
else
  echo default code: $DEFAULT
  echo default model: $DEFAULT_MODEL
  if [ -f "$DEFAULT_MODEL.json" ]; then
    MODEL=$DEFAULT_MODEL
  else
    MODEL=$MODELS_DIR/$GLOBAL_DEFAULT-${MODELS[$GLOBAL_DEFAULT]}
  fi
  echo model not found, using $MODEL instead
fi

[ -f "$OUTPUT_DIR/$CODE.conllu" ] && exit
rm -f "$OUTPUT_DIR/$CODE.conllu"

# Run TUPA
tupa --verbose=1 ${DYNET_FLAGS} --max-length=300 \
  $PREPROCESS_DIR/$TEST_FILE_BASENAME --lang=$LANG --vocab=- \
  --dep-dim=0 --omit-features=d --max-height=100 \
  -m $MODEL -o $OUTPUT_DIR -j $CODE --formats conllu || exit 1

# Evaluate
python tupa/scripts/conll18_ud_eval.py $TEST_FILE $OUTPUT_DIR/$CODE.conllu

# Run again with xml output
#tupa --verbose=1 ${DYNET_FLAGS} --max-length=300 \
#  $PREPROCESS_DIR/$TEST_FILE_BASENAME --lang=$LANG --vocab=- \
#  --dep-dim=0 --omit-features=d --max-height=100 \
#  -m $MODEL -o $OUTPUT_DIR.xml/$CODE --formats xml

