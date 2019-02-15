

setClass("Shape", contains = "VIRTUAL")
setClass("CenteredShape", representation(pos = "numeric"), contains = "Shape")
setClass("Ellipse", representation(radius = "numeric"), contains = "CenteredShape")
setClass("Circle", representation(radius = "numeric"), contains = "Ellipse")
setClass("Rectangle", representation(dim = "numeric"), contains = "CenteredShape")
setClass("Square", contains = "Rectangle")
setClass("Triangle", contains = "Shape")
