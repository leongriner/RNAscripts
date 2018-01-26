#!/bin/bin

#Prevent expansion of * when no matching files present.
shopt -s nullglob

#Introduction and usage explanation
echo -e '\E['34';'01'm-------------------RNAseq Script Wrapper-------------------\n'
echo "This script is designed to collect working parameters/preferences for executing a child script. The child script (RNA_script.sh) will perform Adapter Trimming, 3' quality filtering, HISAT2 alignment against Grch38, SAM-to-BAM conversion and BAM sorting. The way the script is executed will change depending on the parameters you set here. E.g. a different HISAT2 command will be executed depending on if the data is from paired end reads."
echo "The script assumes a directory layout as follows:"
tput sgr0
echo "base directory/"
echo "|--scripts/"
echo "|  \--scripts"
echo "|--reads/"
echo "|  \--FastQ files"
echo "|--references/"
echo "|  \--HISAT2 genome/ (e.g. grch38_snp_tran)"
echo "|     \--HISAT2 genome files"
echo "|  \--grch38_gtf/"
echo "|     \--Homo_sapiens.GRCh38.84.gtf"
echo "\--working/"
echo "   \--basename_list.txt"
echo ""
echo -e '\E['34';'01'm '
echo "Ensure that the Base Directory also contains the sample basename list (basename_list.txt)."
tput sgr0
echo "This file must contain a list of sample basenames (e.g. the basename for a pair of fastq files NGS_data_123_1.fastq and NGS_data_123_2.fastq is NGS_data_123)."
echo "Each basename in the file must be on a separate line with no trailing whitespace. The file must end with the last entry, not with a new line. E.g."
echo -e '\E['32';'01'm<start of file>\c'; tput sgr0; echo -e 'NGS_data_123\E['32';'01'm<line break>'; tput sgr0;
echo -e 'NGS_data_456\E['32';'01'm<line break>'; tput sgr0;
echo -e 'NGS_data_789\E['32';'01'm<end of file>'
echo -e '\E['34';'01'm '
echo "Ensure sure that these are in place before setting preferences. The script will launch after preferences are set."
echo "If the basename or directory layout is incorrect the script will fail."
tput sgr0
echo ""

#Parameters gate
read -n 1 -p "Would you like to begin setting preferences and parameters? [y/n]:" pref_check
case $pref_check in
  y|Y) echo "";;
  n|N) echo ""; echo -e '\E['31';'01'm You have selected no to setting preferences. Exiting.';tput sgr0; exit 1 ;;
  *) echo ""; echo -e '\E['31';'01'm Invalid input. Exiting.';tput sgr0; exit 1 ;;
esac

#Preferences header
echo -e '\E['34';'01'm\n-------------------RNAseq Script Preferences-------------------\n'
echo "Set preferences for this script."
tput sgr0

#Base Directory check - can be replaced with a script that detects folder structure,
echo "Is the current directory the base directory?"
read -n 1 -p "I.e. Does the current dirctory contain the working, reads and reference directories? [y/n] " basedir_check
case $basedir_check in
  y|Y) echo "[basedir]="$(pwd) > pref.tmp ;;
  n|N) echo ""; read -p "Enter the absolute path (no trailing "/"). E.g. /path/to/base/dir " basedir_custom ; echo [basedir]="$basedir_custom" > pref.tmp ;;
  *) echo ""; echo -e '\E['31';'01'm Invalid input. Exiting.';tput sgr0; exit 1 ;;
esac

#Base Name check - can be replaced with a script that detects presence of file.
echo ""
read -n 1 -p "Has a sample basename list file (basename_list.txt) been created in the current directory? [y/n]: " basename_check
case $basename_check in
  y|Y) echo "[basename_check]=""$basename_check" >> pref.tmp ;;
  *) echo ""; echo -e '\E['31';'01'm A sample basename list must be created before proceeding. Exiting.';tput sgr0; exit 1 ;;
esac

#Threads check.
echo ""
read -p "Enter the number of processors/threads would you like to use [#] - press [ENTER] to input: " threads
case $threads in
  [0-999]*) echo "[threads]=""$threads" >> pref.tmp ;;
  *) echo ""; echo -e '\E['31';'01'm Invalid input. Exiting.';tput sgr0; exit 1 ;;
esac

#Mem check.
read -p "Enter the amount of memory (in GB) that would you like to use [#]. Do not add GB suffix. Only use whole numbers - press [ENTER] to input: " memory
case $memory in
  [0-999]*) echo "[memory]=""$memory" >> pref.tmp ;;
  *) echo -e '\E['31';'01'm Invalid input. Exiting.';tput sgr0; exit 1 ;;
esac

#Paired check - can be replaced with a script that reads directory contents to see if fastq files have a _1.fastq and _2.fastq suffix
read -n 1 -p "Are fastq files paired (ending in _1.fastq and _2.fastq) [y/n]: " paired_check
case $paired_check in
  y|Y|n|N) echo "[paired]=""$paired_check" >> pref.tmp ;;
  *) echo -e '\E['31';'01'm Invalid input. Exiting';tput sgr0; exit 1 ;;
esac

#Checks to see whether this is running on a local machine or the cluster. Unsure if this check is possible to script.
echo ""
read -n 1 -p "Are you running this script on the PAN cluster? [y/n]: " cluster_check
case $cluster_check in
  y|Y|n|N) echo "[cluster]=""$cluster_check" >> pref.tmp ;;
  *) echo ""; echo -e '\E['31';'01'm Invalid input. Exiting';tput sgr0; exit 1 ;;
esac
echo ""

#Stringtie Check
read -n 1 -p "Would you like to perform stringtie GTF file generation on the HISAT2/SAMtools output? [y/n]: " stringtie_check
case $stringtie_check in
  y|Y|n|N) echo [stringtie]="$stringtie_check" >> pref.tmp ;;
  *) echo -e '\E['31';'01'm Invalid input. Exiting';tput sgr0; exit 1 ;;
esac

#Execution gate
echo -e '\E['34';'01'm\n\n-------------------RNAseq Analysis Script-------------------\n'
echo "Preferences have been set. Please a) programs have been set to the path variable. b) child scripts have correct paths set to programs."
tput sgr0
read -n 1 -p "Would you like to begin executing the analysis script? [y/n]:" run_check
case $run_check in
  y|Y) echo "";;
  n|N) echo ""; echo -e '\E['31';'01'm You have selected "No" to running the analysis script. Exiting.';tput sgr0; exit 1 ;;
  *) echo ""; echo -e '\E['31';'01'm Invalid input. Exiting.';tput sgr0; exit 1 ;;
esac

#---DIFFERENTIAL SCRIPT EXECUTION-----

#Parameter/preference loading
declare -a hold_array #declare an array to pass preferences into - needs to be an indexed array as readarray does not work with associative arrays.
readarray -t hold_array < pref.tmp #pass file contents to indexed array
printf -v readstr '%s ' "${hold_array[@]}" #read contents of hold_array as a space-separated string
sandwich="("$readstr")" #sandwiching readstr between (). Cluster bash interprets brackes differently to local bash when () used in declare so this is set via intermediate variable.
case $cluster_check in
  y|Y) declare -A pref_arr="$sandwich" ;;#pass string to declared associative array. Eval seems to work weird on te cluster but declare seems to work ok without eval.
  n|N) eval "declare -A pref_arr="$sandwich"" #pass string to declared associative array. Needs to run through eval to be interepreted as a bash command.
esac

# Declaring an associative array allows for easy referecing of parameters vs indexed array (does not need to
# invoke pattern matching through AWK, SED or GREP, does not need to know the index number of the parameter,
# intuitive to script and easy to add/remove parameters). Passing to the assoc. array is ugly but worth it.

#Preference passing to cluster scripts via awk (parent/child variable passing doesn't work on the cluster)
if [ "${pref_arr[cluster]}" = "y" ] || [ "${pref_arr[cluster]}" = "y" ]; then
memvar="${pref_arr[memory]}"
threadvar="${pref_arr[threads]}"
awk '{if ($0 ~ "#SBATCH --mem") {$0="#SBATCH --mem="var}{print $0}}' var="$memvar" scripts/RNA_script_cluster.sh | awk '{if ($0 ~ "#SBATCH --cpus-p") {$0="#SBATCH --cpus-per-task="var}{print $0}}' var="$threadvar" > scripts/RNAscript_hold.tmp && mv scripts/RNAscript_hold.tmp scripts/RNA_script_cluster.sh
awk '{if ($0 ~ "#SBATCH --mem") {$0="#SBATCH --mem="var}{print $0}}' var="$memvar" scripts/stringtie_script_cluster.sh | awk '{if ($0 ~ "#SBATCH --cpus-p") {$0="#SBATCH --cpus-per-task="var}{print $0}}' var="$threadvar" > scripts/STscript_hold.tmp && mv scripts/STscript_hold.tmp scripts/stringtie_script_cluster.sh
fi

# making scripts executable
chmod 755 "${pref_arr[basedir]}"/scripts/RNA_script_cluster.sh
chmod 755 "${pref_arr[basedir]}"/scripts/RNA_script_local.sh
chmod 755 "${pref_arr[basedir]}"/scripts/stringtie_script_cluster.sh
chmod 755 "${pref_arr[basedir]}"/scripts/stringtie_script_local.sh


# Cluster checking and loading of appropriate scripts
case "${pref_arr[cluster]}" in
  y|Y) echo "Loading cluster script"; sbatch "${pref_arr[basedir]}"/scripts/RNA_script_cluster.sh ;;
  n|N) echo "Loading local script"; bash "${pref_arr[basedir]}"/scripts/RNA_script_local.sh ;;
  *) echo  -e '\E['31';'01'm Cluster preferences not set. Exiting.';tput sgr0; exit 1 ;;
esac

# Cluster/stringtie preference check and loading of appropriate scripts
case "${pref_arr[cluster]}:${pref_arr[stringtie]}" in
 y:y|Y:Y|y:Y|Y:y) echo "Loading stringtie cluster script"; sbatch "${pref_arr[basedir]}"/scripts/stringtie_script_cluster.sh ;;
 n:y|N:Y|n:Y|N:y) echo "Loading stringtie local script"; bash "${pref_arr[basedir]}"/scripts/stringtie_script_local.sh ;;
 *) echo  -e '\E['31';'01'm Cluster preferences not set. Exiting.';tput sgr0; exit 1 ;;
esac

