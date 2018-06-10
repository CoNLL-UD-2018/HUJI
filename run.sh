#!/usr/bin/env bash

echo $*

cd ~/tupa
. ./activate_parse.sh
. ./activate_models.sh

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 inputDataset outputDir"
  exit 1
fi

inputDataset=$1
outputDir=$2
modelsDir=/media/data/models

for row in $(jq -r '.[] | @base64' < $inputDataset/metadata.json); do
  declare -A l=()
  for var in lcode tcode rawfile psegmorfile outfile goldfile; do
    l[$var]=$(echo $row | base64 --decode | jq -r .$var)
  done
  code=${l[lcode]}_${l[tcode]}
  model=$modelsDir/$code-${MODELS[$code]}
  data=$inputDataset/${l[psegmorfile]}
  default=${DEFAULT_MODELS[${l[lcode]}]}
  default_model=$modelsDir/$default-${MODELS[$default]}
  if [ ! -f $data ]; then  # If UDPipe-processed data does not exist, try to use gold data (trial?)
    data=$inputDataset/${l[goldfile]}
  fi
  if [ -f $model.json ]; then
    echo model $model found
  elif [ -f "$default_model" ]; then
    model=$default_model
    echo model not found, using $model instead
  else  # Copy from baseline output
    echo model not found, copying from baseline output
    cp -v $data $outputDir/$code
    continue
  fi
  python -m tupa --verbose=1 $data -m $model -o $outputDir/$code -e --lang=${l[lcode]}
  # Join all TUPA output files to one
  #tail -n +1 $outputDir/$code/* | sed 's/==> .*\/\(.\+\)\..* <==/# sent_id = \1/' | cat -s > $outputDir/${l[outfile]}
  #tail -n +1 $outputDir/$code/* | sed '/==> .*\/\(.\+\)\..* <==/d' | cat -s > $outputDir/${l[outfile]}
  python -m semstr.scripts.join $outputDir/${l[outfile]} $data $outputDir/$code
  rm -rf $outputDir/$code
done
