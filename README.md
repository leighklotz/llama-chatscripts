# llama-chatscripts
scripts and prompts for llama.cpp

# quantizing
best to download them from HF but if not, consult this:

```bash
for q in q2_K q3_K q4_K 8_0
    do
	echo "Quantizing ${weight} for q${q}"
	./quantize ./models/${weight}/ggml-model-f16.bin ./models/${weight}/ggml-model-q${q}.bin q${q}
    done
done
```
# running
`./wizard-vicuna.sh`

- Like the originals in https://github.com/ggerganov/llama.cpp you can override MODEL, PROMPT etc
- There is some complexity in making the prompt cache work; I had to make 2 versions of the prompt with different endings;
  otherwise one or the other run would go off unendingly
- end your input with `slash` `enter`; would be nice to use ctrl-enter
- ^C will interrupt, twice to exist
