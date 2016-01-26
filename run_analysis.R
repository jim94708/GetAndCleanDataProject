
library(sqldf)
library(dplyr)

#Read in test data
testdata<-read.table("./data/UCI/test/X_test.txt")

#Add column names to test data
vars<-read.table("./data/UCI/features.txt", colClasses = "character")
vars<-vars[,2]
colnames(testdata)<-vars

#Add ID, Subject, and Activity columns to test data
tesub<-read.table("./data/UCI/test/subject_test.txt", colClasses = "integer")
teact<-read.table("./data/UCI/test/y_test.txt", colClasses = "integer")
testdata<-cbind(tesub, testdata)
testdata<-cbind(teact, testdata)
ids<-(1:nrow(testdata))
testdata<-cbind(ids, testdata)
colnames(testdata)[1]<-"ID"
colnames(testdata)[2]<-"Activity"
colnames(testdata)[3]<-"Subject"
rownames(testdata)<-testdata$ID
rm("tesub", "teact", "ids")

#Read in train data
traindata<-read.table("./data/UCI/train/X_train.txt")

#Add column names to train data
colnames(traindata)<-vars

#Add ID, Subject and Activity columns to train data
trsub<-read.table("./data/UCI/train/subject_train.txt", colClasses = "integer")
tract<-read.table("./data/UCI/train/y_train.txt", colClasses = "integer")
traindata<-cbind(trsub, traindata)
traindata<-cbind(tract, traindata)
ids<-(nrow(testdata)+1:nrow(traindata))
traindata<-cbind(ids, traindata)
colnames(traindata)[1]<-"ID"
colnames(traindata)[2]<-"Activity"
colnames(traindata)[3]<-"Subject"
rownames(traindata)<-traindata$ID
rm("trsub", "tract", "ids", "vars")

#Append training and test data sets
alldata<-rbind(testdata, traindata, make.row.names = FALSE)

#Identify columns of interest in the combined data set
cols<-grep("-mean\\(\\)|-std\\(\\)", colnames(traindata))
SelectedCols<-alldata[,c(1, 2, 3,cols)] 

#tidy up a bit to save memory
rm("testdata", "traindata", "alldata")

#replace the activity numbers with the activity names
dtActNames<-read.table("./data/UCI/activity_labels.txt", stringsAsFactors = FALSE)
colnames(dtActNames)<-c("ActivityID", "ActivityLabel")

sqlString<-"Select s.*, a.ActivityLabel
            From SelectedCols s 
              Inner join dtActNames a on s.Activity = a.ActivityID"
newDF = sqldf(sqlString)

#clean up the variable names for punctuation
colnames(newDF)<-gsub("-mean\\(\\)-", "Mean", colnames(newDF))
colnames(newDF)<-gsub("-std\\(\\)-", "Std", colnames(newDF))
colnames(newDF)<-gsub("-mean\\(\\)", "Mean", colnames(newDF))
colnames(newDF)<-gsub("-std\\(\\)", "Std", colnames(newDF))

#aggregate all variables by activity name and subject id
TidyData<-aggregate(newDF, by=list(newDF$ActivityLabel, newDF$Subject), FUN=mean, na.rm=TRUE)
TidyData<-TidyData[,c(1,2,6:71)]
colnames(TidyData)[c(1,2)]<-c("Activity", "Subject")

#cleanup unnecessary objects
rm("dtActNames", "SelectedCols")
