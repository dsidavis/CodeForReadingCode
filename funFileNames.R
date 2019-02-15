# Find what functions are defined in each file

rcodeFiles = c("S3Class.R", "mkClassHierarchy.R")

e = lapply(rcodeFiles, parse)

# This assumes functions are defined as expressions of the form
#   name = function()....
# So we don't do any error checking.
# We could make this more robust.

# Using R language objects directly
lapply(e[[1]], function(x)
       if(class(x) %in% c("=", "<-") && is.call(x[[3]]) && as.character(x[[3]][[1]]) == "function")
          as.character(x[[2]])
       else
          character())

# This could fail for, e.g.,
#  x$foo = function()...
#  foo = (function(){})()


# Using rstatic
library(rstatic)
e1 = to_ast(e[[1]])
idx = find_nodes(e1, is, "Function")

lapply(idx, function(i) e1[[i]]$parent$write$name)



