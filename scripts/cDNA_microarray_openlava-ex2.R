#!/usr/bin/env Rscript
#
library("BatchJobs")
library("parallelMap")
library("parallel")
library("knitr")
library("Biobase")
library("Hiiragi2013")
library("glmnet")
library("mlr")

setwd("~/examples")
 
conf = BatchJobs:::getBatchJobsConf()
conf$cluster.functions = makeClusterFunctionsOpenLava("../batch.tmpl")
storagedir = getwd()
parallelStartBatchJobs(storagedir = storagedir)

data( "x", package = "Hiiragi2013" )
rowV <- data.frame( v = rowVars(exprs(x)) )
selectionThreshold <- 10^(-0.5)
selectedFeatures  <- ( rowV$v > selectionThreshold )
embryoSingleCells <- data.frame( t(exprs(x)[selectedFeatures, ]), check.names = TRUE )
embryoSingleCells$tg <- factor( ifelse( x$Embryonic.day == "E3.25", "E3.25", "other") )
with( embryoSingleCells, table( tg ) )

start.time <- Sys.time()
task <- makeClassifTask( id = "Hiiragi", data = embryoSingleCells, target = "tg" )
lrn = makeLearner( "classif.glmnet", predict.type = "prob" )
rdesc <- makeResampleDesc( method = "CV", stratify = TRUE, iters = 12 )

tuningLrn <- makeTuneWrapper(lrn, 
  resampling = makeResampleDesc("CV", iters = 10,  stratify = TRUE), 
  par.set = makeParamSet(makeNumericParam("s", lower = 0.001, upper = 0.1)), 
  control = makeTuneControlGrid(resolution = 6) )
r2 <- resample(learner = tuningLrn, task = task, resampling = rdesc )
system.time(res <- resample(lrn, adult.task, rdesc))
res
end.time <- Sys.time()
time.taken <- end.time - start.time
print(time.taken)

parallelStop()
