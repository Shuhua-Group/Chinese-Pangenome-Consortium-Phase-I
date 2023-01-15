#!/bin/bash
module load anaconda3
module load samtools
module load minimap2
module load htslib

snakemake -s ${SNAKEFILE} -j ${JOB_COUNT} --nt --ri -k \
    --jobname "{rulename}.{jobid}" \
    -w 60 "$@"

