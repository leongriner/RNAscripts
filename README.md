# RNAscripts
Scripts for RNAseq data processing.

RNA_wrapper.sh collects user preferences and runs RNA_script_local.sh or RNA_script_cluster.sh. The cluster scripts includes headers for scheduling the job on the New Zealand eScience Infrastructure PAN cluster. The PAN cluster uses SLURM for job scheduling.

RNA_script_local.sh and RNA_script_cluster.sh run:
1. BBDuk - part of BBMap tools. Performs adapter trimming and 3' quality filtering.
2. HISAT2 - alignment against GRCh38 - run with options downstream transcriptiomics workflows.
3. SAMtools - conversion of the resulting SAM file to BAM format.
4. SAMtools - BAM sorting

stringtie_script_local.sh and stringtie_script_cluster.sh run:
1. stringtie - generates a gtf file from sorted BAM files.
2. stringtie - run in `--merge` mode. Generates a non-redundant list of transcripts from all gtf files for downstream abundance estimation
3. stringtie - run in `-eB` mode. Estimates abundance and outputs tables for Ballgown processing. Uses sorted BAM files as input and merged GTF files as reference.

## Using these scripts

Run the scripts by executing either RNA_wrapper.sh optionally followed by stringtie_wrapper.sh, once initial 

RNA and stringtie wrapper scripts initiate child scripts; RNA_script_local.sh, RNA_script_cluster.sh, stringtie_script_local.sh, stringtie_script_cluster.sh. The wrapper scripts generate parameter/preference files, pref.tmp and STpref.tmp. These files are passed to child scripts to execute based on user inputs. These scripts also use basename_list.txt as input for stepping through sample names.

Script | Generates | Requires
--- | --- | ---
RNA_wrapper.sh | pref.tmp | <br/><br/>
RNA_script_local.sh | sorted .bam files | pref.tmp <br/> basename_list.txt <br/> fastq files
RNA_script_cluster.sh | sorted .bam files | pref.tmp <br/> basename_list.txt <br/> fastq files
stringtie_wrapper.sh | STpref.tmp | <br/><br/>
stringtie_script_local.sh | sample .gtf files <br/> Ballgown tables | STpref.tmp <br/> basename_list.txt <br/> sorted .bam files
stringtie_script_cluster.sh | sample .gtf files <br/> Ballgown tables | STpref.tmp <br/> basename_list.txt <br/> sorted .bam files

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

## Input files
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

### fastq files
Placeholder

### HISAT2 reference files
Placeholder

### Homo_sapiens_GRCh38.84.gtf
Placeholder
