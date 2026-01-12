# What Is This?

This folder have scripts for step-to-step train a G2P (Grapheme-to-Phoneme) model using Phonetisaurus for generation new pronunciations for OOV (Out-of-vocabulary) words. Need a lexicon in CMUDICT format. Phonetisaurus is a program for G2P with Fst (Weighted Finite-State Transducers) method using OpenFST toolkit. 

# STEP-STEP

## Setup files and create folders
```bash
bash ./phonetisaurus.sh setup  
```
## Compile all tools include all ngram builder tools
```bash
bash ./phonetisaurus.sh compile_all
```
## Train model for G2P
```bash
bash ./phonetisaurus.sh train lexicon ngram_order lm
```

**lexicon:** Lexicon file in CMU Dict format.

**ngram_order:** Ngram Order for train ngram model (default: 6).

**lm:** Ngram builder tool (default: kenlm)

### List of ngram builder

KenLM (kenlm)

MitLM (mitlm)

## Get predicts (pronunciations) of a wordlist

```bash
bash ./phonetisaurus.sh get_predict wordlist output_dic 
```

**wordlist:** wordlist file.

**output_dic:** Output file with (words+pronunciations) (default: output.dic)
