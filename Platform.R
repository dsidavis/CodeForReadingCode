
funs = as.list(getNamespace("tools"))
funs = funs[sapply(funs, is.function)]


p = lapply(funs, function(f) find_nodes(to_ast(f), function(node) is(node, "Symbol") && node$name == ".Platform"))

w = sapply(p, length) > 0
funs = funs[w]
p = p[w]

# This yields 29 functions.
names(funs)


# We have the use of .Platform but we need the parent
# Let's see if these are all $ operators or any [[
# Note the $parent$parent to go beyond the ArgumentList to the Subset call.
k = mapply(function(f, idx) { f = to_ast(f); lapply(idx, function(i) f[[i]]$parent$parent)}, funs, p)

# See how many uses of .Platform in each function across the functions
table(sapply(k, length))


table(unlist(lapply(k, function(x) sapply(x, class))))
# So all are Subset

# And all are $ 
table(unlist(lapply(k, function(x) sapply(x, function(x) x$fn$name))))

# Now let's see which ones are $OS.type

el = lapply(k, function(x) sapply(x, function(x) x$args[[2]]$name))

table(unlist(el))
#dynlib.ext    OS.type   path.sep     r_arch 
#         2         30          5          1

# Drop the non-OS.type calls

k = lapply(k, function(x) x[lapply(x, function(x) x$args[[2]]$name) == "OS.type"])
k = k[sapply(k, length) > 0]
length(k)

# Which ones are not in if() conditions or switch() statements

source("foo.R")


w = lapply(k, function(x) sapply(x, isInIfOrSwitch))

table(unlist(w))
# 11 are ?

names(k)[sapply(w, function(x) any(x == "?"))]

# tools:::compatibilityEnv uses .Platform$OS.type in a switch() call.



# In checkTnF, the call to prepare_Rd() function uses .Platform$OS.type
# in 
#     prepare_Rd(file, defines = .Platform$OS.type)

# so we can examine the prepare_Rd() function.
# That uses defines as
#      if (!is.null(defines)) 
#         Rd <- processRdIfdefs(Rd, defines)
# So we look at processRdIfdefs()
# Ultimately we find this being used in
#   if ((target %in% defines) == (tag ==  "#ifdef"))
# So this is another if() statement
# 

