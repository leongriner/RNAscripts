#!/bin/bin

#Prevent expansion of * when no matching files present.
shopt -s nullglob

#Introduction and usage explanation
echo -e '\E['34';'01'm-------------------Stringtie Script Wrapper-------------------\n'
echo "This script is designed to collect working parameters/preferences for executing a child script. As input, this script requires sorted BAM files such as those produced using the RNA_wrapper.sh file and its child scripts. The child scripts involved in this workflow (stringtie_script_local.sh or stringtie_script_cluster.sh) will generate a GTF file for each sorted BAM file, merge these GTF files into a non-redundant list of transcripts then use this as a reference for generating abundance tables for downstream Ballgown analysis."
echo ""
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
read -n 1 -p "Would you like to begin setting preferences and parameters? [y/n]:" STpref_check
case $STpref_check in
  y|Y) echo "";;
  n|N) echo ""; echo -e '\E['31';'01'm You have selected no to setting preferences. Exiting.';tput sgr0; exit 1 ;;
  *) echo ""; echo -e '\E['31';'01'm Invalid input. Exiting.';tput sgr0; exit 1 ;;
esac

#Preferences header
echo -e '\E['34';'01'm\n-------------------Stringtie Script Preferences-------------------\n'
echo "Set preferences for this script."
tput sgr0

#Base Directory check - can be replaced with a script that detects folder structure,
echo "Is the current directory the base directory?"
read -n 1 -p "I.e. Does the current dirctory contain the working, reads and reference directories? [y/n] " STbasedir_check
case $STbasedir_check in
  y|Y) echo "[basedir]="$(pwd) > STpref.tmp ;;
  n|N) echo ""; read -p "Enter the absolute path (no trailing "/"). E.g. /path/to/base/dir " STbasedir_custom ; echo [basedir]="$STbasedir_custom" > STpref.tmp ;;
  *) echo ""; echo -e '\E['31';'01'm Invalid input. Exiting.';tput sgr0; exit 1 ;;
esac

#Base Name check - can be replaced with a script that detects presence of file.
echo ""
read -n 1 -p "Has a sample basename list file (basename_list.txt) been created in the current directory? [y/n]: " STbasename_check
case $STbasename_check in
  y|Y) echo "[basename_check]=""$STbasename_check" >> STpref.tmp ;;
  *) echo ""; echo -e '\E['31';'01'm A sample basename list must be created before proceeding. Exiting.';tput sgr0; exit 1 ;;
esac

#Threads check.
echo ""
read -p "Enter the number of processors/threads would you like to use [#] - press [ENTER] to input: " STthreads
case $STthreads in
  [0-999]*) echo "[threads]=""$STthreads" >> STpref.tmp ;;
  *) echo ""; echo -e '\E['31';'01'm Invalid input. Exiting.';tput sgr0; exit 1 ;;
esac

#Mem check.
read -p "Enter the amount of memory (in GB) that would you like to use [#]. Do not add GB suffix. Only use whole numbers - press [ENTER] to input: " STmemory
case $STmemory in
  [0-999]*) echo "[memory]=""$STmemory" >> STpref.tmp ;;
  *) echo -e '\E['31';'01'm Invalid input. Exiting.';tput sgr0; exit 1 ;;
esac

#Checks to see whether this is running on a local machine or the cluster. Unsure if this check is possible to script.
echo ""
read -n 1 -p "Are you running this script on the PAN cluster? [y/n]: " STcluster_check
case $STcluster_check in
  y|Y|n|N) echo "[cluster]=""$STcluster_check" >> STpref.tmp ;;
  *) echo ""; echo -e '\E['31';'01'm Invalid input. Exiting';tput sgr0; exit 1 ;;
esac
echo ""

#Execution gate
echo -e '\E['34';'01'm\n\n-------------------Stringtie Analysis Script-------------------\n'
echo "Preferences have been set. Please a) programs have been set to the path variable. b) child scripts have correct paths set to programs."
tput sgr0
read -n 1 -p "Would you like to begin executing the analysis script? [y/n]:" STrun_check
case $STrun_check in
  y|Y) echo "";;
  n|N) echo ""; echo -e '\E['31';'01'm You have selected "No" to running the analysis script. Exiting.';tput sgr0; exit 1 ;;
  *) echo ""; echo -e '\E['31';'01'm Invalid input. Exiting.';tput sgr0; exit 1 ;;
esac

#---DIFFERENTIAL SCRIPT EXECUTION-----

#Parameter/preference loading
declare -a SThold_array #declare an array to pass preferences into - needs to be an indexed array as readarray does not work with associative arrays.
readarray -t SThold_array < STpref.tmp #pass file contents to indexed array
printf -v STreadstr '%s ' "${SThold_array[@]}" #read contents of hold_array as a space-separated string
sandwich="("$STreadstr")" #sandwiching readstr between (). Cluster bash interprets brackes differently to local bash when () used in declare so this is set via intermediate variable.
case $STcluster_check in
  y|Y) declare -A pref_arr="$STsandwich" ;;#pass string to declared associative array. Eval seems to work weird on te cluster but declare seems to work ok without eval.
  n|N) eval "declare -A STpref_arr="$STsandwich"" #pass string to declared associative array. Needs to run through eval to be interepreted as a bash command.
esac

# Declaring an associative array allows for easy referecing of parameters vs indexed array (does not need to
# invoke pattern matching through AWK, SED or GREP, does not need to know the index number of the parameter,
# intuitive to script and easy to add/remove parameters). Passing to the assoc. array is ugly but worth it.

#Preference passing to cluster scripts via awk (parent/child variable passing doesn't work on the cluster)
if [ "${STpref_arr[cluster]}" = "y" ] || [ "${STpref_arr[cluster]}" = "y" ]; then
STmemvar="${STpref_arr[memory]}"
STthreadvar="${STpref_arr[threads]}"
awk '{if ($0 ~ "#SBATCH --mem") {$0="#SBATCH --mem="var}{print $0}}' var="$STmemvar" scripts/stringtie_script_cluster.sh | awk '{if ($0 ~ "#SBATCH --cpus-p") {$0="#SBATCH --cpus-per-task="var}{print $0}}' var="$STthreadvar" > scripts/STscript_hold.tmp && mv scripts/STscript_hold.tmp scripts/stringtie_script_cluster.sh
fi

# making scripts executable
chmod 755 "${STpref_arr[basedir]}"/scripts/stringtie_script_cluster.sh
chmod 755 "${STpref_arr[basedir]}"/scripts/stringtie_script_local.sh

# Cluster/stringtie preference check and loading of appropriate scripts
case "${STpref_arr[cluster]}" in
  y|Y) echo "Loading stringtie cluster script"; sbatch "${STpref_arr[basedir]}"/scripts/stringtie_script_cluster.sh ;;
  n|N) echo "Loading stringtie local script"; bash "${STpref_arr[basedir]}"/scripts/stringtie_script_local.sh ;;
  *) echo  -e '\E['31';'01'm Cluster preferences not set. Exiting.';tput sgr0; exit 1 ;;
esac
