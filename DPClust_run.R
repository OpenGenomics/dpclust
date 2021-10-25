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
DPFILE <- paste0(SAMPLEID,"_dpInput.txt") ## must be in working directory
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
outdir <- file.path(WORKINGDIR,SAMPLEID)
if (!file.exists(outdir)) { dir.create(outdir) }

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
      outdir=outdir,
      cna_params=list(datpath=outdir,
                      cndatafiles=NULL,
                      co_cluster_cna=FALSE),
      mutphasingfiles=NULL)

q(save="no")
