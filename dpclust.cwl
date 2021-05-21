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
  dp_density:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)__DirichletProcessplotdensity.txt
  dp_plot:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)__DirichletProcessplot.png
  dp_polygon:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)__DirichletProcessplotpolygonData.txt
  dp_locations:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)__DirichletProcessplot_with_cluster_locations.png
  dp_locations2:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)__DirichletProcessplot_with_cluster_locations_2.png
  dp_cluster:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)__DP_and_cluster_info.txt
  gsdata:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)__gsdata.RData
  local_optima:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)__localOptima.txt
  optima_info:
    type: File
    outputBinding:
      glob: $(inputs.sampleid)__optimaInfo.txt
