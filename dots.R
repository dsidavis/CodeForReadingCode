
e = getNamespace("utils")
funs = as.list(e)
funs = funs[sapply(funs, is.function)]

w = sapply(funs, function(f) "..." %in% names(formals(f)))

names(funs[w])


# Is the ... used?
# utils:::format.person seems to have a ... but then doesn't use it ?
# In general, is it for additional parameters in a method?

# How is it used - as list(...) or passed to another call with ...
# utils:::changedFiles uses list(...)

a = usesDots(utils:::format.person)
# empty so never uses the ...

b = usesDots(utils:::changedFiles)
sapply(b, function(x) x$fn$name)


# ... is passed in 4 different places in the code to 3 different functions
c = usesDots(new.packages)
fns = sapply(c, function(x) x$fn$name)

# What can be in ... passed to new.packages.
# We find these 3 functions to which ... might be passed and see what their parameter names are,
# We exclude the ones that are in the calls along with the passed ... as we can't duplicate those parameters
tt = lapply(c, function(x) setdiff(names(formals(get(x$fn$name, mode = "function"))), c(names(x$args), "...")))
# The following is the union of all the parameters in the 3 functions
unique(unlist(tt))
# However, we may want the ones that are common to all in case the ... is actually passed to all 3 functions
tb = table(unlist(tt))
names(tb)[tb == length(c)]
# Since there are no parameters in common, this suggests that we only call 2 or fewer of these functions
# in  new.packages() and which one(s) are done within if() statements.
# So we have to trace the control flow. Examining the code manually, we see ... is passed to installed.packages
# (along with lib.loc) via the instPkgs parameter and this call will be forced if instPkgs is not explicitly
# provided by the caller.  If available is not specified by the caller, ... will then be passed to available.packages
# along with contriburl and method and then on to install.packages




f = function(..., .args = list(...))
{
  sum(sapply(.args, length))
}

usesDots(f)
