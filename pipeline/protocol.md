# Building a Pan-genome Reference

## Table of Contents

- **Key resources table**
  - [Data](#data)
  - [Softwares](#softwares)

- **Step-by-step method details**
  - [HiFi reads generation](#hifi-reads-generation)
  - [Genome assembly](#genome-assembly)
  - [Pangenome graph construction](#pangenome-graph-construction)

## Key resources table

### Data

 - Subreads reads (`.subreads.bam`) or HiFi reads (`.ccs.bam`)
   > If the input is HIFI reads, the *HiFi reads generation* step can be skipped.

 - Hi-C reads ( optional )
   > Hi-C data is recommended for obtaining higher haplotype-resolved assemblies.

### Softwares

 - [ccs](https://github.com/PacificBiosciences/ccs)
 - [samtools](https://github.com/samtools/samtools)
 - [hifiasm](https://github.com/chhylp123/hifiasm)
 - [inspector](https://github.com/ChongLab/Inspector)


## Step-by-step method details

### HiFi reads generation

Totally 68 samples were sequenced on 2–5 single 8M SMRT Cells. The obtained subreads are converted into HiFi reads by the `ccs-v6.3.0` in PacBio tools with `--hifi-kinetics` `--min-passes 3` `--min-length 50`.

```shell
ccs --hifi-kinetics ${cell_id} output/${cell_id}.ccs.bam -j 64 --min-passes 3 --min-length 50 --log-file log/${cell_id}.ccs.log
```

Convert `*.ccs.bam` to `*.ccs.fastq.gz`

```shell
samtools fastq -n -@ 16 output/${cell_id}.ccs.bam |bgzip -@ 16 -c > fastq/${cell_id}.ccs.fastq.gz
```

Merge HiFi reads from multiple SMRT Cells.

```shell
zcat fastq/${cell_1}.ccs.fastq.gz [fastq/${cell_2}.ccs.fastq.gz ...] |bgzip -@ 32 -c > ${sample_id}.ccs.fastq.gz
```
	
### Genome assembly

As for 11 samples with Hi-C data, we ran `hifiasm` with following command:

```
hifiasm -o $sample.asm -h1 ${sample_id}.r1.fastq.gz -h2 ${sample_id}.r2.fastq.gz -t 96 ${sample_id}.ccs.fastq.gz. 
```

As for the remaining 57 samples, we ran `hifiasm` with the command: 

```
hifiasm -o ${sample_id}.asm -t 96 ${sample_id}.ccs.fastq.gz. 
```

### Assembly polish

First, We used `inspector v1.260` to evaluate the assembling errors.

```
inspector.py -c ${sample_id}.asm.fa -r ${sample_id}.ccs.fastq.gz -o ${sample_id}.asm/ --datatype hifi -t 64
```

Then, we performed assembly polish based on the evaluation results.

```
inspector-correct.py -i ${sample_id}.asm/ --datatype pacbio-hifi -o ${sample_id}.asm.corrected/ --skip_structural -t 64
```


### Pangenome graph construction
	
