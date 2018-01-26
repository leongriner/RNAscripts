#!/bin/bash

#Prevent expansion of * when no matching files present.
shopt -s nullglob

#Load test
echo "stringtie_script_local.sh load successful"

#Parameter/preference loading
declare -a hold_array #declare an array to pass preferences into - needs to be an indexed array as readarray does not work with associative arrays.
readarray -t hold_array < pref.tmp #pass file contents to indexed array
printf -v readstr '%s ' "${hold_array[@]}" #read contents of hold_array as a space-separated string
eval "declare -A pref_arr=("$readstr")" #pass string to declared associative array. Needs to run through eval.

#Set basedir as a variable for easier referencing
basedir="${pref_arr[basedir]}"
echo "Base directory set to "$basedir"."

#Set basenames array
case ${pref_arr[basename_check]} in
  Y|y) declare -a basename ; readarray -t basename < basename_list.txt; echo "Basenames load successful" ;;
  *) echo -e '\E['31';'01'm Basenames not set. Exiting.';tput sgr0; exit 1 ;;
esac

# Stringtie
for i in "${basename[@]}"
  do mkdir $basedir/working/"$i"_stringtie/
  stringtie $basedir/working/"$i"_sorted.bam -p "${pref_arr[threads]}" -o $basedir/working/"$i"_stringtie/"$i"_sorted.gtf -G $basedir/references/grch38_gtf/Homo_sapiens.GRCh38.84.gtf
  if [ $? = 0 ]; then
    echo "StringTie GTF generation of" $i "done"
  else
    echo "StringTie GTF generation of" $i "encountered an error, aborted"
    exit 1
  fi
done

# Stringtie Merge
stringtie --merge -p "${pref_arr[threads]}" -o $basedir/working/stringtie_merged.gtf -G $basedir/references/grch38_gtf/Homo_sapiens.GRCh38.84.gtf $basedir/working/*_stringtie/*_sorted.gtf
if [ $? = 0 ]; then
  echo "StringTie GTF merge done"
else
  echo "StringTie GTF merge done"
  exit 1
fi

# Stringtie eB
for i in "${basename[@]}"
  do mkdir $basedir/working/"$i"_stringtie_eB/
  stringtie $basedir/working/"$i"_sorted.bam -p "${pref_arr[threads]}" -e -B -o $basedir/working/"$i"_stringtie_eB/"$i"_sorted_eB.gtf -G $basedir/working/stringtie_merged.gtf
  if [ $? = 0 ]; then
    echo "Generation of stringTie GTF and Ballgown files for" $i "done"
  else
    echo "Generation of stringTie GTF and Ballgown files for" $i "encountered an error, aborted"
    exit 1
  fi
done
