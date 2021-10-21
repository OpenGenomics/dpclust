options(scipen=1)
## ################################################################
## Pipeline to run DPClust on TCGA data
## ################################################################
args <- commandArgs(TRUE)
SAMPLEID <- toString(args[1]) ## sample id
PURITY <- as.numeric(args[2]) ## tumor purity
PLOIDY <- as.numeric(args[3]) ## tumor ploidy
GENDER <- toString(args[4]) ## patient gender
WORKINGDIR <- toString(args[5])  ## full path to working directory
DATDIR <- file.path(WORKINGDIR, SAMPLEID)
DPFILE <- paste0(SAMPLEID,"_dpInput.txt") ## must be in DATDIR
## ################################################################
## author: maxime.tarabichi@ulb.be, maxime.tarabichi@crick.ac.uk
## ################################################################


## ################################################################
## path to summary of TCGA purity/ploidy/gender
#PATHSUMMARY <- "/opt/dpclust/summary.ascatTCGA.penalty70.txt"
## ################################################################


## ################################################################
## package dependencies for this script
library(dpclust3p)
library(DPClust)
## ################################################################

## ################################################################
#setwd(WORKINGDIR)
## ################################################################

## ################################################################
#DPFILE <- paste0(SAMPLEID,"_dpInput.txt")
#pp_summary <- read.table(PATHSUMMARY,sep="\t",header=T)
#purity <- pp_summary[pp_summary$name==SAMPLEID,"purity"]
purity <- PURITY
#ploidy <- pp_summary[pp_summary$name==SAMPLEID,"ploidy"]
ploidy <- PLOIDY
#gender <- ifelse(pp_summary[pp_summary$name==SAMPLEID,"sex"]=="XY","male","female")
gender <- GENDER
## ################################################################

RunDP(analysis_type='nd_dp',
      run_params=make_run_params(no.iters=1250,
                                 no.iters.burn.in=250,
                                 mut.assignment.type=1,
                                 num_muts_sample=NA,
                                 is.male=if(gender=="male") T else F,
                                 min_muts_cluster=5,
                                 min_frac_muts_cluster=0.01,
                                 species="human",
                                 assign_sampled_muts=TRUE,
 #                                supported_chroms=paste0("chr",c(1:22,"X")),
                                 supported_chroms=c(1:22,"X"),
                                 keep_temp_files=TRUE,
                                 generate_cluster_ordering=TRUE),
      sample_params=make_sample_params(datafiles=DPFILE,
                                       cellularity=purity,
                                       is.male=if(gender=="male") T else F,
                                       samplename=SAMPLEID,
                                       subsamples="",
                                       mutphasingfiles=NULL),
      advanced_params=make_advanced_params(seed=12345,
                                           conc_param=0.01,
                                           cluster_conc=5,
                                           max.considered.clusters=20),
      outdir=DATDIR,
      cna_params=list(datpath=DATDIR,
                      cndatafiles=NULL,
                      co_cluster_cna=FALSE),
      mutphasingfiles=NULL)

q(save="no")
## ################################################################
## Load and filter data
#data <- read.table(file=DPFILE,header=T)
#if(length(table(data$nMaj2))>0){data=data}else{data=data[,! colnames(data) %in% "nMaj2"]}
#if(length(table(data$nMin2))>0){data=data}else{data=data[,! colnames(data) %in% "nMin2"]}
#if(length(table(data$frac2))>0){data=data}else{data=data[,! colnames(data) %in% "frac2"]}
#if(substr(data[1,'chr'],1,3)=='chr'){chrom='chr'}else{chrom=NULL}
#dataset <- DPClust:::load.data.inner(list(data=data),
#                                     cellularity=purity,
#                                     Chromosome="chr",
#                                     position="end",
#                                     WT.count="WT.count",
#                                     mut.count="mut.count",
#                                     subclonal.CN="subclonal.CN",
#                                     no.chrs.bearing.mut="no.chrs.bearing.mut",
#                                     mutation.copy.number="mutation.copy.number",
#                                     subclonal.fraction="subclonal.fraction",
#                                     is.male=if(gender=="male") T else F,
#                                     supported_chroms=paste0(chrom,c(1:22,"X")),
#                                     mutation_type="SNV")
#rownames(dataset[["mutCount"]])=rownames(data)[! 1:length(data$start) %in% dataset[["removed_indices"]]]
#rownames(dataset[["WTCount"]])=rownames(data)[! 1:length(data$start) %in% dataset[["removed_indices"]]]
#rownames(dataset[["totalCopyNumber"]])=rownames(data)[! 1:length(data$start) %in% dataset[["removed_indices"]]]
#rownames(dataset[["mutation.copy.number"]])=rownames(data)[! 1:length(data$start) %in% dataset[["removed_indices"]]]
#rownames(dataset[["copyNumberAdjustment"]])=rownames(data)[! 1:length(data$start) %in% dataset[["removed_indices"]]]
#names(dataset[["mutationType"]])=rownames(data)[! 1:length(data$start) %in% dataset[["removed_indices"]]]
### ################################################################
#
### ################################################################
### run DPClust
#clustering <- DPClust:::DirichletProcessClustering(mutCount=dataset$mutCount,
#                                                  WTCount=dataset$WTCount,
#                                                  no.iters=1250,
#                                                  no.iters.burn.in=250,
#                                                  cellularity=purity,
#                                                  totalCopyNumber=dataset$totalCopyNumber,
#                                                  mutation.copy.number=dataset$mutation.copy.number,
#                                                  copyNumberAdjustment=dataset$copyNumberAdjustment,
#                                                  mutationTypes=dataset$mutationType,
#                                                  samplename=paste0("",SAMPLEID,"_"),
#                                                  subsamplesrun=paste0(""),
#                                                  output_folder=WORKINGDIR,
#                                                  conc_param=0.01,
#                                                  cluster_conc=5,
#                                                  mut.assignment.type=1,
#                                                  most.similar.mut=NA,
#                                                  max.considered.clusters=30)
### ################################################################
## Write the final output
## ################################################################

## ################################################################
#q(save="no")
## ################################################################
