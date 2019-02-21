
b = body(utils::install.packages)[-1]
k = sapply(b, class)

w = sapply(b, function(e) class(e) %in% c("=", "<-") && is.call(e[[3]]) && is.name(e[[3]][[1]]) && as.character(e[[3]][[1]]) == "function")

internalFuns = structure(lapply(b[w], `[[`, 3),  names = sapply(b[w], function(e) as.character(e[[2]])))

library(codetools)
gvars = lapply(internalFuns, function(e) findGlobals(eval(e), FALSE))




b = body(tools:::.install_packages)[-1]




ns = getNamespace("utils")

length(ls(ns, all = TRUE))


