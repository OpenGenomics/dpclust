#$!/user/bin/bash
METAFILE=/home/groups/Spellmandata/chiotti/gdan_pipelines/timing/dlbcl/metadata/dlbcl.meta.manifest
DATDIR=/home/groups/Spellmandata/chiotti/gdan_pipelines/heterogeneity/tools/dpclust	#location of $SAMPLEID_dpInput.txt

for LINE in `cat $METAFILE`
do
SAMPLEID=`echo ${LINE:0:30}`
PURITY=`grep $SAMPLEID $METAFILE | awk '{print $4}'`
PLOIDY=`grep $SAMPLEID $METAFILE | awk '{print $3}'`
GENDER=`grep $SAMPLEID $METAFILE | awk '{print $5}'`

sbatch --get-user-env dpclust.sh -s $SAMPLEID -u $PURITY -l $PLOIDY -g $GENDER -d $DATDIR
done
