TUPA in the CoNLL 2018 UD Shared Task
=====================================
TUPA is a transition-based parser for [Universal Conceptual Cognitive Annotation (UCCA)][1].

This repository contains the version of TUPA used as the submission by the HUJI team to the [CoNLL 2018 UD Shared Task](http://universaldependencies.org/conll18/):

    @InProceedings{hershcovich2018universal,
      author    = {Hershcovich, Daniel  and  Abend, Omri  and  Rappoport, Ari},
      title     = {Universal Dependency Parsing with a General Transition-Based DAG Parser},
      booktitle = {Proc. of CoNLL UD 2018 Shared Task},
      year      = {2018},
      url       = {http://www.cs.huji.ac.il/~danielh/udst2018.pdf}
    }

System outputs on development and test treebanks, as well as trained models (including ablation experiments), are available [in this release](https://github.com/CoNLL-UD-2018/HUJI/releases/tag/udst2018).

For more information, please see the [official TUPA code repository](https://github.com/huji-nlp/tupa).


### Requirements
* Python 3.6+


### Training

Download the [UD treebanks](http://hdl.handle.net/11234/1-2837) and extract them (e.g. to `../data/ud-treebanks-v2.2`).

Run `train_conll2018.sh` to train a model on each treebank. For example, to train on `../data/ud-treebanks-v2.2/UD_English-EWT`, run:

    ./train_conll2018.sh ../data/ud-treebanks-v2.2/UD_English-EWT

Or, if you have a [slurm](https://slurm.schedmd.com) cluster, just run

    sbatch --array=1-121 train_conll2018.sh

to train models for all treebanks.

### Parsing

Either download the [pre-trained models](https://github.com/CoNLL-UD-2018/HUJI/releases/tag/udst2018), or train your own (see above). If you trained your own models, update their suffixes in `activate_models_conll2018.sh`.

To parse the test treebanks, run `run_conll2018.sh`. For example:

    ./run_conll2018.sh ../data/ud-treebanks-v2.2/UD_English-EWT

Or parse all test treebanks using slurm:

    sbatch --array=1-121 run_conll2018.sh

To parse the development treebanks, run:

    ./run_conll2018.sh ../data/ud-treebanks-v2.2/UD_English-EWT dev

Or parse all development treebanks using slurm:

    sbatch --array=1-121 run_conll2018.sh dev


### Evaluation

Either run the models yourself (see above), or download the [system outputs](https://github.com/CoNLL-UD-2018/HUJI/releases/download/udst2018/tupa_conll2018_output.tar.gz).

To get LAS-F1 scores for test treebanks, run:

    ./eval_conll2018.sh
    
To get LAS-F1 scores for dev treebanks, run:

    ./eval_conll2018.sh dev

For evaluation on enhanced dependencies, run:

    ./eval_enhanced_conll2018.sh


Author
------
* Daniel Hershcovich: danielh@cs.huji.ac.il


License
-------
This package is licensed under the GPLv3 or later license (see [`LICENSE.txt`](LICENSE.txt)).

[1]: http://github.com/huji-nlp/ucca
