cwlVersion: v1.0
class: CommandLineTool
label: dpclust
baseCommand: [ Rscript, --vanilla, --slave, /opt/dpclust/DPClust_run.R ]
requirements:
  - class: DockerRequirement
    dockerPull: quay.io/ohsugdanpipelines/dpclust

inputs:
  sampleid:
    type: string
    inputBinding:
      position: 1
  rho_psi:
    type: File
    inputBinding:
      position: 2
  gender:
    type: string
    inputBinding:
      position: 3
  workdir:
    type: string
    default: ./
    inputBinding:
      position: 4
  dpfile:
    type: File
    inputBinding:
      position: 5

outputs:
  dpout:
    type: Directory
    outputBinding:
      glob: ./$(inputs.sampleid)
#  dp_info:
#    type: File
#    outputBinding:
#      glob: ./$(inputs.sampleid)/$(inputs.sampleid)*DP_and_cluster_info.txt
#  best_cluster:
#    type: File
#    outputBinding: 
#      glob: ./$(inputs.sampleid)/$(inputs.sampleid)*bestClusterInfo.txt
#  optima:
#    type: File
#    outputBinding:
#      glob ./$(inputs.sampleid)/$(inputs.sampleid)*optimaInfo.txt
#  dp_locations2:
#    type: File
#    outputBinding:
#      glob: ./$(inputs.sampleid)/$(inputs.sampleid)*DirichletProcessplot_with_cluster_locations_2.png
#  likelihoods_bed:
#    type: File
#    outputBinding:
#      glob: ./$(inputs.sampleid)/$(inputs.sampleid)*mutationClusterLikelihoods.bed
#  assignments_bed:
#    type: File
#    outputBinding:
#      glob: ./$(inputs.sampleid)/$(inputs.sampleid)*bestConsensusAssignments.bed
#  best_results:
#    type: File
#    outputBinding:
#      glob: ./$(inputs.sampleid)/$(inputs.sampleid)*bestConsensusResults.RData
#  mut_assign:
#    type: File
#    outputBinding:
#      glob: ./$(inputs.sampleid)/$(inputs.sampleid)*mutation_assignments.png
