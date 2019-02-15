
a = read.csv("A.csv")
b = read.table("B.txt")

a$x + b$y

files = list.files("Data", pattern = "\\.csv$", full.names = TRUE)
tmp = lapply(files, read.csv)

d = do.call(rbind, tmp)


