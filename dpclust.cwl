cwlVersion: v1.0
class: CommandLineTool
label: dpclust
baseCommand: [ Rscript, --vanilla, --slave, /opt/dpclust/DPClust_run.R ]
requirements:
  - class: DockerRequirement
    dockerPull: opengenomics/dpclust:v2.0

inputs:
  sampleid:
    type: string
    inputBinding:
      position: 1
  dpinput:
    type: File
    inputBinding:
      position: 2
  workdir:
    type: string
    default: ./
    inputBinding:
      position: 3

outputs:
  best_cluster:
    type: File
    outputBinding: 
      glob: $(inputs.sampleid)__bestClusterInfo.txt
  dp_locations2:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)__DirichletProcessplot_with_cluster_locations_2.png
  likelihoods_bed:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)__mutationClusterLikelihoods.bed
  assignments_bed:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)__bestConsensusAssignments.bed
  best_results:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)__bestConsensusResults.RData
  mut_assign:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)__mutation_assignments.png
