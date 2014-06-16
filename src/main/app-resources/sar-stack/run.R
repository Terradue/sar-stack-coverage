#!/usr/bin/Rscript --vanilla --slave --quiet
 
library("rciop")

library("httr")
library("stringr")
library("XML")
library("RCurl")
library("sp")
library("rgeos") 

# ERS-1, ERS-2, Envisat number of cycles
max.cycles <- list("ERS-1"=200, "ERS-2"=200, "ENVISAT"=110)

# get the bbox
os.stop <- rciop.getparam("bbox")

# a function to get the mission: ERS-1, ERS-2 or ENVISAT
GetMission <- function (osd.description) {
  
  cat.res <- getURL(str_replace(osd.description, "description", "rdf"))
  
  mission <- xpathApply(xmlParse(cat.res), "//dclite4g:Series/eop:platform", xmlValue)
  
  return(mission)
}

GetCoverage <- function(osd.description, response.type, q) {

  # get the queryables
  q <- GetOSQueryables(osd.description, response.type)
  
  # fill the queryables values
  q$value[q$type == "geo:box"] <- etna.bbox
  q$value[q$type == "count"] <- 900
  
  # query the catalogue 
  query.res <- Query(osd.description, response.type, q) 
  
  # from the catalogue response, extract the datasets
  dataset <- xmlToDataFrame(nodes = getNodeSet(xmlParse(query.res), 
    "//dclite4g:DataSet"), stringsAsFactors = FALSE)
  
  # get the list of relative orbits within a cycle covering the AOI
  rel.orbit <- unique(dataset$wrsLongitudeGrid)
  
  # for each relative orbit, get the cycles where that relative orbit is available on the catalogue 
  cycle <- lapply(rel.orbit, function(x) {
   
    subset.track <- dataset[dataset$wrsLongitudeGrid == x,]
    
    list(relative.orbit=x, cycles=rev(unique(subset.track$cycle)))
   })
  
  # create a list with the sequence of the satelite cycles
  cycle.list <- c(seq(1:as.numeric(max.cycles[satelite])))
  
  # create an empty data frame
  my.df <- data.frame(matrix(NA, nrow = as.numeric(max.cycles[satelite]), ncol = 0))

  # fill the data frame with logical values
  for (index in seq(1, length(rel.orbit))) {
    both <- union(cycle.list, as.numeric(cycle[[index]]$cycles))
    d <- both %in% as.numeric(cycle[[index]]$cycles)
    my.df <- cbind(my.df, d)
  }
  
  # set the names of the data frame
  rownames(my.df) <- paste("cycle", 1:as.numeric(max.cycles[satelite]), sep="_")
  colnames(my.df) <- rel.orbit
  
  # plot the information
  
  # prepare the canvas
  n.columns <- 3
  
  if (length(rel.orbit) %% n.columns == 1 ) {
    n.rows <- length(rel.orbit) %/% n.columns + 1
  } else {
    n.rows <- length(rel.orbit) %/% n.columns
  }
  
  par(mfrow = c(n.rows, n.columns))
  
  # plot each of the relative orbits
  for (index in seq(1, length(rel.orbit))) {
    
    plot(my.df[,index], 
      type="h", 
      lwd=1, 
      axes=FALSE, 
      ylab=paste("# of passes:", length(which(my.df[,index] == TRUE))),
      xlab=paste("cycle from 1 to ", max.cycles[satelite]))
    
    title(paste("Orbit", colnames(my.df)[index], sep=" "))
  }
  
  title(main="ASAR Image Mode Level 0 over the Etna", outer=T)
  

}

# set the response type for the catalogue queries
response.type <- "application/rdf+xml"


# read the stdin into a file
f <- file("stdin")
open(f)

while(length(osd.description <- readLines(f, n=1)) > 0) {
  
  # get the queryables exposed by the OpenSearch document
  q <- GetOSQueryables(osd.description, response.type)
  
  # fill the queryables values
  q$value[q$type == "geo:box"] <- bbox
  q$value[q$type == "count"] <- 900

  GetCoverage(osd.description, response.type, q)
  
}
