#!/bin/bash
# dpclust.sh
#SBATCH --partition=exacloud
#SBATCH --account=spellmanlab
#SBATCH --time=10:00:00
#SBATCH --output=dp-%j.out
#SBATCH --error=dp-%j.err
#SBATCH --job-name=dpclust
#SBATCH --gres disk:1024
#SBATCH --mincpus=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G

function usage()
{
        echo "dpclust.sh"    " [a.k.a. *this* script] "
        echo "Author: Kami E. Chiotti "
        echo "Date: 05.17.21"
        echo
        echo "A wrapper for the dpClust algorithm."
        echo "It builds and launches the command to execute the OpenGenomics/dpclust CWL CommandLineTool within a docker container, "
        echo "then returns the output files. "
        echo
        echo "NOTE #1: All input files must be in the same directory as *this* script."
	echo "NOTE #2: The TMPJSON is a JSON template found in the same directory as *this* script. Do not modify this file."
        echo
        echo "Usage: $0 [ -s $SAMPLE -o $OUTDIR"
        echo
	echo " [-s SAMPLE]       - Sample identifier in the format of TCGA-XX-XXXX"
	echo " [-o OUTDIR]       - Full path and name of the directory to which output will be written."
        exit
}

SAMPLE=""
OUTDIR=""

while getopts ":s:o:h" Option
        do
        case $Option in
                s ) SAMPLE="$OPTARG" ;;
		o ) OUTDIR="$OPTARG" ;;
                h ) usage ;;
                * ) echo "unrecognized argument. use '-h' for usage information."; exit -1 ;;
        esac
done
shift $(($OPTIND - 1))

if [[ "$OUTDIR" == "" ]]
then
        usage
fi

source /home/groups/EllrottLab/activate_conda

DRIVERS="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -e $OUTDIR ];
then
    mkdir -p $OUTDIR ;
fi

OUTPUT=$OUTDIR/$RUN_SAMPLE
if [ ! -e $OUTPUT ];
then
    mkdir -p $OUTPUT ;
fi

WORKDIR=`mktemp -d -p /mnt/scratch/ dpclust.XXX`
chmod -R 775 $WORKDIR
chmod -R g+s $WORKDIR

CWL=./dpclust.cwl
TMPJSON=./dpclust.template.json
JSON=$WORKDIR/dpclust.json

sed -e "s|sample_in|$SAMPLE|g" $TMPJSON > $JSON

cp -r ./*_allDirichletProcessInfo.txt $CWL $WORKDIR

cd $WORKDIR
time cwltool --no-match-user $CWL $JSON

rm *_allDirichletProcessInfo.txt
tar czf $SAMPLE_out.tar.gz $SAMPLE*
rsync -a $SAMPLE_out.tar.gz $OUTPUT/

cd $DRIVERS
rm -rf $WORKDIR
