#script to produce output for vetting current species distributions

# read in the arguments listed at the command line
args=(commandArgs(TRUE))  
for(i in 1:length(args)) { 
	eval(parse(text=args[[i]])) 
}
# expecting sp.wd, sp

library(SDMTools)
library(raster)
library(maptools)
library(png)

# read in occurrence data and maxent.results files
occur = read.csv(paste(sp.wd, "/occur.csv", sep=""), stringsAsFactors=FALSE)
results = read.csv(paste(sp.wd, "/maxentResults.csv", sep=""), header=TRUE)

# define thresholds
threshold.names = c("Equal.training.sensitivity.and.specificity.logistic.threshold",
"Balance.training.omission..predicted.area.and.threshold.value.logistic.threshold",
"Equate.entropy.of.thresholded.and.original.distributions.logistic.threshold")

# determine the most severe threshold
# in maxentResults.csv, logistic threshold values are in columns 43 47 51 55 59 63 67 71 75
most.severe = colnames(results)[which(results[1,]==max(results[1, c(63,71,75)]))]
most.severe.name = most.severe[which(most.severe %in% threshold.names)][1]
threshold.names = c(threshold.names, most.severe.name)

# get the actual values for those thresholds
thresholds = as.numeric(results[1,c(threshold.names)])
# adjust severe 
if (thresholds[4] <= 0.4) {
	thresholds[4] = thresholds[4]*2
	threshold.names[4] = paste("Most.severe*2: ", most.severe.name, sep="")
} else {
	thresholds[4] = thresholds[4]/2
	threshold.names[4] = paste("Most.severe/2: ", most.severe.name, sep="")
}

# get the current.asc file
ascfile = read.asc.gz(file=paste(sp.wd, "/bioclim.asc.gz", sep=""))
# convert to raster (otherwise too slow to image)
r_ascfile = raster(ascfile)

# get the regions to plot
regions = c("state", "ibra")
state.poly = readShapePoly("/home/jc148322/AP02/climate.summaries/region_layers/Shapefile/STE11aAust.shp")
ibra.poly = readShapePoly("/home/jc148322/AP02/climate.summaries/region_layers/Shapefile/IBRA7_regions.shp")
#nrm.poly = readShapePoly("/home/jc148322/AP02/climate.summaries/region_layers/Shapefile/NRM_Regions_2010.shp")
region.polys = c(state.poly, ibra.poly)

for (i in 1:length(region.polys)) { cat(i,'of',length(region.polys),' region polys\n')

	# create .pdf to save figure
	png(file=paste(sp.wd, "/", sp, "_", regions[i], ".png", sep=""), width=28, height=19, units='cm', res=600)
	
	# change margins to make pretty
	par(mfrow=c(2,3), mar=c(0,0,0,0), oma=c(0,0,0,0))

	# plot current projection with IBRA regions and occurrence points
	image(r_ascfile, xlim=c(112.9,154), ylim=c(-43.7425,-8), axes=FALSE, col=rev(terrain.colors(255)))
	points(occur$lon, occur$lat, pch=19, cex=0.25, col="red")
	plot(region.polys[i][[1]], add=TRUE, lwd=0.15)


	# add maps for each threshold
	for (j in 1:length(thresholds)) { cat(j,'of',length(thresholds),' thresholds\n')

		# apply the threshold
		tr = thresholds[j]
		tr_ascfile = ascfile
		tr_ascfile[which(tr_ascfile<tr)]=0
		tr_ascfile[which(tr_ascfile>=tr)]=1
		
		# need to convert to raster because image it too big
		r_tr_ascfile = raster(tr_ascfile)
		mytitle = paste(strtrim(threshold.names[j], width=25), ": ", tr, sep="")
	
		# create a blank plot to line up the threshold maps
		if (j == 3) {
			plot.new()
		}
		
		# plot the threshold raster
		image(r_tr_ascfile, xlim=c(112.9,154), ylim=c(-43.7425,-8), axes=FALSE, col=rev(terrain.colors(2)))
		text(125, -38, mytitle)
		text(120, -15, paste("T", j, sep=""), cex=3)
		
		# add the region outline
		plot(region.polys[i][[1]], add=TRUE, lwd=0.25)

	}# end for threshold

	# close the .png 
	dev.off()
	
} # end for region