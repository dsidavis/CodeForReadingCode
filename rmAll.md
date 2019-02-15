

I see a lot of scripts that start with
```
rm(list = ls(all = TRUE))
```

This means that if I source() this file, the script
will remove all of my variables that I created previously
in my R session.  This includes variables that were created as part of my .Rprofile.

What's the purpose of this?
Perhaps it is to allow one to rerun the script and ensure that we are not using variables
created in a previous source() of the script or created interactively.
If we remove all of the variables, then we guarantee that if we use
a variable before we create it, we will get an error.


It is fine if we run the script in a separate R session, but it is still a somewhat antisocial
approach.
There are two approaches to achieving the same thing:
+ source() or run the code in a separate environment and then throw this away
+ rm() only the variables that you create.

However, if the goal is to avoid using a variable that was "left over" 
because we created  it interactively or in a different run,
then we can analyze the code to determine whether we use a variable
before we define it. This is a better approach. It identifies a problem
before we run the code. It tells us where to fix the problem.


The `CodeDepends` package can help here.
We are looking for any expression that has an input that is not yet defined.
``
library(CodeDepends)
sc = readScript("useBeforeDefine.R")
CodeDepends:::undefinedVariables(sc)
```
This shows d is used before it is defined.



We can find such calls to `rm(list = ls()))` using the
`isRemoveAllVars()` function in the `CodeAnalysis` package.
```
e = parse("script.R")
i = isRemoveAllVars(e)
if(length(i))
  e = e[ - i]
```
