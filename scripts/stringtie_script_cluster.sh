#!/bin/bash -e
#SBATCH -J RNASeqprocessing
#SBATCH --time=06:00:00     # Walltime
#SBATCH -A uoa00585       # Project Account
#SBATCH --mem=5
#SBATCH --cpus-per-task=5
#SBATCH --mail-type ALL
#SBATCH --mail-user l.griner@auckland.ac.nz

#Prevent expansion of * when no matching files present.
shopt -s nullglob

#Load test
echo "stringtie_script_cluster.sh load successful"

#Parameter/preference loading
declare -a hold_array
readarray -t hold_array < pref.tmp
printf -v readstr '%s ' "${hold_array[@]}"
sandwich="("$readstr")"
declare -A pref_arr="$sandwich"
eval "declare -A pref_arr="$sandwich""

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
  if [ $? = 0 ]; then # error checking
    echo "StringTie GTF generation of" $i "done"
  else
    echo "StringTie GTF generation of" $i "encountered an error, aborted"
    exit 1
  fi
done

# Stringtie Merge
stringtie --merge -p "${pref_arr[threads]}" -o $basedir/working/stringtie_merged.gtf -G $basedir/references/grch38_gtf/Homo_sapiens.GRCh38.84.gtf $basedir/working/*_stringtie/*_sorted.gtf
if [ $? = 0 ]; then # error checking
  echo "StringTie GTF merge done"
else
  echo "StringTie GTF merge done"
  exit 1
fi

# Stringtie eB. eB provides better estimates. and generates Ballgown outputs.
for i in "${basename[@]}"
  do mkdir $basedir/working/"$i"_stringtie_eB/
  stringtie $basedir/working/"$i"_sorted.bam -p 12 -e -B -o $basedir/working/"$i"_stringtie_eB/"$i"_sorted_eB.gtf -G $basedir/working/stringtie_merged.gtf
  if [ $? = 0 ]; then # error checking
    echo "StringTie GTF generation of" $i "done"
  else
    echo "StringTie GTF generation of" $i "encountered an error, aborted"
    exit 1
  fi
done
