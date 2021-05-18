cwlVersion: v1.0
class: CommandLineTool
label: dpclust
baseCommand: [ Rscript, --vanilla, --slave, /opt/dpclust/ ]
requirements:
  - class: DockerRequirement
    dockerPull: opengenomics/dpclust:v2.0

inputs:
  sampleid:
    type: string
    inputBinding:
      position: 1
  workdir:
    type: string
    default: ./
    inputBinding:
      position: 2

outputs:
  bestCluster:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)_bestClusterInfo.txt
  bestCA:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)_bestConsensusAssignments.bed
  likelihoods:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)_mutationClusterLikelihoods.bed
  bestCR:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)_bestConsensusResults.RData
  dpLocations:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)_DirichletProcessplot_with_cluster_locations_2.png
  mutAssign:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)_mutation_assignments.png
