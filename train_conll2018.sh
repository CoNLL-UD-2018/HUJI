#!/usr/bin/env bash
#SBATCH --mem=20G
#SBATCH --time=7-0


if [[ $# -lt 1 ]]; then
  if [[ -z "${SLURM_ARRAY_TASK_ID}" ]]; then
    echo "Usage: $0 TREEBANK_DIR [SUFFIX]"
    exit 1
  else
    TRAIN_ARGS=($(sed -n ${SLURM_ARRAY_TASK_ID}p waiting.txt))
  fi
else
  TRAIN_ARGS=("$@")
fi
echo ${TRAIN_ARGS[@]}

TREEBANK_DIR=$(readlink -f ${TRAIN_ARGS[0]})  # Subdirectory of ../data/release-2.2-st-train-dev-data/ud-treebanks-v2.2/
TRAIN_ARGS=("${TRAIN_ARGS[@]:1}")
if [[ ${#TRAIN_ARGS} -lt 1 ]]; then
  SUFFIX=`date '+%Y%m%d'`
else
  SUFFIX="${TRAIN_ARGS[0]}"
  TRAIN_ARGS=("${TRAIN_ARGS[@]:1}")
fi

if [ ! -d ${TREEBANK_DIR} ]; then
    echo Not a directory: ${TREEBANK_DIR}
    exit 1
fi

. ./activate_conll2018.sh

TREEBANK_DIR_BASENAME=$(basename ${TREEBANK_DIR})
TRAIN_FILE=${TREEBANK_DIR}/*-ud-train.conllu
TRAIN_FILE_BASENAME=$(basename ${TRAIN_FILE})
DEV_FILE=${TREEBANK_DIR}/*-ud-dev.conllu

LANG=${TRAIN_FILE_BASENAME%_*}
MODEL_NAME=${TRAIN_FILE_BASENAME%%-*}
LANG_WORD_VECTORS=../word_vectors/cc.$LANG.300.vec

CONVERTED_TRAIN_DIR=../converted/ud-treebanks-v2.2/${TREEBANK_DIR_BASENAME}/train
CONVERTED_DEV_DIR=../converted/ud-treebanks-v2.2/${TREEBANK_DIR_BASENAME}/dev

# Get word vectors
if [ ! -f ${LANG_WORD_VECTORS} ]; then
    wget https://s3-us-west-1.amazonaws.com/fasttext-vectors/wiki.$LANG.vec -O ${LANG_WORD_VECTORS} || exit 1
fi

if [ -s ${LANG_WORD_VECTORS} ]; then
  WORD_VECTORS_FLAG="--word-vectors=${LANG_WORD_VECTORS}"
else
  WORD_VECTORS_FLAG="--word-dim-external=0"
fi

# Convert CoNLL-U to XML
if [ ! -d ${CONVERTED_TRAIN_DIR} ]; then
  python -m semstr.convert ${TRAIN_FILE} -o ${CONVERTED_TRAIN_DIR} --annotate -sv || exit 1
fi
TRAIN_DEV_FLAG="-t ${CONVERTED_TRAIN_DIR} -d ${CONVERTED_DEV_DIR}"
if [ ! -d ${CONVERTED_DEV_DIR} ]; then
  if [ -f $DEV_FILE ]; then
    python -m semstr.convert ${DEV_FILE} -o ${CONVERTED_DEV_DIR} --annotate -sv || exit 1
  else
    TRAIN_DEV_FLAG="--folds=10 ${CONVERTED_TRAIN_DIR}"
  fi
fi
if [ `ls ${CONVERTED_TRAIN_DIR} | wc -l` -lt 100 ]; then
  ITER_FLAG="-I 400=--optimizer=sgd 800=--optimizer=amsgrad"
else
  ITER_FLAG="-I 100=--optimizer=sgd 300=--optimizer=amsgrad"
fi

# Train TUPA
tupa --verbose=1 -W --seed=$RANDOM ${DYNET_FLAGS} --max-length=300 \
  ${TRAIN_DEV_FLAG} ${ITER_FLAG} --lang=$LANG ${WORD_VECTORS_FLAG} --vocab=- \
  --dep-dim=0 --omit-features=d --max-height=100 \
  -m "models/conll2018/$MODEL_NAME-$SUFFIX" ${TRAIN_ARGS[@]}
