#$!/user/bin/bash

SAMPLEID=TCGA-4G-AA30
OUTDIR=/home/groups/Spellmandata/chiotti/gdan_pipelines/heterogeneity/tools/dpclust

sbatch --get-user-env dpclust.sh -s $SAMPLEID -o $OUTDIR

