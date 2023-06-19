#!/bin/bash -e

BASEDIR="$(dirname $(readlink -f "$0"))"
cd ${BASEDIR}/..

MODEL=${MODEL:-weights/vicuna/Wizard-Vicuna-30B-Uncensored.ggmlv3.q5_K_M.bin}
PROMPT_TEMPLATE=${PROMPT_TEMPLATE:-./chatscripts/prompts/chat-with-vicuna-v1.txt}

USER_NAME=${USER_NAME:-USER}
AI_NAME=${AI_NAME:-ChatLLaMa}
PROGRAM=./llama.cpp/main

N_THREAD=${N_THREAD:-8}
N_PREDICTS=${N_PREDICTS:-2048}

# orig: --top_k 40 --top_p 0.5, no --mirostat 1
GEN_OPTIONS=${GEN_OPTIONS:---ctx_size 2048 --temp 0.7 --repeat_last_n 256 --batch_size 32 --repeat_penalty 1.17647 --top_k 0 --top_p 0 --mirostat 2 --mirostat-lr 0.05 --mirostat-ent 3.0 --multiline-input --mlock }
DATE_TIME=$(date +%H:%M)
DATE_YEAR=$(date +%Y)
N_CORE=12

PROMPT_FILE=$(mktemp -t llamacpp_prompt.XXXXXXX.txt)

sed -e "s/\[\[USER_NAME\]\]/$USER_NAME/g" \
    -e "s/\[\[AI_NAME\]\]/$AI_NAME/g" \
    -e "s/\[\[DATE_TIME\]\]/$DATE_TIME/g" \
    -e "s/\[\[DATE_YEAR\]\]/$DATE_YEAR/g" \
    $PROMPT_TEMPLATE > $PROMPT_FILE

PROMPT_HASH=$(md5sum ${PROMPT_FILE} | cut -f 1 -d' ')
PROMPT_CACHE_FILE="/tmp/llamacpp_prompt.${PROMPT_HASH}.bin"

if [[ ! -e "$PROMPT_CACHE_FILE" ]];
then
    echo "Prompt cache $PROMPT_CACHE_FILE does not exist, building with $PROMPT_FILE..."
    # Default batch_size to 8 here for better user feedback during initial prompt processing
    # 2>>"$LOG" 
    # Prompt for cache needs space and newline, but prompt for interactive ends with 'USER:' no space

    TRAIN_PROMPT_FILE="$(mktemp -t llamacpp_prompt.XXXXXXX.txt)"
    echo "Creating ${TRAIN_PROMPT_FILE}"
    cp "${PROMPT_FILE}" "${TRAIN_PROMPT_FILE}"
    echo -e " Thank you.\n" >> "${TRAIN_PROMPT_FILE}"
    set -x
    ${PROGRAM} \
	--model ${MODEL} \
        ${GEN_OPTIONS} \
        --file "${TRAIN_PROMPT_FILE}" \
	--prompt-cache "${PROMPT_CACHE_FILE}" \
	--reverse-prompt "${USER_NAME}:" \
	--in-prefix ' ' \
        --batch_size 8 \
        --n_predict 1
    echo
    echo 'Done!'
fi

if [[ ! -e "$PROMPT_CACHE_FILE" ]];
then
    echo "* ERROR: ${PROMPT_CACHE_FILE} was not created"
    exit 1
fi

set -x
#   --color
${PROGRAM} \
    --model ${MODEL} \
    --threads ${N_CORE} \
    --interactive \
    --file "${PROMPT_FILE}" \
    --prompt-cache "${PROMPT_CACHE_FILE}" \
    --prompt-cache-ro \
    --reverse-prompt "${USER_NAME}:" \
    --in-prefix ' ' \
    ${GEN_OPTIONS} \
    ${*}
