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
 - [minigraph](https://github.com/lh3/minigraph)
 - [cactus](https://github.com/ComparativeGenomicsToolkit/cactus)

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

We used the [Minigraph-Cactus Pangenome Pipeline](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md) with Cactus v2.1.1 to construct the CPC phase 1 pangenome graph. 

First, we need to create an input seqfile `${PREFIX}.seqfile` for Cactus:
```
$ head -n4 ${PREFIX}.seqfile

CHM13v2 /data/reference/chm13v2.0.fa
GRCh38  /data/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
HG00438.1 /data/assembly/HG00438.1.fa
HG00438.2 /data/assembly/HG00438.2.fa
```  
The first columns are the id of reference genomes of assemblies, and the second columns are their absolute directories. The first genome in the seqfile will be the reference genome of the pangenome graph. 

Then we defined the following environment variables:

```
export MYBUCKET=/data/MC_graph/CHM13v2
export MYJOBSTORE=/data/tmp
export PREFIX=${PREFIX}
```


#### 1. Construct the minigraph

We constructed the minigraph in GFA format from the FASTA files in `${PREFIX}.seqfile`.
```
minigraph -cxggs -t 16 \
$(for fasta in $(cut -f2 ${MYBUCKET}/${PREFIX}.seqfile); do echo $fasta; done) \
> ${MYBUCKET}/${PREFIX}.minigraph.gfa
```
Note: The input fasta files cannot have the same sequence names in it. So we preprocessed the GRCh38 reference genome as:
```
sed -i 's/^>chr/^>GRCh38.chr/g' /data/reference/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna
```

#### 2. Preprocess for Minigraph-Cactus

Softmask the input fasta files with dna-brnn
```
mkdir -p ${MYBUCKET}/fasta_pp
cat ${MYBUCKET}/${PREFIX}.seqfile | sed "s\\/data/assembly\\${MYBUCKET}/fasta_pp\\g" > ${MYBUCKET}/${PREFIX}.pp.seqfile
cactus-preprocess ${MYJOBSTORE} ${MYBUCKET}/${PREFIX}.seqfile ${MYBUCKET}/${PREFIX}.pp.seqfile --maskAlpha --minLength 100000 --brnnCores 16  --realTimeLogging --logFile ${MYBUCKET}/log/${PREFIX}.pp.log

```

#### 3. Run the Minigraph-Cactus pipeline
We run the Minigraph-Cactus pipeline with the [cactus-pangenome.sh script](https://github.com/glennhickey/pg-stuff/blob/c87b9236a20272b127ea2fadffc5428c5bf15c0e/cactus-pangenome.sh)
```
 ./cactus-pangenome.sh -j ${MYJOBSTORE} -s ${MYBUCKET}/${PREFIX}.pp.seqfile -m ${MYBUCKET}/${PREFIX}.minigraph.gfa  -o ${MYBUCKET}  -n ${PREFIX}  -r CHM13v2  -g  -F -C -M 100000 -K 10000 -y 2 >> ${MYBUCKET}/log/${PREFIX}.MC_run.log > /dev/null
```	
