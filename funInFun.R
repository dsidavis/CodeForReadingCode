
f =
function(x, n)
{

    y = cumsum(x)
    g = function(z) {
        z + h(n)
    }

    h = function(x) (x+1)^2

    g(y)
}


fc =
function()
{
    ctr = 0L
    ans = numeric()
    
    g = function(n) {
        ctr <<- ctr + 1L
        ans <<- c(ans, n)
    }

    lapply(g, function(x) if(length(x) > 2) g(x))

    list(ans, ctr)
}
