# RNAscripts
Scripts for RNAseq data processing

## Using these scripts

RNA and stringtie wrapper scripts initiate child scripts; RNA_script_local.sh, RNA_script_cluster.sh, stringtie_script_local.sh, stringtie_script_cluster.sh. The wrapper scripts generate parameter/preference files, pref.tmp and STpref.tmp. These files are passed to child scripts to execute based on user inputs. These scripts also use basename_list.txt as input for stepping through sample names.

Script | Generates | Requires
--- | --- | ---
RNA_wrapper.sh | pref.tmp | <br/><br/>
RNA_script_local.sh |  | pref.tmp <br/> basename_list.txt
RNA_script_cluster.sh |  | pref.tmp <br/> basename_list.txt
stringtie_wrapper.sh | STpref.tmp | <br/><br/>
stringtie_script_local.sh |  | STpref.tmp <br/> basename_list.txt
stringtie_script_cluster.sh |  | STpref.tmp <br/> basename_list.txt

The scripts assume the following directory structure. GRCh38 gtf files are used as a reference by Stringtie.

* RNAseq/  
  * reads
    * fastq files
  * references
    * HISAT2 genome
      * HISAT2 genome files
    * grch38_gtf/
      * Homo_sampiens.GRCh38.84.gtf
  * working
    * basename_list.txt

### pref.tmp and STpref.tmp

These files are used to generate associative arrays by child scripts. The contents of the array determines how a script runs. You may run child scripts directly if pref.tmp or STpref.tmp is already present. You can manually generate the these files. Example file contents for both pref.tmp and STpref.tmp:

`[basedir]=/home/lgri018/RNAseq`<br/>
`[basename_check]=y`<br/>
`[threads]=5`<br/>
`[memory]=5`<br/>
`[paired]=y`<br/>
`[cluster]=y`<br/>

Set parameters based on your preferences.

### basename_list.txt

Ensure that the 'working' directory also contains the sample basename list (basename_list.txt).
This file must contain a list of sample basenames (e.g. the basename for a pair of fastq files NGS_data_123_1.fastq and NGS_data_123_2.fastq is NGS_data_123).
Each basename in the file must be on a separate line with no trailing whitespace. The file must end with the last entry, not with a new line. E.g. <br/>
`<start of file>` NGS_data_123`<line break>`<br/>
NGS_data_456`<line break>`<br/>
NGS_data_789`<end of file>`
