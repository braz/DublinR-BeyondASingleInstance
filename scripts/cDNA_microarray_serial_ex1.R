# https://bioconductor.org/help/course-materials/2015/CSAMA2015/lab/classification.html#load-example-data-from-hiiragi2013.
source("https://bioconductor.org/biocLite.R")
source("http://www.bioconductor.org/biocLite.R")
biocLite("Biobase")
biocLite("Hiiragi2013")

library("knitr")
library("Biobase")
library("Hiiragi2013")
library("glmnet")
library("mlr")

data( "x", package = "Hiiragi2013" )
x
table( x$sampleGroup )

rowV <- data.frame( v = rowVars(exprs(x)) )
selectionThreshold <- 10^(-0.5)
selectedFeatures  <- ( rowV$v > selectionThreshold )
embryoSingleCells <- data.frame( t(exprs(x)[selectedFeatures, ]), check.names = TRUE )
embryoSingleCells$tg <- factor( ifelse( x$Embryonic.day == "E3.25", "E3.25", "other") )
with( embryoSingleCells, table( tg ) )


task <- makeClassifTask( id = "Hiiragi", data = embryoSingleCells, target = "tg" )
lrn = makeLearner( "classif.glmnet", predict.type = "prob" )
rdesc <- makeResampleDesc( method = "CV", stratify = TRUE, iters = 12 )

start.time <- Sys.time()
r <- resample(learner = lrn, task = task, resampling = rdesc )
end.time <- Sys.time()
time.taken <- end.time - start.time
print(time.taken)
r
head( r$pred$data )
with( r$pred$data, table(truth, response) )


tuningLrn <- makeTuneWrapper(lrn, 
  resampling = makeResampleDesc("CV", iters = 10,  stratify = TRUE), 
  par.set = makeParamSet(makeNumericParam("s", lower = 0.001, upper = 0.1)), 
  control = makeTuneControlGrid(resolution = 6) )
start.time <- Sys.time()
r2 <- resample(learner = tuningLrn, task = task, resampling = rdesc )
end.time <- Sys.time()
time.taken <- end.time - start.time
print(time.taken)
r2
head( r2$pred$data )
with( r2$pred$data, table(truth, response) )

