rcodeFiles = c("S3Class.R", "mkClassHierarchy.R")

lapply(rcodeFiles, function(f) {
                     e = new.env()
                     source(f, e)
                     ls(e)
                 })

