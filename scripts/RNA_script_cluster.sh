#!/bin/bash -e
#SBATCH -J RNASeqprocessing
#SBATCH --time=06:00:00     # Walltime
#SBATCH -A XXX       # Project Account
#SBATCH --mem=5
#SBATCH --cpus-per-task=5
#SBATCH --mail-type ALL
#SBATCH --mail-user XXX

#Prevent expansion of * when no matching files present.
shopt -s nullglob

#Load test
echo "RNA_script_cluster.sh load successful"

#Parameter/preference loading
declare -a hold_array
readarray -t hold_array < pref.tmp
printf -v readstr '%s ' "${hold_array[@]}"
sandwich="("$readstr")"
declare -A pref_arr="$sandwich"
eval "declare -A pref_arr="$sandwich""

# Declaring an associative array allows for easy referecing of parameters vs indexed array (does not need to
# invoke reading through AWK, SED or GREP, does not need to know the index number of the parameter,
# intuitive to script and easy to add/remove parameters). Passing to the assoc. array is ugly but worth it.

#Case testing in wrapper script should ensure that the

#Set basedir as a variable for easier referencing
basedir="${pref_arr[basedir]}"
echo "Base directory set to "$basedir"."

#Set basenames array
case ${pref_arr[basename_check]} in
  Y|y) declare -a basename ; readarray -t basename < basename_list.txt; echo "Basenames load successful" ;;
  *) echo -e '\E['31';'01'm Basenames not set. Exiting.';tput sgr0; exit 1 ;;
esac

# Load HISAT2 module
module load HISAT2/2.0.5-gimkl-2017a
# Load SAMtools module
module load SAMtools/1.6-gimkl-2017a

#Perform read trimming using BBDuk in paired read mode (NOTE: BBDuk installed in home directory, not run as a loadable module in the cluster).
if [ ${pref_arr[paired]} = "y" ] || [ ${pref_arr[paired]} = "Y" ] then #check whether the paired preference set to "y" or "Y".
  for i in "${basename[@]}"
    do echo "Running adapter trimming for $i"; /home/test/anaconda3/bin/bbduk.sh -Xmx"${pref_arr[memory]}"G t="${pref_arr[threads]}" in1=$basedir/reads/"$i"_1.fastq in2=$basedir/reads/"$i"_2.fastq out1=$basedir/reads/"$i"_1_tr.fastq out2=$basedir/reads/"$i"_2_tr.fastq ref=/home/test/anaconda3/pkgs/bbmap-37.77-0/opt/bbmap-37.77/resources/adapters.fa ktrim=r k=23 mink=11 hdist=1 tpe tbo qtrim=r trimq=10
    if [ $? = 0 ] #open error check
      then
        rm $basedir/reads/"$i"_1.fastq $basedir/reads/"$i"_2.fastq ;
        echo "Adapter trimming done of" $i "done, FASTQ files removed."
      else
        echo  -e '\E['31';'01'm Adapter trimming of ' "$i" ' encountered an error, aborted.'; tput sgr0; exit 1
    fi
  done
else echo ""
fi

# Perform read trimming using BBDuk in single read mode (NOTE: BBDuk installed in home directory, not run as a loadable module in the cluster).
if [ ${pref_arr[paired]} = "n" ] || [ ${pref_arr[paired]} = "N" ] then #check whether the paired preference set to "n" or "N".
  for i in "${basename[@]}"
    do echo "Running adapter trimming for $i"; /home/test/anaconda3/bin/bbduk.sh -Xmx"${pref_arr[memory]}"G t="${pref_arr[threads]}" in=$basedir/reads/"$i".fastq out=$basedir/reads/"$i"_tr.fastq ref=/home/test/anaconda3/pkgs/bbmap-37.77-0/opt/bbmap-37.77/resources/adapters.fa ktrim=r k=23 mink=11 hdist=1 tpe tbo qtrim=r trimq=10
    if [ $? = 0 ] #open error check
      then
        rm $basedir/reads/"$i".fastq;
        echo "Adapter trimming done of" $i "done, FASTQ files removed."
      else
        echo  -e '\E['31';'01'm Adapter trimming of ' "$i" ' encountered an error, aborted.'; tput sgr0; exit 1
    fi
  done
fi

# HISAT2 alignment - paired. Fastq files removed after to save space
if [ ${pref_arr[paired]} = "y" ] || [ ${pref_arr[paired]} = "Y" ]; then #check whether the paired preference set to "y" or "Y".
  for i in "${basename[@]}"
    do echo "Running adapter HISAT2 alignment for $i"; hisat2 -p "${pref_arr[threads]}" -x $basedir/references/grch38_snp_tran/genome_snp_tran -1 $basedir/reads/"$i"_1_tr.fastq -2 $basedir/reads/"$i"_2_tr.fastq -S $basedir/working/"$i".sam --dta
    if [ $? = 0 ]; then #open error check
      rm $basedir/reads/"$i"_1_tr.fastq $basedir/reads/"$i"_2_tr.fastq
      echo "HISAT2 mapping of" $i "done, FASTQ files removed"
    else
      echo  -e '\E['31';'01'm HISAT2 mapping of ' "$i" ' encountered an error, aborted.'; tput sgr0; exit 1
    fi
  done
fi

# HISAT2 alignment - unpaired. Fastq files removed after to save space
if [ ${pref_arr[paired]} = "n" ] || [ ${pref_arr[paired]} = "N" ]; then #check whether the paired preference set to "n" or "N".
  for i in "${basename[@]}"
    do echo "Running adapter HISAT2 alignment for $i"; hisat2 -p "${pref_arr[threads]}" -x $basedir/references/grch38_snp_tran/genome_snp_tran -1 $basedir/reads/"$i"_tr.fastq -S $basedir/working/"$i".sam --dta #NOTE:check how to run in single mode (vs -1. -2)
    if [ $? = 0 ]; then #open error check
      rm $basedir/reads/"$i"_tr.fastq
      echo 'HISAT2 mapping of ' "$i" ' done, FASTQ files removed'
    else
      echo  -e '\E['31';'01'm HISAT2 mapping of ' "$i" ' encountered an error, aborted.'; tput sgr0; exit 1
    fi
  done
fi

# SAM to BAM conversion, SAM files removed after to save space.
for i in "${basename[@]}"
  do samtools view -bS -@ $((pref_arr[threads]-1)) $basedir/working/"$i".sam > $basedir/working/"$i".bam
  if [ $? = 0 ]; then
    rm $basedir/working/"$i".sam
    echo "BAM conversion for" $i "done, SAM file removed"
  else
    echo "BAM conversion for" $i "encountered an error, aborted"
    exit 1
  fi
done

# BAM sorting, BAM files removed after to save space.
for i in "${basename[@]}"
  do samtools sort -@ $((pref_arr[threads]-1)) -m "${pref_arr[memory]}"G -o $basedir/working/"$i"_sorted.bam $basedir/working/"$i".bam
  if [ $? = 0 ]; then
    rm $basedir/working/"$i".bam
    echo "BAM sorting for" $i "done, BAM file removed"
  else
    echo "BAM sorting for" $i "encountered an error, aborted"
    exit 1
  fi
done
