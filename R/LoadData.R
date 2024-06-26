#
# Functions to load DPClust input files
#

#' This function loads a series of data tables or VCFs into a dataset object
#' which is in essense a list of tables, one for each type of information
#' 
#' @param list_of_data_files A list of data file names to be read in
#' @param cellularity A vector containing the cellularity estimates for each sample
#' @param Chromosome String that contains the name of the column with chromosome denomination for each mutation
#' @param position String that contains the name of the column with position denomination for each mutation
#' @param WT.count String the colname of the column in the data files that contains the number of wild type reads
#' @param mut.count String, the colname of the column in the data files that contains the number of mutant reads
#' @param subclonal.CN String, the name of the total copynumber column
#' @param no.chrs.bearing.mut String, the column that contains the number of chromosomes not bearing any mutations
#' @param mutation.copy.number String, colname with mutation copy number estimates
#' @param subclonal.fraction String, colname of the column that contains the subclonal fraction (or CCF) estimate for each mutation
#' @param phase String, colname of the copy number to mutation phasing info column
#' @param is.male Optional boolean that represents the sex, set to TRUE if male, FALSE if female. This information is used to decide whether to include X chromosome mutations
#' @param is.vcf Optional boolean parameter whether the files to be read in are in VCF format
#' @param ref.genome.version Optional string that represents the reference genome, required when reading in VCF files
#' @author sd11
#' @return A list of tables, one for each type of information
load.data <- function(list_of_data_files, cellularity, Chromosome, start, position, WT.count, mut.count, subclonal.CN, no.chrs.bearing.mut, mutation.copy.number, subclonal.fraction, phase=NULL, is.male=T, is.vcf=F, ref.genome.version="hg19", supported_chroms=c(1:22)) {
  data=list()
  
  if (!is.vcf) {
    for(s in 1:length(list_of_data_files)) {
      rwnms=read.table(list_of_data_files,header=T,row.names=NULL)[,1]
      if(any(duplicated(rwnms))){
        rwnms=make.names(rwnms,unique=T)
        data[[s]] = read.table(list_of_data_files[s], header=T, row.names=NULL, stringsAsFactors=F, sep="\t")[,-1]
        rownames(data[[s]])=rwnms
      }else{
        data[[s]] = read.table(list_of_data_files[s], header=T, row.names=NULL, stringsAsFactors=F, sep="\t")[,-1]
        rownames(data[[s]])=rwnms
      }
    }
  } else {
    print("VCF files are no longer supported")
    q(save="no", status=1)
    #for(s in 1:length(list_of_data_files)) {
    #  v = readVcf(list_of_data_files[s], genome=ref.genome.version)
    #  # Transform the VCF into the format that the original load.data function understands
    #  data[[s]] = data.frame(chr=as.vector(seqnames(v)), start=as.vector(start(v))-1, end=as.vector(end(v)),
    #                         WT.count=as.vector(info(v)$WC), mut.count=as.vector(info(v)$MC), subclonal.CN=as.vector(info(v))$TSC,
    #                         nMaj1=as.vector(info(v)$NMA1), nMin1=as.vector(info(v)$NMI1), frac1=as.vector(info(v)$FR1),
    #                         nMaj2=as.vector(info(v)$NMA2), nMin2=as.vector(info(v)$NMI2), frac2=as.vector(info(v)$FR2),
    #                         phase=as.vector(info(v)$PHS), mutation.copy.number=as.vector(info(v)$MCN), subclonal.fraction=as.vector(info(v)$CCF),
    #                         no.chrs.bearing.mut=as.vector(info(v)$NCBM)) # TODO: add in phase
    #}
  }

  # Ofload combining of the tables per sample into a series of tables per data type
  return(load.data.inner(data, cellularity, Chromosome, start, position, WT.count, mut.count, subclonal.CN, no.chrs.bearing.mut, mutation.copy.number, subclonal.fraction, phase, is.male, supported_chroms))
}
  
#' This inner function takes a list of loaded data tables and transforms them into
#' a dataset, which is a list that contains a table per data type
#' @noRd
load.data.inner = function(list_of_tables, cellularity, Chromosome, start, position, WT.count, mut.count, subclonal.CN, no.chrs.bearing.mut, mutation.copy.number, subclonal.fraction, phase, is.male, supported_chroms, mutation_type="SNV") {
  no.subsamples = length(list_of_tables)
  no.muts = nrow(list_of_tables[[1]])
  rwnms = rownames(list_of_tables[[1]])
 
  # One matrix for each data type and propagate it
  chromosome = matrix(0,no.muts,no.subsamples)
  mut.start = matrix(0,no.muts,no.subsamples)
  mut.position = matrix(0,no.muts,no.subsamples)
  WTCount = matrix(0,no.muts,no.subsamples)
  mutCount = matrix(0,no.muts,no.subsamples)
  totalCopyNumber = matrix(0,no.muts,no.subsamples)
  copyNumberAdjustment = matrix(0,no.muts,no.subsamples)
  non.deleted.muts = vector(mode="logical",length=nrow(list_of_tables[[1]]))
  mutationCopyNumber = matrix(NA,no.muts,no.subsamples)
  subclonalFraction = matrix(NA,no.muts,no.subsamples)
  phasing = matrix("unphased",no.muts,no.subsamples)
  for(s in 1:length(list_of_tables)){
    prechr=matrix(as.numeric(gsub(list_of_tables[[s]][,Chromosome], pattern="X", replacement=23)))
    chromosome[,s] = gsub(prechr,pattern=23,replacement="X")
    mut.start[,s] = as.numeric(list_of_tables[[s]][,start])
    mut.position[,s] = as.numeric(list_of_tables[[s]][,position])
    WTCount[,s] = as.numeric(list_of_tables[[s]][,WT.count])
    mutCount[,s] = as.numeric(list_of_tables[[s]][,mut.count])
    totalCopyNumber[,s] = as.numeric(list_of_tables[[s]][,subclonal.CN])
    copyNumberAdjustment[,s] = as.numeric(list_of_tables[[s]][,no.chrs.bearing.mut])
    non.deleted.muts[list_of_tables[[s]][,no.chrs.bearing.mut]>0]=T
    mutationCopyNumber[,s] = as.numeric(list_of_tables[[s]][,mutation.copy.number])
    subclonalFraction[,s] = as.numeric(list_of_tables[[s]][,subclonal.fraction])
    # This is disabled for now, as its not used by current methods
    # if (!is.null(phase)) {
    #   phasing[,s] = list_of_tables[[s]][,phase]
    # }
  }
  
  # Calculate the kappa, in essense the correction component for the allele frequency of each mutation
  kappa = matrix(1,no.muts,no.subsamples)
  for(i in 1:length(list_of_tables)){
    #multiply by no.chrs.bearing.mut, so that kappa is the fraction of reads required for fully clonal mutations, rather than mutation at MCN = 1
    kappa[,i] = DPClust:::mutationCopyNumberToMutationBurden(1,list_of_tables[[i]][,subclonal.CN],cellularity[i]) * list_of_tables[[i]][,no.chrs.bearing.mut]
  }

  # Remove those mutations that have missing values
  not.there.wt = apply(WTCount, 1, function(x) { sum(is.na(x))>0 })
  not.there.mut = apply(mutCount, 1, function(x) { sum(is.na(x))>0 })
  not.there.cn = apply(totalCopyNumber, 1, function(x) { sum(is.na(x))>0 })
  not.there.cna = apply(copyNumberAdjustment, 1, function(x) { sum(is.na(x))>0 })
  not.there.kappa = apply(kappa, 1, function(x) { sum(is.na(x))>0 })
  # Remove those mutations that have no coverage. These cause for trouble lateron.
  not.coverage = apply(WTCount+mutCount, 1, function(x) { any(x==0 | is.na(x)) })
  not.cna = apply(copyNumberAdjustment, 1, function(x) { any(x==0 | is.na(x)) })
  not.on.supported.chrom = apply(chromosome, 1, function(x) { ! any(x %in% as.character(supported_chroms)) })

  print(paste("Removed", sum(not.there.wt),"with missing WTCount", sep=" "))
  print(paste("Removed", sum(not.there.mut),"with missing mutCount", sep=" "))
  print(paste("Removed", sum(not.there.cn | not.cna),"with missing totalCopyNumber", sep=" "))
  print(paste("Removed", sum(not.there.cna),"with missing copyNumberAdjustment", sep=" "))
  print(paste("Removed", sum(not.there.kappa),"with missing kappa", sep=" "))
  print(paste("Removed", sum(not.coverage),"with no coverage", sep=" "))
  print(paste("Removed", sum(not.on.supported.chrom), "on not supported genomic regions", sep=" "))

  select = !(not.there.wt | not.there.mut | not.there.cn | not.there.cna | not.there.kappa | not.coverage | not.cna | not.on.supported.chrom)
  
  # Keep indices of removed mutations to 'spike in' lateron when constructing the output
  removed_indices = which(!select)
  chromosome.not.filtered = chromosome
  mut.position.not.filtered = mut.position

  # Remove mutations that have been flagged for various reasons
  chromosome = as.matrix(chromosome[select,])
  mut.start = as.matrix(mut.start[select,])
  mut.position = as.matrix(mut.position[select,])
  WTCount = as.matrix(WTCount[select,])
  mutCount = as.matrix(mutCount[select,])
  totalCopyNumber = as.matrix(totalCopyNumber[select,])
  copyNumberAdjustment = as.matrix(copyNumberAdjustment[select,])
  non.deleted.muts = non.deleted.muts[select]
  kappa = as.matrix(kappa[select,])
  mutationCopyNumber = as.matrix(mutationCopyNumber[select,])
  subclonalFraction = as.matrix(subclonalFraction[select,])
  phasing = as.data.frame(phasing[select,])
  mutationType = factor(rep(mutation_type, nrow(mutCount)), levels=c("SNV", "CNA", "indel"))

  rwnms = rwnms[select]
  rownames(chromosome) = rwnms

  print("")
  print(paste("Removed",no.muts-nrow(WTCount), "mutations with missing data"))
  print("")
  
  # These are required when this dataset is subsampled
  selection = NA
  full_data = NA
  most.similar.mut = NA
  
  return(list(chromosome=chromosome, start=mut.start, position=mut.position, WTCount=WTCount, mutCount=mutCount, 
              totalCopyNumber=totalCopyNumber, copyNumberAdjustment=copyNumberAdjustment, 
              non.deleted.muts=non.deleted.muts, kappa=kappa, mutation.copy.number=mutationCopyNumber, 
              subclonal.fraction=subclonalFraction, removed_indices=removed_indices,
              chromosome.not.filtered=chromosome.not.filtered, mut.position.not.filtered=mut.position.not.filtered,
	            sampling.selection=selection, full.data=full_data, most.similar.mut=most.similar.mut, 
              mutationType=mutationType, conflict.array=NA, cellularity=cellularity, phase=phasing,
              mutphasing=NULL))
}

#' Load the CN input for a single sample (for now)
#' This expects a cnDP input file
load.cn.data = function(infile) {
  cndata = read.table(infile, header=T, stringsAsFactors=F)
  return(cndata)
}

#' Load the indel input
#' This expects a DP indel input file
load.indel.data = function(infiles) {
  indeldata = lapply(infiles, function(infile) read.table(infile, header=T, stringsAsFactors=F))
  return(indeldata)
}

#' Function that adds copy number as a series of SNVs into a data set
add.in.cn.as.snv.cluster = function(dataset, cndata, cellularity, add.conflicts=T, conflicting.events.only=F, num.clonal.events.to.add=0, min.cna.size=10) {
  # If clonal events are to be added, make a selection. For now this just takes the largest event
  if (num.clonal.events.to.add > 0) {
    # Save the largest clonal event to add to the CNAs
    allowed.cn = c("cHD", "cLOH", "cAmp", "cGain", "cLoss")
    cndata_clonal = cndata[cndata$CNA %in% allowed.cn,]
    
    if (num.clonal.events.to.add < nrow(cndata_clonal)) {
      cn_sorted = sort((cndata_clonal[,4]-cndata_clonal[,3]), index.return=T,  decreasing=T)
      cn_selected = cn_sorted$ix[1:num.clonal.events.to.add]
    } else {
      cn_selected = 1:nrow(cndata_clonal)
    }
    cndata_clonal = cndata_clonal[cn_selected,, drop=F]
  }
  
  # The subclonal events can be used for clustering
  allowed.cn = c("sHD", "sLOH", "sAmp", "sGain", "sLoss")
  cndata = cndata[cndata$CNA %in% allowed.cn,]
  
  # Append the clonal events
  if (num.clonal.events.to.add) {
    cndata = rbind(cndata, cndata_clonal)
  }
  
  # Remove duplicates
  dups = cndata[cndata$CNA=="sLOH",]$startpos # These are added in twice, remove the sLoss marking
  cndata = cndata[!(cndata$startpos %in% dups & cndata$CNA=="sLOH"),]
  
  # No more CNAs left, return original dataset
  if (nrow(cndata)==0) {
    return(dataset)
  }
  num.samples = ncol(dataset$mutCount)
  
  # Take average depth as template for these CNAs disguised as fictional SNVs - but if that is lower than 90x we cannot insert a subclone at 2% CCF
  N = round(mean(dataset$WTCount+dataset$mutCount))
  if (N < 90) {
    N = 90
  }

  # Calculate the average mutation rate per 10kb 300.000
  hum_genome_size = 323483
  mut_rate_10kb = nrow(dataset$mutCount)/hum_genome_size
  
  # For each copy number event simulate a mutation cluster
  for (i in 1:nrow(cndata)) {
    #print(paste("CNA",i))
    #print(cndata[i,])
    # Confidence is used to downweigh the depth of this CNA to mimick uncertainty. 
    # If its a clonal event then there is no SD defined, so set confidence to 1, which means no downscaling is performed
    conf = ifelse(!is.na(cndata[i,]$SDfrac_A), cndata[i,]$SDfrac_A*100+1, 1)
    
    # Calculate the size of this segment in kb and the number of muts it needs to be represented by
    CNA_size = cndata[i,]$endpos/10000 - cndata[i,]$startpos/10000
    CNA_num_muts = ceiling(CNA_size * mut_rate_10kb) / conf
    
    # Now create the number of mutations required, but only if the copy number segment is of large enough size
    if (CNA_num_muts > 0 & CNA_size > min.cna.size) {
      dataset = create_pseudo_snv(cndata[i,], CNA_num_muts, N, conf, cellularity, dataset, conflicting.events.only)
    } else {
      # Add the CNA as a single SNV so it is co-clustered without adding much weight
      dataset = create_pseudo_snv(cndata[i,], 1, N, conf, cellularity, dataset, conflicting.events.only)
    }
  }
  
  if (add.conflicts) {
    dataset = add.snv.cna.conflicts(dataset, cndata)
  }
  
  return(dataset)
}

#' Function that adds copy number as a single SNV into a data set
add.in.cn.as.single.snv = function(dataset, cndata, cellularity, add.conflicts=T) {
  
  # The subclonal events can be used for clustering
  allowed.cn = c("sHD", "sLOH", "sAmp", "sGain", "sLoss")
  cndata = cndata[cndata$CNA %in% allowed.cn,]

  # Remove duplicates
  dups = cndata[cndata$CNA=="sLOH",]$startpos # These are added in twice, remove the sLoss marking
  cndata = cndata[cndata$startpos %in% dups & cndata$CNA=="sLoss",]

  num.samples = ncol(dataset$mutCount)
  
  # Take average depth as template for these CNAs disguised as fictional SNVs, but make the CNA weigh as much as 100 SNVs, to be downscaled below due to uncertainty
  N = round(mean(dataset$WTCount+dataset$mutCount) * 3)
  for (i in 1:nrow(cndata)) {
    # Fetch fraction of cells and confidence
    CNA_frac = cndata[i,]$frac1_A
    # Confidence is used to downweigh the depth of this CNA to mimick uncertainty
    conf = cndata[i,]$SDfrac_A*100+1 
   
    # Create pseudo SNV carried by 1 copy in 1+1 area, and being subclonal proportionate to the CNA
    tumourCN = 2
    ncbm = 1
    reads.per.clonal.copy = (cellularity*N/conf) / (cellularity*tumourCN + (1-cellularity)*2)
    mc = round(reads.per.clonal.copy*CNA_frac)
    wt = round(N/conf) - mc
    mcn = DPClust:::mutationBurdenToMutationCopyNumber(mc/(mc+wt), tumourCN, cellularity, 2)

    # Save the pseudo SNV in the dataset
    dataset$chromosome = rbind(dataset$chromosome, rep(cndata[i,]$chr, num.samples))
    dataset$position = rbind(dataset$position, rep(cndata[i,]$startpos, num.samples))
    dataset$mutCount = rbind(dataset$mutCount, rep(mc, num.samples))
    dataset$WTCount = rbind(dataset$WTCount, rep(wt, num.samples))
    dataset$totalCopyNumber = rbind(dataset$totalCopyNumber, rep(tumourCN, num.samples))
    dataset$copyNumberAdjustment = rbind(dataset$copyNumberAdjustment, rep(ncbm, num.samples))
    dataset$mutation.copy.number = rbind(dataset$mutation.copy.number, rep(mcn, num.samples))
    dataset$kappa = rbind(dataset$kappa, mutationCopyNumberToMutationBurden(1, tumourCN, cellularity))
    
    index = nrow(dataset$mutCount)
    #print(paste("NEW CNA CCF/MCN", cndata[i,]$frac1_A, dataset$mutation.copy.number[index,1], mcn, dataset$mutCount[index,1], dataset$WTCount[index, 1], conf))
    # TODO: Setting same CNA CCF across samples does not work for multiple samples!
    dataset$subclonal.fraction = rbind(dataset$subclonal.fraction, rep(dataset$mutation.copy.number[index,1], num.samples))
    dataset$phase = rbind(dataset$phase, rep("unphased", num.samples))
    dataset$non.deleted.muts = c(dataset$non.deleted.muts, T)
  }
  # Setting mutation type of all CNAs and making each CNA most similar to itself
  dataset$mutationType = factor(c(as.character(dataset$mutationType), rep("CNA", nrow(cndata))), levels=c("SNV", "CNA", "indel"))
  dataset$most.similar.mut = c(dataset$most.similar.mut, which(dataset$mutationType=="CNA"))
  
  if (add.conflicts) {
    # Only allow subclonal losses here
    allowed.conflicts = c("sLoss", "sLOH")
    cndata = cndata[cndata$CNA %in% allowed.conflicts,]
    
    if (nrow(cndata) == 0) {
      print("No potential conflicting CNA events found")
    } else {
    
      # The CNA events have already been added to the dataset
      conflict.array = array(1, c(nrow(dataset$mutCount), nrow(dataset$mutCount)))
      
      conflicting_mutcount = 0
      for (i in 1:nrow(cndata)) {
        conflict_indices = get.conflicting.indices(dataset, cndata)

        # If there are no conflicts, then move on to the next CNA
        if (sum(conflict_indices, na.rm=T) == 0) { 
          next
        }
        
        # There are conflicts, put them in the conficts array
      	if (sum(conflict_indices) > 3) {
      		print(paste("Found", sum(conflict_indices), "conflicts for this segment, but keeping only 1"))
      		keep = which(conflict_indices)[1]
      		conflict_indices[which(conflict_indices)] = FALSE
      		conflict_indices[keep] = TRUE
      	}

        conflicting_mutcount = conflicting_mutcount + sum(conflict_indices)
        for (i in which(conflict_indices)) {
          j = which(dataset$position==cndata$startpos[i] & dataset$mutationType=="CNA")
          conflict.array[j,i] = 2
          conflict.array[i,j] = 1024 #equivalent to 10 mutations
        }
      }
      
      print(paste("Found ", conflicting_mutcount, " conflicting CNA and SNVs", sep=""))
    }
    dataset$conflict.array = conflict.array
  }
  return(dataset)
}

#' Create a number of pseudo SNVs to represent a CNA and add them to the dataset
create_pseudo_snv = function(cndata.i, num_muts, N, conf, cellularity, dataset, conflicting.events.only) {
  # If only conflicts are allowed, then check whether this is a conflicting CNA event. If not, return the dataset
  if (conflicting.events.only) {
    conflict_indices = get.conflicting.indices(dataset, cndata.i)
    if (!(sum(conflict_indices) > 0)) {
      return(dataset)
    }
  }
  
  num.samples = ncol(dataset$mutCount)
  # Create pseudo SNV carried by 1 copy in 1+1 area, and being subclonal proportionate to the CNA
  tumourCN = 2
  ncbm = 1 # copy number adjustment / multiplicity
  reads.per.clonal.copy = (cellularity*N/conf) / (cellularity*tumourCN + (1-cellularity)*2)
  
  # multiple mutations - a cluster, therefore add binomial noise
  if (round(num_muts) > 1) {
    # Calculate the expected number of reads carying the mutation and from there mutCount, WTCount and mutation.copy.number
    exp_mc = round(reads.per.clonal.copy*cndata.i$frac1_A)
    mc = rbinom(num_muts, round(N/conf), exp_mc/(N/conf))
    mc[mc==0] = 1
    wt = round(N/conf) - mc
    mcn = DPClust:::mutationBurdenToMutationCopyNumber(mc/(mc+wt), tumourCN, cellularity, 2)
    
  # single mutation - do not add binomial noise
  } else {
    num_muts = 1
    mc = round(reads.per.clonal.copy*cndata.i$frac1_A)
    wt = round(N/conf) - mc
    mcn = DPClust:::mutationBurdenToMutationCopyNumber(mc/(mc+wt), tumourCN, cellularity, 2)
  }
  
  # Save the pseudo SNVs in the dataset
  dataset$chromosome = rbind(dataset$chromosome, matrix(rep(cndata.i$chr, num.samples*num_muts), ncol=num.samples))
  dataset$position = rbind(dataset$position, matrix(rep(cndata.i$startpos, num.samples*num_muts), ncol=num.samples))
  dataset$mutCount = rbind(dataset$mutCount, matrix(rep(mc, num.samples), ncol=num.samples))
  dataset$WTCount = rbind(dataset$WTCount,  matrix(rep(wt, num.samples), ncol=num.samples))
  dataset$totalCopyNumber = rbind(dataset$totalCopyNumber,  matrix(rep(tumourCN, num.samples*num_muts), ncol=num.samples))
  dataset$copyNumberAdjustment = rbind(dataset$copyNumberAdjustment, matrix(rep(ncbm, num.samples*num_muts), ncol=num.samples))
  dataset$mutation.copy.number = rbind(dataset$mutation.copy.number, matrix(rep(mcn, num.samples), ncol=num.samples))
  dataset$kappa = rbind(dataset$kappa, matrix(rep(mutationCopyNumberToMutationBurden(1, tumourCN, cellularity), num.samples*num_muts), ncol=num.samples))

  index = which(dataset$position==cndata.i$startpos)
  #print(head(paste("NEW CNA CCF/MCN", cndata.i$frac1_A, dataset$mutation.copy.number[index,1], mcn, dataset$mutCount[index,1], dataset$WTCount[index, 1], conf), 25))
  # TODO: Setting same CNA CCF across samples does not work for multiple samples!
  dataset$subclonal.fraction = rbind(dataset$subclonal.fraction, matrix(rep(dataset$mutation.copy.number[index,1], num.samples), ncol=num.samples))
  dataset$non.deleted.muts = c(dataset$non.deleted.muts, T)

  new_phase = matrix(rep(NA, num.samples), ncol=num.samples)
  for (i in 1:num.samples) {
    new_phase[,i] = "unphased"
  }
  colnames(new_phase) = colnames(dataset$phase)
  dataset$phase = rbind(dataset$phase, new_phase)

  # Setting mutation type of all SNVs and making each CNA most similar to itself
  dataset$mutationType = factor(c(as.character(dataset$mutationType), rep("CNA", num_muts)), levels=c("SNV", "CNA", "indel"))
  dataset$most.similar.mut = c(dataset$most.similar.mut, which(dataset$mutationType=="CNA"))

  return(dataset)
}

add.snv.cna.conflicts = function(dataset, cndata) {
  # Only allow subclonal losses here
  allowed.conflicts = c("sLoss", "sLOH")
  cndata = cndata[cndata$CNA %in% allowed.conflicts,]
  
  if (nrow(cndata) == 0) {
    print("No potential conflicting CNA events found")
  } else {
    
    # The CNA events have already been added to the dataset
    conflict.array = array(1, c(nrow(dataset$mutCount), nrow(dataset$mutCount)))
    
    conflicting_mutcount = 0
    for (i in 1:nrow(cndata)) {
      conflict_indices = dataset$chromosome[dataset$mutationType=="SNV",1]==cndata$chr[i] & 
        dataset$position[dataset$mutationType=="SNV",1] >= cndata$startpos[i] & 
        dataset$position[dataset$mutationType=="SNV",1] <= cndata$endpos[i] & 
        dataset$subclonal.fraction[dataset$mutationType=="SNV",1] < 0.9 &
        dataset$phase[dataset$mutationType=="SNV",1] == "MUT_ON_DELETED"
      
      # If there are no conflicts, then move on to the next CNA
      if (sum(conflict_indices, na.rm=T) == 0) { 
        next
      }
      
      # There are conflicts, put them in the conficts array
      if (sum(conflict_indices) > 3) {
        print(paste("Found", sum(conflict_indices), "conflicts for this segment, but keeping only 1"))
        keep = which(conflict_indices)[1]
        conflict_indices[which(conflict_indices)] = FALSE
        conflict_indices[keep] = TRUE
      }
      
      conflicting_mutcount = conflicting_mutcount + sum(conflict_indices)
      for (i in which(conflict_indices)) {
        j = which(dataset$position==cndata$startpos[i] & dataset$mutationType=="CNA")
        # If there are multiple SNVs that represent this CNA, then just take the first to not create too much weight
        j = j[1]
        conflict.array[j,i] = 2
        conflict.array[i,j] = 1024 # equivalent to 10 mutations
      }
    }
    
    print(paste("Found ", conflicting_mutcount, " conflicting CNA and SNVs", sep=""))
  }
  dataset$conflict.array = conflict.array
  return(dataset)
}

#' Returns a list of subclonal SNV indices that are conflicting with a CNA event. This code 
#' classifies a subclonal SNV has a CCF of < 0.9. This function returns a vector consisting of T/F values.
#' TODO: Determine whether an SNV is likely to be subclonal in a less arbitrary way.
get.conflicting.indices = function(dataset, cndata) {
  if (nrow(cndata) > 1) {
    warning("Cannot fetch conflicting indices from a multi-row CNA data.frame")
  }
  i = 1
  conflict_indices = dataset$chromosome[dataset$mutationType=="SNV",1]==cndata$chr[i] & 
    dataset$position[dataset$mutationType=="SNV",1] >= cndata$startpos[i] & 
    dataset$position[dataset$mutationType=="SNV",1] <= cndata$endpos[i] & 
    dataset$subclonal.fraction[dataset$mutationType=="SNV",1] < 0.9 &
    dataset$phase[dataset$mutationType=="SNV",1] == "MUT_ON_DELETED"
  return(conflict_indices)
}

#' Replace the pseudo SNV clusters that represent a CNA event during clustering
#' by amalgamated assignments for each CNA
#' @param dataset A data set object
#' @return a data set in which the pseudo SNVs are removed
remove_pseudo_snv_cna_clusters = function(dataset) {
  # Remove the pseudo CNAs
  pseudo_snv_index = which(dataset$mutationType=="CNA")
  dataset = remove_mutations(dataset, pseudo_snv_index)
  return(dataset)
}

#' Helper function to remove a set of mutations from a dataset by their index
#' @param dataset A data set object
#' @param mutation_index Index of mutations to be removed
#' @return a data set in which the pseudo SNVs are removed
remove_mutations = function(dataset, mutation_index) {
  dataset$chromosome = dataset$chromosome[-mutation_index,,drop=F]
  dataset$position = dataset$position[-mutation_index,,drop=F]
  dataset$mutCount = dataset$mutCount[-mutation_index,,drop=F]
  dataset$WTCount = dataset$WTCount[-mutation_index,,drop=F]
  dataset$totalCopyNumber = dataset$totalCopyNumber[-mutation_index,,drop=F]
  dataset$copyNumberAdjustment = dataset$copyNumberAdjustment[-mutation_index,,drop=F]
  dataset$mutation.copy.number = dataset$mutation.copy.number[-mutation_index,,drop=F]
  dataset$kappa = dataset$kappa[-mutation_index,,drop=F]
  dataset$subclonal.fraction = dataset$subclonal.fraction[-mutation_index,,drop=F]
  dataset$non.deleted.muts = dataset$non.deleted.muts[-mutation_index]
  dataset$phase = dataset$phase[-mutation_index]
  dataset$mutationType = dataset$mutationType[-mutation_index]
  if (!is.na(dataset$most.similar.mut)) {
    dataset$most.similar.mut = dataset$most.similar.mut[-mutation_index]
  }
  return(dataset)
}

#' Add mutation phasing information to a dataset
#' @param dataset A data set object
#' @param mutphasing data.frame with phasing data
#' @param add.conflicts Supply TRUE when a mutation-to-mutation confict matrix is to be built (Default: FALSE)
#' @return a dataset with field mutphasing and potentially field conflict.array added
add.mutphasing = function(dataset, mutphasing, add.conflicts=F) {
  dataset$mutphasing = mutphasing
  
  if (add.conflicts & sum(mutphasing$phasing=="anti-phased") > 0) {
    anti.phased = mutphasing[mutphasing$phasing=="anti-phased",]
    
    if (is.na(dataset$conflict.array)) {
      dataset$conflict.array = array(1, c(nrow(dataset$mutCount), nrow(dataset$mutCount)))
    }
    
    for (i in 1:nrow(anti.phased)) {
      print("Adding phasing conflict:")
      print(anti.phased[i,])
      
      # Work out index of both mutations
      k = which(dataset$chromosome==anti.phased$Chr[i] & dataset$position==anti.phased$Pos1[i])
      l = which(dataset$chromosome==anti.phased$Chr[i] & dataset$position==anti.phased$Pos2[i])
      
      # Check that only one hit
      if (length(k) > 1 | length(l) > 1) {
        warning("Mutation occurring more than once in add.mutphasing")
      }
            
      # Check that the conflict array is synchronised
      if (k > nrow(dataset$conflict.array) | l > nrow(dataset$conflict.array)) {
        warning("Conflict array and mutation data not synchronised in add.mutphasing")
      }
      
      # Assign higher conflict status to both
      dataset$conflict.array[k,l] = dataset$conflict.array[k,l] + 1
      dataset$conflict.array[l,k] = dataset$conflict.array[l,k] + 1
    }
  }
  return(dataset)
}

#' Add indels to an existing dataset
#' @param dataset A data set object
#' @param indeldata A list of read in data.frames (one per sample) with output from dpclust3p
#' @param supported_chroms Chromosomes that are supported
#' @return the provided dataset with indels added
add.in.indels = function(dataset, indeldata, is.male, supported_chroms) {
  indelset = load.data.inner(list_of_tables=indeldata, 
                             cellularity=dataset$cellularity, 
                             Chromosome="chr", 
                             position="end",
                             WT.count="WT.count", 
                             mut.count="mut.count", 
                             subclonal.CN="subclonal.CN", 
                             no.chrs.bearing.mut="no.chrs.bearing.mut", 
                             mutation.copy.number="mutation.copy.number", 
                             subclonal.fraction="subclonal.fraction", 
                             phase="phase",
                             is.male=is.male,
                             supported_chroms=supported_chroms, 
                             mutation_type="indel")
  dataset = append.dataset(dataset, indelset)
  # Save the indelset separately
  dataset$indeldata=indelset
  return(dataset)
}


#' Convenience function to append two datasets
#' @param a dataset a
#' @param b dataset b
#' @return a dataset in which a and b are appended
append.dataset = function(a, b) {
  if (dim(a$mutCount) != dim(b$mutCount) & a$cellularity!=b$cellularity) {
    stop("Cannot append two datasets of different sizes or with different cellularities")
  }
  
  if (!is.na(a$sampling.selection) | !is.na(b$sampling.selection)) {
    stop("Cannot append datasets that have been downsampled")
  }
  
  if (!is.na(a$conflict.array) | !is.na(b$conflict.array)) {
    stop("Cannot append datasets that contain conflict arrays")
  }
  
  # Append the basic tables
  a$chromosome = rbind(a$chromosome, b$chromosome)
  a$position = rbind(a$position, b$position)
  a$mutCount = rbind(a$mutCount, b$mutCount)
  a$WTCount = rbind(a$WTCount,  b$WTCount)
  a$totalCopyNumber = rbind(a$totalCopyNumber,  b$totalCopyNumber)
  a$copyNumberAdjustment = rbind(a$copyNumberAdjustment, b$copyNumberAdjustment)
  a$mutation.copy.number = rbind(a$mutation.copy.number, b$mutation.copy.number)
  a$kappa = rbind(a$kappa, b$kappa)
  a$subclonal.fraction = rbind(a$subclonal.fraction, b$subclonal.fraction)
  a$phase = rbind(a$phase, b$phase)
  a$mutationType = factor(c(as.character(a$mutationType), as.character(b$mutationType)), levels=c("SNV", "CNA", "indel"))
  a$most.similar.mut = c(a$most.similar.mut, b$most.similar.mut)
  a$non.deleted.muts = c(a$non.deleted.muts, b$non.deleted.muts)
  a$chromosome.not.filtered = c(a$chromosome.not.filtered, b$chromosome.not.filtered)
  a$mut.position.not.filtered = c(a$mut.position.not.filtered, b$mut.position.not.filtered)

  # Add the total number of SNVs in the a dataset to the removed indices of b
  a$removed_indices = c(a$removed_indices, b$removed_indices+nrow(a$chromosome.not.filtered))
  
  # Cannot have been any downsampling, so take whatever is in a
  a$sampling.selection = a$sampling.selection
  a$conflict.array = a$conflict.array
  # Mutphasing tables can be appended
  a$mutphasing = rbind(a$mutphasing, b$mutphasing)
  
  # full.data=full_data, 
  return(a)  
}
