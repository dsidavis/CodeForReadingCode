library(rstatic)
e = parse("changepoint.R")
e = to_ast(e)
i = find_nodes(e, function(x) is(x, "Call") && x$fn$name == "write.csv")

length(i)
# 19 calls to write.csv

kalls = lapply(i, function(i) e[[ i ]] )

files = sapply(kalls, function(x) x$args[[2]]$value)
vars = sapply(kalls, function(x) x$args[[1]]$name)

w = (gsub("\\.csv$", "", files) == vars)
table(w)
# 2 are not the same
kalls[!w]

# abvmed_mcpts_final -> "abvmed_cpts_final.csv"
# tas_mcpts_final    -> "tas_cpts_final.csv") 
#  no m in file names before the cpts.
#
