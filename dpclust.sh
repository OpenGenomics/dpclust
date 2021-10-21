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
        echo "Usage: $0 [ -s $SAMPLE -u $PURITY -l $PLOIDY -g $GENDER -d $DATDIR"
        echo
	echo " [-s SAMPLE]       - Sample identifier [string]"
        echo " [-u PURITY]       - Tumor purity [float]"
        echo " [-l PLOIDY]       - Tumor ploidy [float]"
        echo " [-g GENDER]       - Patient gender [string]"
	echo " [-d DATDIR]       - Full path and name of directory housing $SAMPLE_dpInput.txt [string]"
        exit
}

SAMPLE=""
PURITY=""
PLOIDY=""
GENDER=""
DATDIR=""

while getopts ":s:u:l:g:d:h" Option
        do
        case $Option in
                s ) SAMPLE="$OPTARG" ;;
                u ) PURITY="$OPTARG" ;;
                l ) PLOIDY="$OPTARG" ;;
                g ) GENDER="$OPTARG" ;;
		d ) DATDIR="$OPTARG" ;;
                h ) usage ;;
                * ) echo "unrecognized argument. use '-h' for usage information."; exit -1 ;;
        esac
done
shift $(($OPTIND - 1))

if [[ "$DATDIR" == "" || "$PURITY" == "" || "$PLOIDY" == "" || "$GENDER" == "" || "$SAMPLE" == "" ]]
        usage
fi

source /home/groups/EllrottLab/activate_conda

if [ ! -e $DIR ];
then
    mkdir -p $DIR ;
fi

WORKDIR=`mktemp -d -p /mnt/scratch/ dpclust.XXX`
chmod -R 775 $WORKDIR
chmod -R g+s $WORKDIR

CWL=./dpclust.cwl
TMPJSON=./dpclust.template.json
JSON=$WORKDIR/dpclust.json

sed -e "s|sample_in|$SAMPLE|g" -e "s|purity_in|$PURITY|g" -e "s|ploidy_in|$PLOIDY|g" -e "s|gender_in|$GENDER|g" $TMPJSON > $JSON

cp -r $SAMPLE $CWL $WORKDIR

CACHE=/mnt/scratch/dpclust_cache
mkdir -p $CACHE

cd $WORKDIR
time cwltool --cache $CACHE --copy-outputs --no-match-user $CWL $JSON

tar czf $SAMPLE_out.tar.gz $SAMPLE/
rsync -a $SAMPLE_out.tar.gz $DATDIR/
rsync -a $CACHE $DATDIR/

cd $DATDIR
rm -rf $WORKDIR
