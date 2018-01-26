#!/bin/bash

#Prevent expansion of * when no matching files present.
shopt -s nullglob

#Load test
echo "stringtie_script_cluster.sh load successful"

#Parameter/preference loading
declare -a SThold_array
readarray -t SThold_array < STpref.tmp
printf -v STreadstr '%s ' "${SThold_array[@]}"
sandwich="("$STreadstr")"
eval "declare -A pref_arr="$sandwich""

#Set basedir as a variable for easier referencing
basedir="${STpref_arr[basedir]}"
echo "Base directory set to "$basedir"."

#Set basenames array
case ${STpref_arr[basename_check]} in
  Y|y) declare -a basename ; readarray -t basename < basename_list.txt; echo "Basenames load successful" ;;
  *) echo -e '\E['31';'01'm Basenames not set. Exiting.';tput sgr0; exit 1 ;;
esac

# Stringtie
for i in "${basename[@]}"
  do mkdir $basedir/working/"$i"_stringtie/
  stringtie $basedir/working/"$i"_sorted.bam -p "${STpref_arr[threads]}" -o $basedir/working/"$i"_stringtie/"$i"_sorted.gtf -G $basedir/references/grch38_gtf/Homo_sapiens.GRCh38.84.gtf
  if [ $? = 0 ]; then # error checking
    echo "StringTie GTF generation of" $i "done"
  else
    echo "StringTie GTF generation of" $i "encountered an error, aborted"
    exit 1
  fi
done

# Stringtie Merge
stringtie --merge -p "${STpref_arr[threads]}" -o $basedir/working/stringtie_merged.gtf -G $basedir/references/grch38_gtf/Homo_sapiens.GRCh38.84.gtf $basedir/working/*_stringtie/*_sorted.gtf
if [ $? = 0 ]; then # error checking
  echo "StringTie GTF merge done"
else
  echo "StringTie GTF merge done"
  exit 1
fi

# Stringtie eB. eB provides better estimates. and generates Ballgown outputs.
for i in "${basename[@]}"
  do mkdir $basedir/working/"$i"_stringtie_eB/
  stringtie $basedir/working/"$i"_sorted.bam -p "${STpref_arr[threads]}" -e -B -o $basedir/working/"$i"_stringtie_eB/"$i"_sorted_eB.gtf -G $basedir/working/stringtie_merged.gtf
  if [ $? = 0 ]; then # error checking
    echo "StringTie GTF generation of" $i "done"
  else
    echo "StringTie GTF generation of" $i "encountered an error, aborted"
    exit 1
  fi
done
