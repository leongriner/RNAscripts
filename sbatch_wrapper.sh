#!/bin/bash

echo "[memory]=1" > sbatch_pref.tmp
echo "[threads]=1" >> sbatch_pref.tmp

declare -a hold_array
readarray -t hold_array < sbatch_pref.tmp
printf -v readstr '%s ' "${hold_array[@]}"
sandwich="("$readstr")"
declare -A pref_arr="$sandwich"
eval "declare -A pref_arr="$sandwich""

echo "${pref_arr[memory]}"

mem_var="${pref_arr[memory]}"
threads_var="${pref_arr[threads]}"

awk '{if ($0 ~ /#SBATCH --mem/) $0="#SBATCH --mem="$mem_var"G"; else   sbatch_pass.sh