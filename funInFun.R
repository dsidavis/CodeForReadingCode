
f =
function(x, n)
{

    y = cumsum(x)
    g = function(z) {
        z + n
    }

    g(y)
}


