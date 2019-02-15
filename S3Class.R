
f =
function(file)
{
    d = read.csv(file)
    class(d) = c("SpatialTimeSeries", class(d))
    d
}


plot.SpatialTimeSeries =
function(x, y, ...)
{
    par(mfrow = c(3, 1))
    plot(x$time)
    # ....
}
