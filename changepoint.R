#
### -------------------------------------------------------------------###
####---------------------     Changepoint analysis  -------------------###
###--------------------------------------------------------------------###


####created by Autumn I, Jan 2019

## All variables should be combined together into a single csv
## If data needs to be prepped, see the R codes for prepping dive data (prep_data_chgpt_diving) 
##                                and location data (prep_data_chgpt_argos)



# first: clear workspace if necessary
rm(list = ls(all = TRUE)); 


# load packages
library(dplyr)
library(tseries)
library(changepoint)


### -------------------------------------------------------------------###
####---------------------     Load and Prep Data    -------------------###
###--------------------------------------------------------------------###


#Load in the speeds and angles from the location file, and then the dive info

spd_ang <- read.csv("for_changepoint_input/chgpt_input_spd_ang.csv") #all columns good
dur_maxbin_perclong <- read.csv ("for_changepoint_input/duration_wMaxbin_percentlong.csv") #need DUR_61, max_bin and long_dives
max_depths <- read.csv ("for_changepoint_input/MaxDepths_filt.csv") #only need MaxDepth
percent_above_med_bin <- read.csv ("for_changepoint_input/percent_dives_above_Median_bin.csv") #need dive_sum and percent_above_med
TAD <- read.csv ("for_changepoint_input/TAD.csv") #only need Perc_surf_0to5


#format dates and turtle IDs in each sheet, then reduce to only columns needed,
#then match reduced ones by ID and DATE 

spd_ang$date_only <- as.Date(spd_ang$date_only, '%Y-%m-%d', tz='UTC')
spd_ang$id <- as.factor(spd_ang$id)

dur_maxbin_perclong$Date_only <- as.Date(dur_maxbin_perclong$Date_only, '%Y-%m-%d', tz='UTC')
dur_maxbin_perclong$id <- as.factor(dur_maxbin_perclong$id)

max_depths$Date_only <- as.Date(max_depths$Date_only, '%Y-%m-%d', tz='UTC')
max_depths$id <- as.factor(max_depths$id)

percent_above_med_bin$Date_only <- as.Date(percent_above_med_bin$Date_only, '%Y-%m-%d', tz='UTC')
percent_above_med_bin$id <- as.factor(percent_above_med_bin$id)

TAD$Date_only <- as.Date(TAD$DATE_TIME, '%Y-%m-%d', tz='UTC')
TAD$id <- as.factor(TAD$id)


#check that all ids are the same for matching
unique(spd_ang$id) #all ids end in "a" here
unique(dur_maxbin_perclong$id) #no "a"s
unique(max_depths$id) #no "a"s
unique(percent_above_med_bin$id) #no "a"s
unique(TAD$id) #no "a"s

#take out "a"s from spd_ang file
spd_ang$id <- substr(spd_ang$id, 0, 6)

#make sure all have same names of "id" and "Date_only" to match on. 
colnames(spd_ang)[colnames(spd_ang)=="date_only"] <- "Date_only"

#only keep relevant columns and join files based on id and Date_only and 
dur_maxbin_perclong_ss <- dur_maxbin_perclong %>%
  select(id, Date_only, DUR_61, max_bin, long_dives)

max_depth_ss <- max_depths %>%
  select(id, Date_only, MaxDepth)

percent_above_med_bin_ss <- percent_above_med_bin %>%
  select(id, Date_only, dive_sum, percent_above_med)

TAD_ss <- TAD %>%
  select (id, Date_only, Perc_surf_0to5)

m1 <- merge(spd_ang, dur_maxbin_perclong_ss, by = c("id", "Date_only"), all.x = TRUE, all.y = TRUE)
m2 <- merge(m1, max_depth_ss, by = c("id", "Date_only"), all.x = TRUE, all.y = TRUE)
m3 <- merge(m2, percent_above_med_bin_ss, by = c ("id", "Date_only"), all.x = TRUE, all.y = TRUE)
final_merge <- merge(m3, TAD_ss, by = c("id", "Date_only"), all.x = TRUE, all.y = TRUE)

#format final merge 
final_merge$time <- as.POSIXct(as.character(final_merge$Date_only, '%Y-%m-%d'))
final_merge$id <- as.factor (final_merge$id) #"121295" "121296" "121297" "121298" "121299"



### -------------------------------------------------------------------###
####-------------------  Make final files for analysis  -------------------###
###--------------------------------------------------------------------###

#Need to change them into the columns needed only, then remove NAs, so that I retain as much data as possible
# since not all rows have NAs for same data 

####-------------------  Speeds  -------------------###


spd_merge <- na.omit(final_merge[c (1, 3, 12)])

#need the row number per turtle to match up to changepoints later, and an id_row column too
spd_merge$row <- ave(spd_merge$meandaily_kph, spd_merge$id, FUN = seq_along)

spd_merge$id_row <- paste(spd_merge$id, spd_merge$row, sep = "_")

#need a df list for changepoint function later on
df.list_spd <- list(spd_merge[ which(spd_merge$id == "121295"),], spd_merge[ which(spd_merge$id == "121296"),],
                    spd_merge[ which(spd_merge$id == "121297"),], spd_merge[ which(spd_merge$id == "121298"),],
                    spd_merge[ which(spd_merge$id == "121299"),])



####-------------------  Angles  -------------------###

ang_merge <- na.omit(final_merge[c (1, 4, 12)])

ang_merge$row <- ave(ang_merge$maxdaily_ang, ang_merge$id, FUN = seq_along)

ang_merge$id_row <- paste(ang_merge$id, ang_merge$row, sep = "_")

df.list_ang <- list(ang_merge[ which(ang_merge$id == "121295"),], ang_merge[ which(ang_merge$id == "121296"),],
                    ang_merge[ which(ang_merge$id == "121297"),], ang_merge[ which(ang_merge$id == "121298"),],
                    ang_merge[ which(ang_merge$id == "121299"),])




####-------------------  Number of dives in bins > 60 min  -------------------###
 
bin60_merge <- na.omit(final_merge[c (1, 5, 12)])

bin60_merge$row <- ave(bin60_merge$DUR_61, bin60_merge$id, FUN = seq_along)

bin60_merge$id_row <- paste(bin60_merge$id, bin60_merge$row, sep = "_")

df.list_bin60 <- list(bin60_merge[ which(bin60_merge$id == "121295"),], bin60_merge[ which(bin60_merge$id == "121296"),],
                    bin60_merge[ which(bin60_merge$id == "121297"),], bin60_merge[ which(bin60_merge$id == "121298"),],
                    bin60_merge[ which(bin60_merge$id == "121299"),])



####-------------------  Max Dive Duration  -------------------###
 
maxdur_merge <- na.omit(final_merge[c (1, 6, 12)])

maxdur_merge$row <- ave(maxdur_merge$max_bin, maxdur_merge$id, FUN = seq_along)

maxdur_merge$id_row <- paste(maxdur_merge$id, maxdur_merge$row, sep = "_")

df.list_maxdur <- list(maxdur_merge[ which(maxdur_merge$id == "121295"),], maxdur_merge[ which(maxdur_merge$id == "121296"),],
                       maxdur_merge[ which(maxdur_merge$id == "121297"),], maxdur_merge[ which(maxdur_merge$id == "121298"),],
                       maxdur_merge[ which(maxdur_merge$id == "121299"),])


####-------------------  Percent of long dives  -------------------###


long_merge <- na.omit(final_merge[c (1, 7, 12)])

long_merge$row <- ave(long_merge$long_dives, long_merge$id, FUN = seq_along)

long_merge$id_row <- paste(long_merge$id, long_merge$row, sep = "_")

df.list_long <- list(long_merge[ which(long_merge$id == "121295"),], long_merge[ which(long_merge$id == "121296"),],
                     long_merge[ which(long_merge$id == "121297"),], long_merge[ which(long_merge$id == "121298"),],
                     long_merge[ which(long_merge$id == "121299"),])

 
####-------------------  Max Depth  -------------------###

maxdep_merge <- na.omit(final_merge[c (1, 8, 12)])

maxdep_merge$row <- ave(maxdep_merge$MaxDepth, maxdep_merge$id, FUN = seq_along)

maxdep_merge$id_row <- paste(maxdep_merge$id, maxdep_merge$row, sep = "_")

df.list_maxdep <- list(maxdep_merge[ which(maxdep_merge$id == "121295"),], maxdep_merge[ which(maxdep_merge$id == "121296"),],
                       maxdep_merge[ which(maxdep_merge$id == "121297"),], maxdep_merge[ which(maxdep_merge$id == "121298"),],
                       maxdep_merge[ which(maxdep_merge$id == "121299"),])



####-------------------  Total dives per day  -------------------###

tdives_merge <- na.omit(final_merge[c (1, 9, 12)])

tdives_merge$row <- ave(tdives_merge$dive_sum, tdives_merge$id, FUN = seq_along)

tdives_merge$id_row <- paste(tdives_merge$id, tdives_merge$row, sep = "_")

df.list_tdives <- list(tdives_merge[ which(tdives_merge$id == "121295"),], tdives_merge[ which(tdives_merge$id == "121296"),],
                       tdives_merge[ which(tdives_merge$id == "121297"),], tdives_merge[ which(tdives_merge$id == "121298"),],
                       tdives_merge[ which(tdives_merge$id == "121299"),])


####-------------------  Percent above median depth  -------------------###

abvmed_merge <- na.omit(final_merge[c (1, 10, 12)])

abvmed_merge$row <- ave(abvmed_merge$percent_above_med, abvmed_merge$id, FUN = seq_along)

abvmed_merge$id_row <- paste(abvmed_merge$id, abvmed_merge$row, sep = "_")

df.list_abvmed <- list(abvmed_merge[ which(abvmed_merge$id == "121295"),], abvmed_merge[ which(abvmed_merge$id == "121296"),],
                       abvmed_merge[ which(abvmed_merge$id == "121297"),], abvmed_merge[ which(abvmed_merge$id == "121298"),],
                       abvmed_merge[ which(abvmed_merge$id == "121299"),])


####-------------------  Percent time at surface  -------------------###

tas_merge <- na.omit(final_merge[c (1, 11, 12)])

tas_merge$row <- ave(tas_merge$Perc_surf_0to5, tas_merge$id, FUN = seq_along)

tas_merge$id_row <- paste(tas_merge$id, tas_merge$row, sep = "_")

df.list_tas <- list(tas_merge[ which(tas_merge$id == "121295"),], tas_merge[ which(tas_merge$id == "121296"),],
                    tas_merge[ which(tas_merge$id == "121297"),], tas_merge[ which(tas_merge$id == "121298"),],
                    tas_merge[ which(tas_merge$id == "121299"),])



 ### -------------------------------------------------------------------###
 ####---------------------     Determine Distributions  -------------------###
 ###--------------------------------------------------------------------###
 
 
 
#Then, I will need to figure out the data distribution for them, in order to 
#decide if I will use cpt.meanvar or cpt.mean and cpt.var separately

#visual inspection
library(ggpubr)

ggdensity(spd_merge$meandaily_kph[which (spd_merge$id == "121295")])


#then test (if p-value > 0.05, assume normality)
shapiro.test(spd_merge$meandaily_kph[which (spd_merge$id == "121295")]) #p = 0.003, not normal, so need to use cpt.mean and cpt.var separately
shapiro.test(ang_merge$maxdaily_ang [which (ang_merge$id == "121295")]) #NA
shapiro.test(bin60_merge$DUR_61 [which (bin60_merge$id == "121295")]) #p < 0.05
shapiro.test(maxdur_merge$max_bin [which (maxdur_merge$id == "121295")]) # p < 0.05
shapiro.test(long_merge$long_dives [which (long_merge$id == "121295")]) # p < 0.05
shapiro.test(maxdep_merge$MaxDepth [which (maxdep_merge$id == "121295")]) # p < 0.05
##XXXX  needed to change to tdives_merge from tdivesmerge
shapiro.test(tdives_merge$dive_sum [which (tdives_merge$id == "121295")]) # p < 0.05
shapiro.test(abvmed_merge$percent_above_med [which (abvmed_merge$id == "121295")]) # p < 0.05
shapiro.test(tas_merge$Perc_surf_0to5 [which (tas_merge$id == "121295")]) # p < 0.05
#since one of the turtles is not normal in each set, will not check others.



### -------------------------------------------------------------------###
####---------------------     Changepoint Means    -------------------###
###--------------------------------------------------------------------###

TurtleIDs <- c("121295", "121296", "121297", "121298", "121299")

####-------------------  Speeds  -------------------###


#create function to do means changepoint analysis
mcpt_spd <- function(x) {
  cpt.mean(data = x$meandaily_kph, penalty = "Manual", pen.value = 0.06, method = "BinSeg", Q = 10, test.stat =  "CUSUM")
  }

#apply across all turtles
do.mcpt_spd <- lapply(df.list_spd, mcpt_spd)

#print plots of changepoints for evaluation
for(i in 1:length(do.mcpt_spd)){
    plot(do.mcpt_spd[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
  } 
  
#get list of all cpt results across all turtles - associate them with turtle IDs 
cpts_spd <- sapply(1:length(do.mcpt_spd), function(x) {print(do.mcpt_spd[[x]]@cpts)})
names(cpts_spd) <- TurtleIDs

id_cpt_spd <- as.data.frame(cbind(unlist(cpts_spd)))
names(id_cpt_spd) <- "cpts"
id_cpt_spd$id = substr(row.names(id_cpt_spd), 0, 6)
id_cpt_spd$id_row <- paste(id_cpt_spd$id, id_cpt_spd$cpts, sep = "_")


#finally join dataframes to get each changepoint date
spd_mcpts_final <- inner_join (id_cpt_spd, spd_merge, by = "id_row")

#write to csv
write.csv (spd_cpts_final, "spd_cpts_final.csv")





####-------------------  Angles  -------------------###


#create function to do means changepoint analysis

mcpt_ang <- function(x) {
  cpt.mean(data = x$maxdaily_ang, penalty = "Manual", pen.value = 0.06, method = "BinSeg", Q = 10, test.stat =  "CUSUM")
  
}

#apply across all turtles
do.mcpt_ang <- lapply(df.list_ang, mcpt_ang)


#print plots of changepoints for evaluation
for(i in 1:length(do.mcpt_ang)){
  plot(do.mcpt_ang[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
cpts_ang <- sapply(1:length(do.mcpt_ang), function(x) {print(do.mcpt_ang[[x]]@cpts)})

id_cpt_ang <- as.data.frame(cbind(unlist(cpts_ang)))
names(id_cpt_ang) <- TurtleIDs
id_cpt_ang <- as.data.frame(cbind(unlist(id_cpt_ang)))
names(id_cpt_ang) <- "cpts"

id_cpt_ang$id = substr(row.names(id_cpt_ang), 0, 6)
id_cpt_ang$id_row <- paste(id_cpt_ang$id, id_cpt_ang$cpts, sep = "_")


#finally join dataframes to get each changepoint date
ang_mcpts_final <- inner_join (id_cpt_ang, ang_merge, by = "id_row")

#write to csv
write.csv (ang_mcpts_final, "ang_mcpts_final.csv")




####-------------------  Number of dives in bins > 60 min  -------------------###

#create function to do means changepoint analysis
mcpt_bin60 <- function(x) {
  cpt.mean(data = x$DUR_61, penalty = "Manual", pen.value = 0.06, method = "BinSeg", Q = 10, test.stat =  "CUSUM")
  
}

#apply across all turtles
do.mcpt_bin60 <- lapply(df.list_bin60, mcpt_bin60)


#print plots of changepoints for evaluation
for(i in 1:length(do.mcpt_bin60)){
  plot(do.mcpt_bin60[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
cpts_bin60 <- sapply(1:length(do.mcpt_bin60), function(x) {print(do.mcpt_bin60[[x]]@cpts)})


id_cpt_bin60 <- as.data.frame(cbind(unlist(cpts_bin60)))
names(id_cpt_bin60) <- TurtleIDs
id_cpt_bin60 <- as.data.frame(cbind(unlist(id_cpt_bin60)))
names(id_cpt_bin60) <- "cpts"

id_cpt_bin60$id = substr(row.names(id_cpt_bin60), 0, 6)
id_cpt_bin60$id_row <- paste(id_cpt_bin60$id, id_cpt_bin60$cpts, sep = "_")


#finally join dataframes to get each changepoint date
bin60_mcpts_final <- inner_join (id_cpt_bin60, bin60_merge, by = "id_row")

#write to csv
write.csv (bin60_cpts_final, "bin60_cpts_final.csv")




####-------------------  Max Dive Duration  -------------------###

#create function to do means changepoint analysis

mcpt_maxdur <- function(x) {
  cpt.mean(data = x$max_bin, penalty = "Manual", pen.value = 0.06, method = "BinSeg", Q = 10, test.stat =  "CUSUM")
  
}

#apply across all turtles
do.mcpt_maxdur <- lapply(df.list_maxdur, mcpt_maxdur)

#print plots of changepoints for evaluation
for(i in 1:length(do.mcpt_maxdur)){
  plot(do.mcpt_maxdur[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
cpts_maxdur <- sapply(1:length(do.mcpt_maxdur), function(x) {print(do.mcpt_maxdur[[x]]@cpts)})
names(cpts_maxdur) <- TurtleIDs

id_cpt_maxdur <- as.data.frame(cbind(unlist(cpts_maxdur)))
names(id_cpt_maxdur) <- "cpts"


id_cpt_maxdur$id = substr(row.names(id_cpt_maxdur), 0, 6)
id_cpt_maxdur$id_row <- paste(id_cpt_maxdur$id, id_cpt_maxdur$cpts, sep = "_")


#finally join dataframes to get each changepoint date
maxdur_mcpts_final <- inner_join (id_cpt_maxdur, maxdur_merge, by = "id_row")

#write to csv
write.csv (maxdur_cpts_final, "maxdur_cpts_final.csv")


####-------------------  Percent of long dives  -------------------###

#create function to do means changepoint analysis

mcpt_long <- function(x) {
  cpt.mean(data = x$long_dives, penalty = "Manual", pen.value = 0.06, method = "BinSeg", Q = 10, test.stat =  "CUSUM")
  
}

#apply across all turtles
do.mcpt_long <- lapply(df.list_long, mcpt_long)

#print plots of changepoints for evaluation
for(i in 1:length(do.mcpt_long)){
  plot(do.mcpt_long[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
cpts_long <- sapply(1:length(do.mcpt_long), function(x) {print(do.mcpt_long[[x]]@cpts)})

id_cpt_long <- as.data.frame(cbind(unlist(cpts_long)))
names(id_cpt_long) <- TurtleIDs
id_cpt_long <- as.data.frame(cbind(unlist(id_cpt_long)))
names(id_cpt_long) <- "cpts"

id_cpt_long$id = substr(row.names(id_cpt_long), 0, 6)
id_cpt_long$id_row <- paste(id_cpt_long$id, id_cpt_long$cpts, sep = "_")


#finally join dataframes to get each changepoint date
long_mcpts_final <- inner_join (id_cpt_long, long_merge, by = "id_row")

#write to csv
write.csv (long_cpts_final, "long_cpts_final.csv")


####-------------------  Max Depth  -------------------###


#create function to do means changepoint analysis

mcpt_maxdep <- function(x) {
  cpt.mean(data = x$MaxDepth, penalty = "Manual", pen.value = 0.06, method = "BinSeg", Q = 10, test.stat =  "CUSUM")
      
  }

#apply across all turtles
do.mcpt_maxdep <- lapply(df.list_maxdep, mcpt_maxdep)

#print plots of changepoints for evaluation
for(i in 1:length(do.mcpt_maxdep)){
  plot(do.mcpt_maxdep[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
cpts_maxdep <- sapply(1:length(do.mcpt_maxdep), function(x) {print(do.mcpt_maxdep[[x]]@cpts)})

id_cpt_maxdep <- as.data.frame(cbind(unlist(cpts_maxdep)))
names(id_cpt_maxdep) <- TurtleIDs
id_cpt_maxdep <- as.data.frame(cbind(unlist(id_cpt_maxdep)))
names(id_cpt_maxdep) <- "cpts"

id_cpt_maxdep$id = substr(row.names(id_cpt_maxdep), 0, 6)
id_cpt_maxdep$id_row <- paste(id_cpt_maxdep$id, id_cpt_maxdep$cpts, sep = "_")


#finally join dataframes to get each changepoint date
maxdep_mcpts_final <- inner_join (id_cpt_maxdep, maxdep_merge, by = "id_row")

#write to csv
write.csv (maxdep_cpts_final, "maxdep_cpts_final.csv")


####-------------------  Total dives per day  -------------------###

#create function to do means changepoint analysis

mcpt_tdives <- function(x) {
  cpt.mean(data = x$dive_sum, penalty = "Manual", pen.value = 0.06, method = "BinSeg", Q = 10, test.stat =  "CUSUM")
  
}

#apply across all turtles
do.mcpt_tdives <- lapply(df.list_tdives, mcpt_tdives)

#print plots of changepoints for evaluation
for(i in 1:length(do.mcpt_tdives)){
  plot(do.mcpt_tdives[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
cpts_tdives <- sapply(1:length(do.mcpt_tdives), function(x) {print(do.mcpt_tdives[[x]]@cpts)})

id_cpt_tdives <- as.data.frame(cbind(unlist(cpts_tdives)))
names(id_cpt_tdives) <- TurtleIDs
id_cpt_tdives <- as.data.frame(cbind(unlist(id_cpt_tdives)))
names(id_cpt_tdives) <- "cpts"


id_cpt_tdives$id = substr(row.names(id_cpt_tdives), 0, 6)
id_cpt_tdives$id_row <- paste(id_cpt_tdives$id, id_cpt_tdives$cpts, sep = "_")


#finally join dataframes to get each changepoint date
tdives_mcpts_final <- inner_join (id_cpt_tdives, tdives_merge, by = "id_row")

#write to csv
write.csv (tdives_cpts_final, "tdives_cpts_final.csv")


####-------------------  Percent above median depth  -------------------###

#changepoint function
mcpt_abvmed <- function(x) {
  cpt.mean(data = x$percent_above_med, penalty = "Manual", pen.value = 0.06, method = "BinSeg", Q = 10, test.stat =  "CUSUM")
  
}

#apply across all turtles
do.mcpt_abvmed <- lapply(df.list_abvmed, mcpt_abvmed)

#print plots of changepoints for evaluation
for(i in 1:length(do.mcpt_abvmed)){
  plot(do.mcpt_abvmed[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
cpts_abvmed <- sapply(1:length(do.mcpt_abvmed), function(x) {print(do.mcpt_abvmed[[x]]@cpts)})
names(cpts_abvmed) <- TurtleIDs

id_cpt_abvmed <- as.data.frame(cbind(unlist(cpts_abvmed)))
names(id_cpt_abvmed) <- "cpts"
id_cpt_abvmed$id = substr(row.names(id_cpt_abvmed), 0, 6)
id_cpt_abvmed$id_row <- paste(id_cpt_abvmed$id, id_cpt_abvmed$cpts, sep = "_")


#finally join dataframes to get each changepoint date
abvmed_mcpts_final <- inner_join (id_cpt_abvmed, abvmed_merge, by = "id_row")

#write to csv
write.csv (abvmed_mcpts_final, "abvmed_cpts_final.csv")



####-------------------  Percent time at surface  -------------------###

#create function to do means changepoint analysis

mcpt_tas <- function(x) {
  cpt.mean(data = x$Perc_surf_0to5, penalty = "Manual", pen.value = 0.06, method = "BinSeg", Q = 10, test.stat =  "CUSUM")
  
}

#apply across all turtles
do.mcpt_tas <- lapply(df.list_tas, mcpt_tas)

#print plots of changepoints for evaluation
for(i in 1:length(do.mcpt_tas)){
  plot(do.mcpt_tas[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
cpts_tas <- sapply(1:length(do.mcpt_tas), function(x) {print(do.mcpt_tas[[x]]@cpts)})

id_cpt_tas <- as.data.frame(cbind(unlist(cpts_tas)))
names(id_cpt_tas) <- TurtleIDs
id_cpt_tas <- as.data.frame(cbind(unlist(id_cpt_tas)))
names(id_cpt_tas) <- "cpts"


id_cpt_tas$id = substr(row.names(id_cpt_tas), 0, 6)
id_cpt_tas$id_row <- paste(id_cpt_tas$id, id_cpt_tas$cpts, sep = "_")


#finally join dataframes to get each changepoint date
tas_mcpts_final <- inner_join (id_cpt_tas, tas_merge, by = "id_row")

#write to csv
write.csv (tas_mcpts_final, "tas_cpts_final.csv")


### -------------------------------------------------------------------###
####---------------------     Changepoint Variance  -------------------###
###--------------------------------------------------------------------###

####-------------------  Speeds  -------------------###


#create function to do means changepoint analysis

vcpt_spd <- function(x) {
  cpt.var(data = x$meandaily_kph, penalty = "Manual", pen.value = "log(2*log(n))", method = "BinSeg", Q = 10, test.stat =  "CSS")
  
}

#apply across all turtles
do.vcpt_spd <- lapply(df.list_spd, vcpt_spd)


#print plots of changepoints for evaluation
for(i in 1:length(do.vcpt_spd)){
  plot(do.vcpt_spd[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
vcpts_spd <- sapply(1:length(do.vcpt_spd), function(x) {print(do.vcpt_spd[[x]]@cpts)})
names(vcpts_spd) <- TurtleIDs

id_vcpt_spd <- as.data.frame(cbind(unlist(vcpts_spd)))
names(id_vcpt_spd) <- "cpts"
id_vcpt_spd$id = substr(row.names(id_vcpt_spd), 0, 6)
id_vcpt_spd$id_row <- paste(id_vcpt_spd$id, id_vcpt_spd$cpts, sep = "_")


#finally join dataframes to get each changepoint date
spd_vcpts_final <- inner_join (id_vcpt_spd, spd_merge, by = "id_row")

#write to csv
write.csv (spd_vcpts_final, "spd_vcpts_final.csv")




####-------------------  Angles  -------------------###


#create function to do means changepoint analysis


vcpt_ang <- function(x) {
  cpt.var(data = x$maxdaily_ang, penalty = "Manual", pen.value = "log(2*log(n))", method = "BinSeg", Q = 10, test.stat =  "CSS")
  
}

#apply across all turtles
do.vcpt_ang <- lapply(df.list_ang, vcpt_ang)

#print plots of changepoints for evaluation
for(i in 1:length(do.vcpt_ang)){
  plot(do.vcpt_ang[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
vcpts_ang <- sapply(1:length(do.vcpt_ang), function(x) {print(do.vcpt_ang[[x]]@cpts)})
names(vcpts_ang) <- TurtleIDs

id_vcpt_ang <- as.data.frame(cbind(unlist(vcpts_ang)))
names(id_vcpt_ang) <- "cpts"
id_vcpt_ang$id = substr(row.names(id_vcpt_ang), 0, 6)
id_vcpt_ang$id_row <- paste(id_vcpt_ang$id, id_vcpt_ang$cpts, sep = "_")


#finally join dataframes to get each changepoint date
ang_vcpts_final <- inner_join (id_vcpt_ang, ang_merge, by = "id_row")

#write to csv
write.csv (ang_vcpts_final, "ang_vcpts_final.csv")

####-------------------  Number of dives in bins > 60 min  -------------------###

#create function to do means changepoint analysis

vcpt_bin60 <- function(x) {
  cpt.var(data = x$DUR_61, penalty = "Manual", pen.value = "log(2*log(n))", method = "BinSeg", Q = 10, test.stat =  "CSS")
  
}

#apply across all turtles
do.vcpt_bin60 <- lapply(df.list_bin60, vcpt_bin60)

#print plots of changepoints for evaluation
for(i in 1:length(do.vcpt_bin60)){
  plot(do.vcpt_bin60[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
vcpts_bin60 <- sapply(1:length(do.vcpt_bin60), function(x) {print(do.vcpt_bin60[[x]]@cpts)})
names(vcpts_bin60) <- TurtleIDs

id_vcpt_bin60 <- as.data.frame(cbind(unlist(vcpts_bin60)))
names(id_vcpt_bin60) <- "cpts"
id_vcpt_bin60$id = substr(row.names(id_vcpt_bin60), 0, 6)
id_vcpt_bin60$id_row <- paste(id_vcpt_bin60$id, id_vcpt_bin60$cpts, sep = "_")


#finally join dataframes to get each changepoint date
bin60_vcpts_final <- inner_join (id_vcpt_bin60, bin60_merge, by = "id_row")

#write to csv
write.csv (bin60_vcpts_final, "bin60_vcpts_final.csv")


####-------------------  Max Dive Duration  -------------------###

#create function to do means changepoint analysis

vcpt_maxdur <- function(x) {
  cpt.var(data = x$max_bin, penalty = "Manual", pen.value = "log(2*log(n))", method = "BinSeg", Q = 10, test.stat =  "CSS")
  
}

#apply across all turtles
do.vcpt_maxdur <- lapply(df.list_maxdur, vcpt_maxdur)

#print plots of changepoints for evaluation
for(i in 1:length(do.vcpt_maxdur)){
  plot(do.vcpt_maxdur[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
vcpts_maxdur <- sapply(1:length(do.vcpt_maxdur), function(x) {print(do.vcpt_maxdur[[x]]@cpts)})
names(vcpts_maxdur) <- TurtleIDs

id_vcpt_maxdur <- as.data.frame(cbind(unlist(vcpts_maxdur)))
names(id_vcpt_maxdur) <- "cpts"
id_vcpt_maxdur$id = substr(row.names(id_vcpt_maxdur), 0, 6)
id_vcpt_maxdur$id_row <- paste(id_vcpt_maxdur$id, id_vcpt_maxdur$cpts, sep = "_")


#finally join dataframes to get each changepoint date
maxdur_vcpts_final <- inner_join (id_vcpt_maxdur, maxdur_merge, by = "id_row")

#write to csv
write.csv (maxdur_vcpts_final, "maxdur_vcpts_final.csv")


####-------------------  Percent of long dives  -------------------###

#create function to do means changepoint analysis

vcpt_long <- function(x) {
  cpt.var(data = x$long_dives, penalty = "Manual", pen.value = "log(2*log(n))", method = "BinSeg", Q = 10, test.stat =  "CSS")
  
}

#apply across all turtles
do.vcpt_long <- lapply(df.list_long, vcpt_long)

#print plots of changepoints for evaluation
for(i in 1:length(do.vcpt_long)){
  plot(do.vcpt_long[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
vcpts_long <- sapply(1:length(do.vcpt_long), function(x) {print(do.vcpt_long[[x]]@cpts)})
names(vcpts_long) <- TurtleIDs

id_vcpt_long <- as.data.frame(cbind(unlist(vcpts_long)))
names(id_vcpt_long) <- "cpts"
id_vcpt_long$id = substr(row.names(id_vcpt_long), 0, 6)
id_vcpt_long$id_row <- paste(id_vcpt_long$id, id_vcpt_long$cpts, sep = "_")


#finally join dataframes to get each changepoint date
long_vcpts_final <- inner_join (id_vcpt_long, long_merge, by = "id_row")

#write to csv
write.csv (long_vcpts_final, "long_vcpts_final.csv")



####-------------------  Max Depth  -------------------###


#create function to do means changepoint analysis

vcpt_maxdep <- function(x) {
  cpt.var(data = x$MaxDepth, penalty = "Manual", pen.value = "log(2*log(n))", method = "BinSeg", Q = 10, test.stat =  "CSS")
  
}

#apply across all turtles
do.vcpt_maxdep <- lapply(df.list_maxdep, vcpt_maxdep)

#print plots of changepoints for evaluation
for(i in 1:length(do.vcpt_maxdep)){
  plot(do.vcpt_maxdep[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
vcpts_maxdep <- sapply(1:length(do.vcpt_maxdep), function(x) {print(do.vcpt_maxdep[[x]]@cpts)})
names(vcpts_maxdep) <- TurtleIDs

id_vcpt_maxdep <- as.data.frame(cbind(unlist(vcpts_maxdep)))
names(id_vcpt_maxdep) <- "cpts"
id_vcpt_maxdep$id = substr(row.names(id_vcpt_maxdep), 0, 6)
id_vcpt_maxdep$id_row <- paste(id_vcpt_maxdep$id, id_vcpt_maxdep$cpts, sep = "_")


#finally join dataframes to get each changepoint date
maxdep_vcpts_final <- inner_join (id_vcpt_maxdep, maxdep_merge, by = "id_row")

#write to csv
write.csv (maxdep_vcpts_final, "maxdep_vcpts_final.csv")




####-------------------  Total dives per day  -------------------###

#create function to do means changepoint analysis

vcpt_tdives <- function(x) {
  cpt.var(data = x$dive_sum, penalty = "Manual", pen.value = "log(2*log(n))", method = "BinSeg", Q = 10, test.stat =  "CSS")
  
}

#apply across all turtles
do.vcpt_tdives <- lapply(df.list_tdives, vcpt_tdives)

#print plots of changepoints for evaluation
for(i in 1:length(do.vcpt_tdives)){
  plot(do.vcpt_tdives[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
vcpts_tdives <- sapply(1:length(do.vcpt_tdives), function(x) {print(do.vcpt_tdives[[x]]@cpts)})
names(vcpts_tdives) <- TurtleIDs

id_vcpt_tdives <- as.data.frame(cbind(unlist(vcpts_tdives)))
names(id_vcpt_tdives) <- "cpts"
id_vcpt_tdives$id = substr(row.names(id_vcpt_tdives), 0, 6)
id_vcpt_tdives$id_row <- paste(id_vcpt_tdives$id, id_vcpt_tdives$cpts, sep = "_")


#finally join dataframes to get each changepoint date
tdives_vcpts_final <- inner_join (id_vcpt_tdives, tdives_merge, by = "id_row")

#write to csv
write.csv (tdives_vcpts_final, "tdives_vcpts_final.csv")




####-------------------  Percent above median depth  -------------------###

vcpt_abvmed <- function(x) {
  cpt.var(data = x$percent_above_med, penalty = "Manual", pen.value = "log(2*log(n))", method = "BinSeg", Q = 10, test.stat =  "CSS")
  
}

#apply across all turtles
do.vcpt_abvmed <- lapply(df.list_abvmed, vcpt_abvmed)

#print plots of changepoints for evaluation
for(i in 1:length(do.vcpt_abvmed)){
  plot(do.vcpt_abvmed[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
vcpts_abvmed <- sapply(1:length(do.vcpt_abvmed), function(x) {print(do.vcpt_abvmed[[x]]@cpts)})
names(vcpts_abvmed) <- TurtleIDs

id_vcpt_abvmed <- as.data.frame(cbind(unlist(vcpts_abvmed)))
names(id_vcpt_abvmed) <- "cpts"
id_vcpt_abvmed$id = substr(row.names(id_vcpt_abvmed), 0, 6)
id_vcpt_abvmed$id_row <- paste(id_vcpt_abvmed$id, id_vcpt_abvmed$cpts, sep = "_")


#finally join dataframes to get each changepoint date
abvmed_vcpts_final <- inner_join (id_vcpt_abvmed, abvmed_merge, by = "id_row")

#write to csv
write.csv (abvmed_vcpts_final, "abvmed_vcpts_final.csv")



####-------------------  Percent time at surface  -------------------###

#create function to do means changepoint analysis

vcpt_tas <- function(x) {
  cpt.var(data = x$Perc_surf_0to5, penalty = "Manual", pen.value = "log(2*log(n))", method = "BinSeg", Q = 10, test.stat =  "CSS")
  
}

#apply across all turtles
do.vcpt_tas <- lapply(df.list_tas, vcpt_tas)

#print plots of changepoints for evaluation
for(i in 1:length(do.vcpt_tas)){
  plot(do.vcpt_tas[[i]], type = "l", xlab = "Index", cpt.width = 4, main = i)
} 

#get list of all cpt results across all turtles - associate them with turtle IDs 
vcpts_tas <- sapply(1:length(do.vcpt_tas), function(x) {print(do.vcpt_tas[[x]]@cpts)})
names(vcpts_tas) <- TurtleIDs

id_vcpt_tas <- as.data.frame(cbind(unlist(vcpts_tas)))
names(id_vcpt_tas) <- "cpts"
id_vcpt_tas$id = substr(row.names(id_vcpt_tas), 0, 6)
id_vcpt_tas$id_row <- paste(id_vcpt_tas$id, id_vcpt_tas$cpts, sep = "_")


#finally join dataframes to get each changepoint date
tas_vcpts_final <- inner_join (id_vcpt_tas, tas_merge, by = "id_row")

#write to csv
write.csv (tas_vcpts_final, "tas_vcpts_final.csv")


### -------------------------------------------------------------------###
####------------    Combine Changepoints per turtle  -------------------###
###--------------------------------------------------------------------###

#combine all cpts, keeping ID of what dataframe/analysis is came from

ALL_CPTS <- bind_rows("spd_m" = spd_mcpts_final, "ang_m" = ang_mcpts_final, "bin60_m" = bin60_mcpts_final, "maxdur_m" = maxdur_mcpts_final, 
          "long_m" = long_mcpts_final, "maxdep_m" = maxdep_mcpts_final, "tdives_m" = tdives_mcpts_final, 
          "abvmed_m" = abvmed_mcpts_final, "tas_m" = tas_mcpts_final, "spd_v" = spd_vcpts_final, 
          "ang_v" = ang_vcpts_final, "bin60_v" = bin60_vcpts_final, "maxdur_v" = maxdur_vcpts_final, 
          "long_v" =long_vcpts_final, "maxdep_v" = maxdep_vcpts_final, "tdives_v" =tdives_vcpts_final,
          "abvmed_v" = abvmed_vcpts_final, "tas_v" = tas_vcpts_final, .id = "groups")


#create turtle_date column

ALL_CPTS$turt_date <- paste(ALL_CPTS$id.x, ALL_CPTS$time, sep = "_")

#aggregate by turtle and date - count rows (Do histogram too?)
count_cpts <- ALL_CPTS %>% group_by(turt_date) %>% mutate(count = n())



#write counts to csv
write.csv (count_cpts, "count_cpts.csv")

hist(count_cpts$count)

