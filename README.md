# Meta-Programming for Code Exploration &amp; Review <img style="float: right" src="http://dsi.ucdavis.edu/images/dsi_banner.png" height="4%"></img>
## Duncan Temple Lang

This is for a brief talk for the "Code Review" sessions where we discuss
the myriad of issues when writing code  for different projects, both DSI
projects and student and faculty projects.
See [slides.html](slides.html)

On this session, we'll talk about tools that help us programmatically
understand aspects of R code. This is meta-programming - programming where the
inputs are code. The ideas apply to other languages, however they are especially convenient
in R.  This is because R code  can be readily represented as R objects - for example, just use the `parse()`
function, or `quote()`, or `body()` on a function.  

We can also operate on C and C++ code, again because there is a parser for these
languages. And, for some purposes, we can read the C/C++ code into LLVM and operate on it
in R at a very different level - not the syntactic AST (abstract syntax tree), but on the 
Intermediate Representation, and even the optimized code.

There are  a variety of packages we can use with different levels of low- and high-level
functionality, and we are in the process of building more. These include
+ codetools (comes with every installation of R)
+ [CodeDepends](https://github.com/duncantl/CodeDepends.git)
+ [CodeAnalysis](https://github.com/duncantl/CodeAnalysis.git)
+ [rstatic](https://github.com/nick-ulle/rstatic.git)

For C/C++
+ [RCIndex](https://github.com/omegahat/RClangSimple.git)
+ [Rllvm](https://github.com/duncantl/Rllvm.git)

All of these allow us to query aspects of code; some of the tools allow one to transform code
or to generate code.


### Sometimes we start with
+ a script and perhaps some associated files containing functions
+ a collection of functions in one or more files,
+ or a complete R package - a more structured representation of a collection of files with functions.

### We might want to know, for example,
<!-- done -->
+  which functions call which other functions - see `CodeDepends::makeCallGraph()`
   + if we need to change the name of a function, we know where to change the calls to it.  (We can do it programmatically.)
<!-- done -->
+  which functions are defined in these files and which are assumed to be somewhere else
   + Can `source()` into a separate environment for each file [funFileNames_source.R](funFileNames_source.R)
   + Static analysis of parsed data - see [funFileNames.R](funFileNames.R)
<!-- done : check the :: and ::: -->
+  what packages are used via library(), require() or via the `::` operator -
    [slides.html](slides.html) and `CodeDepends::getInputs()` and the libraries slot.
<!-- done -->
+  what are the global variables in use intentionally - see `CodeAnalysis::getGlobals()` and `codetools::findGlobals`.
<!-- done -->
+  what functions have global variables that are unintentional - see [slides.html](slides.html)
<!-- done -->
+  what parameters in a function are never used - see `CodeAnalysis::findUnusedArgs()`
   + when we compare this with global variables in the functions, we often find typos e.g. a
     parameter named dir and use of a global variable named dr or directory
<!-- done -->
+  what are the names of options() are used in the code. - see `CodeAnalysis::findUsedOptions()`.
<!-- done -->
+  what files are read via, e.g., read.table(), read.csv(), readRDS(), load(), etc. - see [slides.html](slides.html) and `CodeAnalysis::getReadFiles()`
<!-- done -->
+  can we visualize the flow of the code - see [slides.html](slides.html) and `CodeDepends::makeVariableGraph()` and `plot()`.
+  which functions support ... parameter - see [dots.R](dots.R) and `CodeAnalysis::usesDots()`
   + do they process these values directly? or
   + pass them on to other functions and what are these other functions?
   + If they pass them on, what other parameters are in those calls so cannot be in the ...
+  what expressions in the script might not be needed (i.e., left over and redundant) - see
  [unnecessaryCode.R](unnecessaryCode.R). Also, see Nick's example in his thesis to add a rm() call
  when a variable is no longer used.
+ expressions that are repeated with only one parameter changed and should be done in a loop to
  avoid repetition.
    + Are there collections of "very similar blocks of expressions" that are repeated?
+ what parts of the code are platform-specific, e.g. for Windows only - see Platform.R
  + look for `if(.Platform$OS.type) ...` or  `switch(.Platform$OS.type, unix = , windows = )` - see
    [Platform.R](Platform.R), but issues with rstatic and subsetting results.
+ functions defined inside other functions but don't use as closure by assigning values just acess
  values that could be passed down.
  + Find nested functions - 
+ what files are created, e.g., as plots.  Somewhat done in CodeDepends.
+ for loops without preallocation
+ where are the referenced symbols in an expression (toplevel or in a function's body) going to be
  found?
    + look inside function, 
	+ closure
	+ other symbols in the same file, 
	+ in other related files in  directory/project/package
	+ along search path 
	+ or in a namespace/environment
+ is the returned value of a function first assigned to a variable and then immediately returned,
  e.g.,
```
ans = foo()
ans
```
+ Are variables assigned in an if() statement and do they get assigned in both if and else branch
  <!-- See ifAssign.R and in CodeAnalysis/R/ifAssignment.R -->
  so could be written as `var = if() value else otherValue`

+ If I change the default value for a parameter, e.g., from TRUE to FALSE,
 how many calls to this function will I have to change? and where (i.e. identify them all,
 including indirect calls such as in `lapply(X, fun)`?
<!-- done -->
+  identify non-standard evaluation, e.g., calls to get(), assign(), eval() -  see
  [slides.html](slides.html) and `CodeAnalysis::findNSE()`
<!-- done -->
+  find definitions of S4 classes - see [slides.html](slides.html) and `CodeAnalysis::mkClassGraph()`
<!-- done -->
+  creation of S3 objects, i.e. assigning a class to an object - [slides.html](slides.html) and `S3Assignments()`
<!-- done -->
+  S4 methods - [slides.html](slides.html) and `showMethods()` and `methods()` in regular R.
<!-- partially done -->
+  access of slots that don't exist. - see [missedSlots.R](missedSlots.R) and `CodeAnalysis::findSlotAccess()`
   + here we need to know the class of the object. Type inference is important for a general
     approach, but we can do more limited error checking, 
	 + i.e., find if a slot name exists in any
     class defined in the code, if we know the possible class of an object as it is created within the same scope.

  

#### Migrating dependency from one package to another

For example, 
+ What packages does this code use, e.g., XML or xml2?
+ What functions does it use from XML and are there equivalent ones in xml2?
+ How many places in the code will I have to change to migrate the code from one package to another?



## Approaches
### Regular Expressions versus Structured Trees

We can use regular expressions to answer these questions, but this is a very fragile approach.
Instead, we parse the code and then process the resulting hierarchical tree structure. 
This is analogous to not using regular expressions for XML/HTML but rather 
parse the tree and then extract the relevant elements.



We currently have some primitive tools on which we and others can build higher-level functionality.
And we also have some higher-level functionality.








## Things we learned from Code Review

Note in install.packages, we see
```
gsub("_[.](zip|tar[.]gz|tar[.]bzip2|tar[.]xz)", "",
```
It is an interesting way to write a regular expression.
We want to escape the period in the file name, i.e. the '.'.  We could 
use `\\.`  But `[.]` may be more readable.
