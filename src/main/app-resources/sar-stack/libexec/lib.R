GetMissionInfo <- function (osd.description) {
  
  cat.res <- getURL(str_replace(osd.description, "description", "rdf"))
  
  mission <- xpathApply(xmlParse(cat.res), "//dclite4g:Series/eop:platform", xmlValue)
  
  title <- xpathApply(xmlParse(cat.res), "//dclite4g:Series/dc:title", xmlValue)
  
  identifier <- xpathApply(xmlParse(cat.res), "//dclite4g:Series/dc:identifier", xmlValue)
  
  return(list(identifier=identifier, mission=mission, title=title))
}

GetCoverage <- function(osd.description, response.type, q) {

  # get the queryables
  q <- GetOSQueryables(osd.description, response.type)
  
  # fill the queryables values
  q$value[q$type == "geo:box"] <- bbox
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

  return(my.df)
  
} 
