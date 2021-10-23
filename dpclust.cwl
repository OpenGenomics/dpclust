cwlVersion: v1.0
class: CommandLineTool
label: dpclust
baseCommand: [ Rscript, --vanilla, --slave, /opt/dpclust/DPClust_run.R ]
requirements:
  - class: DockerRequirement
    dockerPull: opengenomics/dpclust:v3.0

inputs:
  sampleid:
    type: string
    inputBinding:
      position: 1
  purity:
    type: float
    inputBinding:
      position: 2
  ploidy:
    type: float
    inputBinding:
      position: 3
  gender:
    type: string
    inputBinding:
      position: 4
  workdir:
    type: string
    default: ./
    inputBinding:
      position: 5

outputs:
  dp_info:
    type: File
    outputBinding:
      glob: ./$(inputs.sampleid)*DP_and_cluster_info.txt
  best_cluster:
    type: File
    outputBinding: 
      glob: ./$(inputs.sampleid)*bestClusterInfo.txt
  optima:
    type: File
    outputBinding:
      glob ./$(inputs.sampleid)*optimaInfo.txt
  dp_locations2:
    type: File
    outputBinding:
      glob: ./$(inputs.sampleid)*DirichletProcessplot_with_cluster_locations_2.png
  likelihoods_bed:
    type: File
    outputBinding:
      glob: ./$(inputs.sampleid)*mutationClusterLikelihoods.bed
  assignments_bed:
    type: File
    outputBinding:
      glob: ./$(inputs.sampleid)*bestConsensusAssignments.bed
  best_results:
    type: File
    outputBinding:
      glob: ./$(inputs.sampleid)*bestConsensusResults.RData
  mut_assign:
    type: File
    outputBinding:
      glob: ./$(inputs.sampleid)*mutation_assignments.png
