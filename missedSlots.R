

setClass("foo", representation(x = "integer", y = "logical"))
setClass("bar", representation(top = "numeric", contains = "foo"))

f =
function()
{
    a = new("foo")
    a@x = 1L
    a@z = TRUE
    a
}


s = findSlotAccess(f)

# Discard the within objects and just get the names of the slots being accessed
s = unlist(s)

# Compare to all of the classes of interest.
w = s %in% c(slotNames(getClass("foo")), slotNames(getClass("bar")))

# Possible erroneous slot name(s)
s[!w]
