#!/usr/bin/env Rscript
#
# serial.R - Sample script that performs a kmeans analysis on the generated dataset.csv file
# source: https://github.com/glennklockwood/paraR/blob/master/kmeans/serial.R
# author: glennklockwood
# minor modifications: eoinbrazil
# ggplot2 is included so we can visualize the result

library(ggplot2) 
#load the generated dataset
data <- read.csv('dataset.csv')
 
# run k-means and classify the data into clusters
start.time <- Sys.time()
result <- kmeans(data, centers=10, nstart=100)
end.time <- Sys.time()
time.taken <- end.time - start.time
print(time.taken)
 
# print the cluster centers based on the k-means run
print(result$centers)
 
# present the data as a visual plot
data$cluster = factor(result$cluster)
centers = as.data.frame(result$centers)
plot = ggplot(data=data, aes(x=x, y=y, color=cluster )) + geom_point() + geom_point(data=centers, aes(x=x,y=y, color='Center')) + geom_point(data=centers, aes(x=x,y=y, color='Center'), size=52, alpha=.3, show_guide=FALSE)
print(plot)