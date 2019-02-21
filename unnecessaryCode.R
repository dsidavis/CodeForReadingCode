library(CodeDepends)

sc = readScript("changepoint.R")
info = getInputs(sc)

nout = sapply(info, function(x) length(x@outputs) + length(x@updates) + length(x@libraries))

sc[ nout == 0 ]


# We see
# rm(list = ls(all = TRUE))
# This has a side effect so should be left, but we don't actually want it in the script.

# There are 5 calls to unique()
# These are just visual sanity checks and have no side effect.

# There is a call to ggdensity() which will create a plot
# So there is a side-effect.

# There are several calls to shapiro.test()
# These have no side-effect.

# There are 19 calls to write.csv() which do have side-effects.

# And finally there is a call to hist()


# But what about variables we create that we don't use again.

vars = lapply(info, function(x) c(x@updates, x@outputs))
inputs = lapply(info, slot, "inputs")
i = sapply(seq(along = vars), function(i)  vars[i] %in% unlist(inputs[-(1:i)]))




# Here is a code example where c is created but never used.
# We use the same
sc = readScript("unnecessaryCode_eg.R")
info = getInputs(sc)

vars = lapply(info, function(x) c(x@updates, x@outputs))
inputs = lapply(info, slot, "inputs")
i = sapply(seq(along = vars), function(i)  vars[i] %in% unlist(inputs[-(1:i)]))

# Which variables are defined but not used in the future.
unlist(vars[!i])
