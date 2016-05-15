## Install package
sapply("data.table", require, character.only=TRUE, quietly=TRUE)
sapply("sqldf", require, character.only=TRUE, quietly=TRUE)

## Set working directory and confirm the location

setwd("C:/Users/cam7de/Desktop/Coursera/05152016")
getwd()

## Download .zip file and choose name for the file

loc_dir <- getwd()
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
file_name <- "Dataset.zip"
if (!file.exists(loc_dir)) {dir.create(loc_dir)}
download.file(url, file.path(loc_dir, file_name))

## Unzip the file

unzip("Dataset.zip")

## File is unzipped and directory is named 'UCI HAR Dataset'. 
## Need to set this new directory and then list all files contained within. Recursive because there are other folders within it.

proj_dir <- file.path(loc_dir, "UCI HAR Dataset")
list.files(proj_dir, recursive=TRUE)

## Per instructions, only analyze the training and test sets.
## 1. Merges the training and the test sets to create one data set.

## First, need to read all the text files into data sets.

SubjectTrain <- read.table(file.path(proj_dir, "train", "subject_train.txt"))
SubjectTest  <- read.table(file.path(proj_dir, "test" , "subject_test.txt" ))

ActivityTrain <- read.table(file.path(proj_dir, "train", "Y_train.txt"))
ActivityTest  <- read.table(file.path(proj_dir, "test" , "Y_test.txt" ))

Train <- read.table(file.path(proj_dir, "train", "X_train.txt"))
Test  <- read.table(file.path(proj_dir, "test" , "X_test.txt" ))

## First concatenate the subject list together with row bind

Subject <- rbind(SubjectTrain, SubjectTest)
setnames(Subject, "V1", "subject")

Activity <- rbind(ActivityTrain, ActivityTest)
setnames(Activity, "V1", "act_num")

main_data <- rbind(Train, Test)

## Now, combine datasets and keep the name main_data. Set key.

main_data <- data.table(cbind(cbind(Subject, Activity), main_data))
setkey(main_data, subject, act_num)

## Features txt file explains the variables for mean, st dev, and others

Features <- read.table(file.path(proj_dir, "features.txt"))
setnames(Features, names(Features), c("feature_num", "feature_name"))

## Subset the ones of interest

Features <- Features[grepl("mean\\(\\)|std\\(\\)", Features$feature_name),]

## Add new variable to mimic the variable names in the main data 

Features$feature_cd <- paste("V",Features$feature_num, sep = "")

## Pull from main data according to subset of important variables above

main_data_subvars <- c(key(main_data), Features$feature_cd)
main_data_sub <- main_data[, main_data_subvars, with=FALSE]

## Find activity names

ActivityNames <- read.table(file.path(proj_dir, "activity_labels.txt"))
setnames(ActivityNames, names(ActivityNames), c("act_num", "act_nm"))

## Add activity names to main data sub and then set key

main_data_sub <- merge(main_data_sub, ActivityNames, by="act_num", all.x=TRUE)
setkey(main_data_sub, subject, act_num, act_nm)

## Reshape data set to by subj, act num/nm, feature cd so it will be less variables but more obs

main_data_sub <- data.table(melt(main_data_sub, key(main_data_sub), variable.name="feature_cd"))

## Add feature name via SQL.

Features_tbl <- data.table(Features)
main_data_sub <- 
sqldf(
'select
m.*,
feature_name
from main_data_sub m
  left join Features_tbl f on m.feature_cd = f.feature_cd
')

## Confirm the important char var's are factors

class(main_data_sub$act_nm)
class(main_data_sub$feature_name)

## Using SQL to answer part 5
## From the data set in step 4, creates a second, independent tidy data 
## set with the average of each variable for each activity and each subject.

summary_data <-
sqldf(
'select
act_nm,
subject,
feature_name,
avg(value) as average_value
from main_data_sub
group by 1,2,3
')

## Outputting summary dataset

output_name <- file.path(loc_dir, "Coursera_Module_Project.txt")
write.table(summary_data, output_name, quote = FALSE, sep = "\t", row.names = FALSE)

## Getting codebook references
save(summary_data, file="summary_data.RData")
save(ActivityNames, file="ActivityNames.RData")
save(Features_tbl, file="Features_tbl.RData")

