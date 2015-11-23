library(kernlab)
library(caret)
library(mlr)

library("BatchJobs")
library(parallel)

setwd("~/examples")

conf = BatchJobs:::getBatchJobsConf()
conf$cluster.functions = makeClusterFunctionsOpenLava("../batch.tmpl")
storagedir = getwd()
parallelStartBatchJobs(storagedir = storagedir)

data(GermanCredit)
GermanCredit <- GermanCredit[, -nearZeroVar(GermanCredit)]
GermanCredit$CheckingAccountStatus.lt.0 <- NULL
GermanCredit$SavingsAccountBonds.lt.100 <- NULL
GermanCredit$EmploymentDuration.lt.1 <- NULL
GermanCredit$EmploymentDuration.Unemployed <- NULL
GermanCredit$Personal.Male.Married.Widowed <- NULL
GermanCredit$Property.Unknown <- NULL
GermanCredit$Housing.ForFree <- NULL

set.seed(100)
inTrain <- createDataPartition(GermanCredit$Class, p = .8)[[1]]
GermanCreditTrain <- GermanCredit[inTrain, ]
GermanCreditTest  <- GermanCredit[-inTrain, ]

task = makeClassifTask(id="gc", data=GermanCreditTrain, target="Class")
normalizeFeatures(task, method="standardize")
lrn.svm = makeLearner("classif.ksvm")
lrn.glm = makeLearner("classif.binomial")

rdesc = makeResampleDesc("RepCV", folds=10, reps=5, predict="both")

## estimate sigma
set.seed(231)
sigDist = sigest(Class ~ ., data=GermanCreditTrain, frac=1)

trans = function(x) 2^x
ps = makeParamSet(makeNumericParam("C", lower=-2, upper=4, trafo=trans),
                  makeDiscreteParam("sigma", values=c(as.numeric(sigDist[2]))),
                  makeDiscreteParam("kernel", values=c("rbfdot")))
ctrl = makeTuneControlGrid(resolution=c(C=7L)) # adjust increment
# check grid
grid <- generateGridDesign(ps, resolution=c(C=7))
# change to transformed values
grid$C = trans(grid$C)
grid$sigma = round(as.numeric(as.character(grid$sigma)),4)
set.seed(123457)
res = tuneParams(lrn.svm, task=task, resampling=rdesc, par.set=ps, control=ctrl, show.info=FALSE)
res.opt.grid <- as.data.frame(res$opt.path)
res.opt.grid$C = trans(res.opt.grid$C)
res.opt.grid$sigma = round(as.numeric(as.character(res.opt.grid$sigma)),4)

# update svm learner
lrn.svm = setHyperPars(lrn.svm, par.vals=res$x)

set.seed(123457)
res.bench = benchmark(learners=list(lrn.svm,lrn.glm), task=task, resampling=rdesc)
res.bench

system.time(res <- resample(lrn, task, rdesc))
res

parallelStop()