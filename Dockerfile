FROM ubuntu:20.04

USER root

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get -y install r-base libxml2 libxml2-dev libcurl4-gnutls-dev libssl-dev curl git

RUN R -q -e 'install.packages("BiocManager"); BiocManager::install(c("optparse","KernSmooth","ks","lattice","ggplot2","gridExtra","VariantAnnotation","GenomicRanges","Rsamtools","IRanges","S4Vectors","reshape2","data.table"))'

RUN mkdir -p /opt/dpclust
COPY . /opt/dpclust/
RUN R -q -e 'install.packages("/opt/dpclust", repos=NULL, type="source")'
RUN git clone https://github.com/OpenGenomics/dpclust3p /opt/dpclust3p
RUN R -q -e 'install.packages("/opt/dpclust3p", repos=NULL, type="source")'

## USER CONFIGURATION
RUN adduser --disabled-password --gecos '' ubuntu && chsh -s /bin/bash && mkdir -p /home/ubuntu

USER    ubuntu
WORKDIR /home/ubuntu

CMD ["/bin/bash"]
