# Building a Pan-genome Reference

## Table of Contents

- [**Key resources table**](#Key-resources-table)

  - [Datasets](#Datasets)

  - [Softwares](#Softwares)

- [**Step-by-step method details**](#Step-by-step-method-details)

  - [HiFi reads generation](#hifi-reads-generation)

  - [Genome assembly](#Genome-assembly)

  - [Pangenome graph construction](#Pangenome-graph-construction)

## Key resources table

### Datasets

*.subreads.bam  | in this study



### Softwares

 - [hifiasm]()
 - [minimap2]()


## Step-by-step method details

### HiFi reads generation

Totally 68 samples were sequenced on 2–5 single 8M SMRT Cells. The obtained subreads are converted into HiFi reads by the ccs-v6.3.0 in PacBio tools with `--hifi-kinetics` `--min-passes 3` `--min-length 50`.

```shell

```

Convert `*.ccs.bam` to `*.ccs.fastq.gz`

```shell

```

Merge HiFi reads from multiple SMRT Cells.

```shell

```
	
### Genome assembly


### Pangenome graph construction
	
