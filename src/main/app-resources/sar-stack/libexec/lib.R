GetMissionInfo <- function (osd.description) {
  
  cat.res <- getURL(str_replace(osd.description, "description", "rdf"))
  
  mission <- xpathApply(xmlParse(cat.res), "//dclite4g:Series/eop:platform", xmlValue)
  
  title <- xpathApply(xmlParse(cat.res), "//dclite4g:Series/dc:title", xmlValue)
  
  identifier <- xpathApply(xmlParse(cat.res), "//dclite4g:Series/dc:identifier", xmlValue)
  
  return(list(identifier=identifier, mission=mission, title=title))
}

