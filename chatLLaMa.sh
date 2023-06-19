#!/bin/bash

set -e

cd "$(dirname "$0")/../.." || exit

if [ $# -eq 1 ]; then
    MODEL="./models/${1}"; shift
    echo "model=$MODEL"
elif [ $# -eq 2 ]; then
    CARDINALITY="$1"; shift
    QUANTIZATION="$1"; shift
    MODEL="./models/${CARDINALITY}/ggml-model-${QUANTIZATION}.bin"
else
    echo "usage: $0 CARDINALITY QUANTIZATION"
    echo "CARDINALITY=7B 13B 30B 65B"
    echo "QUANTIZATION=q4_0 q4_1 q5_0 q5_1 q8_0 f16"
    exit 1
fi

PROMPT_TEMPLATE=${PROMPT_TEMPLATE:-./prompts/chat.txt}
USER_NAME="${USER_NAME:-USER}"
AI_NAME="${AI_NAME:-ChatLLaMa}"

# Adjust to the number of CPU cores you want to use.
N_THREAD="${N_THREAD:-4}" # [KLOTZ] was 8
# Number of tokens to predict (made it larger than default because we want a long interaction)
N_PREDICTS="${N_PREDICTS:-2048}"

# Note: you can also override the generation options by specifying them on the command line:
# For example, override the context size by doing: ./chatLLaMa --ctx_size 1024
# was: --top_k 40 --top_p 0.5
GEN_OPTIONS="${GEN_OPTIONS:---ctx_size 2048 --temp 0.7 --top_p 0.3 --repeat_last_n 256 --batch_size 1024 --repeat_penalty 1.17647 --mlock}"

DATE_TIME=$(date +%H:%M)
DATE_YEAR=$(date +%Y)

PROMPT_FILE=$(mktemp -t llamacpp_prompt.XXXXXXX.txt)

sed -e "s/\[\[USER_NAME\]\]/$USER_NAME/g" \
    -e "s/\[\[AI_NAME\]\]/$AI_NAME/g" \
    -e "s/\[\[DATE_TIME\]\]/$DATE_TIME/g" \
    -e "s/\[\[DATE_YEAR\]\]/$DATE_YEAR/g" \
     $PROMPT_TEMPLATE > $PROMPT_FILE

# shellcheck disable=SC2086 # Intended splitting of GEN_OPTIONS
./main $GEN_OPTIONS \
  --model "$MODEL" \
  --threads "$N_THREAD" \
  --n_predict "$N_PREDICTS" \
  --color --interactive \
  --file ${PROMPT_FILE} \
  --reverse-prompt "${USER_NAME}:" \
  --in-prefix ' ' \
  "$@"
