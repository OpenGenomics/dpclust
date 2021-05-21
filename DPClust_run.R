## ################################################################
## Pipeline to run DPClust on TCGA data
## ################################################################
args <- commandArgs(TRUE)
SAMPLEID <- toString(args[1]) ## tcga sample id with format: "TCGA-4G-AAZO"
DPFILE <- toString(args[2]) ## full path to $SAMPLEID_dpInput.txt
WORKINGDIR <- toString(args[3]) ## working directory (all outputs go here and dpinput should be here as well)
## ################################################################
## author: maxime.tarabichi@ulb.be, maxime.tarabichi@crick.ac.uk
## ################################################################


## ################################################################
## path to summary of TCGA purity/ploidy/gender
PATHSUMMARY <- "/opt/dpclust/summary.ascatTCGA.penalty70.txt"
## ################################################################


## ################################################################
## package dependencies for this script
library(dpclust3p)
library(DPClust)
## ################################################################

## ################################################################
setwd(WORKINGDIR)
## ################################################################

## ################################################################
#DPFILE <- paste0(SAMPLEID,"_dpInput.txt")
pp_summary <- read.table(PATHSUMMARY,sep="\t",header=T)
purity <- pp_summary[pp_summary$name==SAMPLEID,"purity"]
ploidy <- pp_summary[pp_summary$name==SAMPLEID,"ploidy"]
gender <- ifelse(pp_summary[pp_summary$name==SAMPLEID,"sex"]=="XY","male","female")
## ################################################################

## ################################################################
## Load and filter data
data <- read.table(file=DPFILE,header=T)
if(length(table(data$nMaj2))>0){data=data}else{data=data[,! colnames(data) %in% "nMaj2"]}
if(length(table(data$nMin2))>0){data=data}else{data=data[,! colnames(data) %in% "nMin2"]}
if(length(table(data$frac2))>0){data=data}else{data=data[,! colnames(data) %in% "frac2"]}
if(substr(data[1,'chr'],1,3)=='chr'){chrom='chr'}else{chrom=NULL}
dataset <- DPClust:::load.data.inner(list(data=data),
                                     cellularity=purity,
                                     Chromosome="chr",
                                     position="end",
                                     WT.count="WT.count",
                                     mut.count="mut.count",
                                     subclonal.CN="subclonal.CN",
                                     no.chrs.bearing.mut="no.chrs.bearing.mut",
                                     mutation.copy.number="mutation.copy.number",
                                     subclonal.fraction="subclonal.fraction",
                                     is.male=if(gender=="male") T else F,
                                     supported_chroms=paste0(chrom,c(1:22,"X")),
                                     mutation_type="SNV")
## ################################################################

## ################################################################
## run DPClust
clustering <- DPClust:::DirichletProcessClustering(mutCount=dataset$mutCount,
                                                  WTCount=dataset$WTCount,
                                                  no.iters=1250,
                                                  no.iters.burn.in=250,
                                                  cellularity=purity,
                                                  totalCopyNumber=dataset$totalCopyNumber,
                                                  mutation.copy.number=dataset$mutation.copy.number,
                                                  copyNumberAdjustment=dataset$copyNumberAdjustment,
                                                  mutationTypes=dataset$mutationType,
                                                  samplename=paste0("",SAMPLEID,"_"),
                                                  subsamplesrun=paste0(""),
                                                  output_folder=WORKINGDIR,
                                                  conc_param=0.01,
                                                  cluster_conc=5,
                                                  mut.assignment.type=1,
                                                  most.similar.mut=NA,
                                                  max.considered.clusters=30)
## ################################################################

## ################################################################
q(save="no")
## ################################################################
