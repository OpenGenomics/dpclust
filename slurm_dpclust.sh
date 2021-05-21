#$!/user/bin/bash

SAMPLEID=TCGA-4G-AAZO
OUTDIR=/home/groups/Spellmandata/chiotti/gdan_pipelines/heterogeneity/tools/dpclust
DPINPUT=$OUTDIR/$SAMPLEID\_dpInput.txt

sbatch --get-user-env dpclust.sh -s $SAMPLEID -d $DPINPUT -o $OUTDIR

