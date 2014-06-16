#!/usr/bin/Rscript --vanilla --slave --quiet
 
library("rciop")
library("rOpenSearch")
library("httr")
library("stringr")
library("XML")
library("RCurl")
library("sp")
library("rgeos") 

source("/application/sar-stack/libexec/lib.R")

# ERS-1, ERS-2, Envisat number of cycles
max.cycles <- list("ERS-1"=200, "ERS-2"=200, "ENVISAT"=110)

# get the bbox
bbox <- rciop.getparam("bbox")

# set the response type for the catalogue queries
response.type <- "application/rdf+xml"


# read the stdin into a file
f <- file("stdin")
open(f)

while(length(osd.description <- readLines(f, n=1)) > 0) {
 
  rciop.log("INFO", paste("Analysing:", osd.description, sep=" "))
 
  mission.info <- GetMissionInfo(osd.description)
  
  # get the queryables exposed by the OpenSearch document
  q <- GetOSQueryables(osd.description, response.type)
  
  # fill the queryables values
  q$value[q$type == "geo:box"] <- bbox
  q$value[q$type == "count"] <- 900

  satelite <- as.character(GetMissionInfo(osd.description)$mission)

  coverage.df <- GetCoverage(osd.description, response.type, q)

  rciop.log("DEBUG", head(coverage.df))

  # plot the information
  # prepare the canvas
  n.columns <- 3
  
  if (length(coverage.df) %% n.columns == 1 ) {
    n.rows <- length(coverage.df) %/% n.columns + 1
  } else {
    n.rows <- length(coverage.df) %/% n.columns
  }
  
  pdf.filename <- paste(TMPDIR, "/", as.character(mission.info$identifier), ".pdf", sep="")

  # create a meaningful outputname
  pdf(pdf.filename)
  
  # create the multi-plot canvas
  par(mfrow = c(n.rows, n.columns))
  
  # plot each of the relative orbits
  for (index in seq(1, length(coverage.df))) {
    
    plot(coverage.df[,index], 
      type="h", 
      lwd=1, 
      axes=FALSE, 
      ylab=paste("# of passes:", length(which(coverage.df[,index] == TRUE))),
      xlab=paste("cycle from 1 to ", max.cycles[as.character(mission.info$mission)]))
    
    title(paste("Orbit", colnames(coverage.df)[index], sep=" "))
  }
  
  title(main=paste(as.character(mission.info$title), "over", bbox, sep=" "), outer=T)
  dev.off()

  rciop.publish(pdf.filename, metalink=TRUE, recursive=FALSE)   
}
