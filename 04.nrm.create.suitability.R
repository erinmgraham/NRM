# this script creates a set of suitability asciis for NRM
# it reads in the maxent projected distributions and applies a vetted threshold
# 	but leaves the above-threshold values as suitability (tr-1)

# read in the arguments listed at the command line
args=(commandArgs(TRUE))  
# check to see if arguments are passed
if(length(args)==0){
    print("No arguments supplied.")
    # leave all args as default values
} else {
	for(i in 1:length(args)) { 
		eval(parse(text=args[[i]])) 
	}
	# expecting wd, taxon and sp
}

library(SDMTools)
#library(raster)
#library(rgdal) # for geotiff
source("/home/jc140298/NRM/dev/helperFunctions.R") # function getVettingThreshold

# create the species specific working directory
taxon.dir = paste(wd, "/", taxon, sep="")
sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
		
# create suitability dir to hold output files
suit.wd = paste(sp.wd, "/suitability", sep=""); dir.create(suit.wd); setwd(suit.wd)

# get the best threshold (based on Garnett for birds, vetting process for other taxa)
threshold = getVettingThreshold(taxon, sp.wd)
if (sp == "Spilocuscus_maculatus") {
	threshold = threshold*2
}

# list the raw projections
tfiles = list.files(sp.wd, pattern="asc.gz", full.names=TRUE)

# extract scenario names from tfile names; remove the file type 
all.projections = basename(tfiles); all.projections = gsub("\\.asc\\.gz","",all.projections) #n=576
rcp.projections = grep("RCP85|RCP45", all.projections, value=TRUE) # only want hi and lo for now n=288
scenarios = c("bioclim", rcp.projections)

for (sc in scenarios[34:41]) {
	
	# read in the maxent predicted distribution
	predicted.asc = read.asc.gz(paste(sp.wd, "/", sc, ".asc.gz", sep="")) 

	# apply the threshold 
	suit.pred.asc = predicted.asc
	suit.pred.asc[suit.pred.asc < threshold] = 0 
	
	# convert to raster to write as geotiff
#	r.suit.pred.asc = raster(suit.pred.asc)
#	writeRaster(r.suit.pred.asc, filename=paste(sc, "_suitability.tif", sep=""), format="GTiff") 
	# EMG Error in .getGDALtransient : could not find function "GDALcall"
	
	write.asc.gz(suit.pred.asc, paste(sc, "_suitability.asc",sep=""))
} # end for sc