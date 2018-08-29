#!/usr/bin/env bash

set -x

CONVERTED=../converted-udpipe

export SPACY_MODEL_EN=en_core_web_lg
export SPACY_MODEL_FR=fr_core_news_md
export SPACY_MODEL_DE=de_core_news_sm
export SPACY_MODEL_ES=es
export SPACY_MODEL_PT=pt
export SPACY_MODEL_IT=it
export SPACY_MODEL_NL=nl

DYNET_FLAGS=
if [ -d venv ]; then
  . venv/bin/activate
else
  /usr/bin/python3 -m virtualenv -p /usr/bin/python3 venv || exit 1
  . venv/bin/activate
  pip install cython numpy
  pip install --upgrade pip
  pip install -r requirements.txt || exit 1
  pip install "ufal.udpipe>=1.2.0.1"
  python setup.py install || exit 1
fi
git rev-parse HEAD
date

