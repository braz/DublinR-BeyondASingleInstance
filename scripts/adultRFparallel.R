library("parallelMap")
library("BatchJobs")
library("mlr")
 
setwd("~/examples")
conf = BatchJobs:::getBatchJobsConf()
conf$cluster.functions = makeClusterFunctionsOpenLava("../batch.tmpl")
storagedir = getwd()
parallelStartBatchJobs(storagedir = storagedir)
 
lrn = makeLearner("classif.randomForest")
adult = read.table("data/adult.test",
                  sep=",",header=F,col.names=c("age", "type_employer", "fnlwgt", "education", 
                  "education_num","marital", "occupation", "relationship", "race","sex",
                  "capital_gain", "capital_loss", "hr_per_week","country", "income"),
                   fill=FALSE,strip.white=T        
)
adult.task = makeClassifTask(data = adult, target = "education")
rdesc = makeResampleDesc("CV", iters = 3)
system.time(res <- resample(lrn, adult.task, rdesc))
res
 
parallelStop()