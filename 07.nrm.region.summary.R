# this script will analyze the SDM outputs for various climate scenarios and produce summary info
# for each region:
# for the baseline - temp/precip min/max; biodiversity
# for each year - 10/50/90 temp/precip min/max; 10/50/90 biodiversity gain/loss 

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

library(maptools)
library(SDMTools)
library(raster)
#library(rgeos)
#source("/home/jc140298/NRM/dev/helperFunctions.R") # function getVettingThreshold

# create the species specific working directories
taxon.dir = paste(wd, "/", taxon, sep="")
sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
distance.wd = paste(sp.wd, "/distance", sep="") 
summary.wd = paste(sp.wd, "/summary", sep="")

# read in NRM shapefiles - all NRMs
NRM.polys = readShapePoly("/home/jc140298/NRM/NRM_poly.shp", 
	proj4string=CRS("+proj=longlat +datum=WGS84"))
# Northern Territory subregions
NTsub.polys = readShapePoly("/home/jc140298/NRM/NT_A_PP_GDA94_130208_5.shp", 
	proj4string=CRS("+proj=longlat +datum=WGS84"))
# Kimberley subregion
WAsub.polys = readShapePoly("/home/jc140298/NRM/RNRM_Subregion_Kimberley.shp", 
	proj4string=CRS("+proj=longlat +datum=WGS84"))

# create file for output
outfilename = "/home/jc140298/tools/testAggregate.txt"
write(c("scenario", "min", "ten", "median", "ninety", "max"), file = outfilename, ncolumns = 6, 
	append=TRUE, sep = "\t")
	
eses = c("RCP45", "RCP85")
#years = c(1990, seq(2015,2085,10)) # emg need to do something with the baseline
years = seq(2015,2085,10)

# for each emission scenario
for (es in eses) { cat(es,'\n')

	# list the aggregate projections
	aggregatefiles = list.files(summary.wd, pattern=es, full.names=TRUE)
	
	if (length(aggregatefiles) == 8) {	# in case there was an issue with aggregating

		# for each file
		for (agfile in aggregatefiles) { cat(basename(agfile),'\n') 
		
			# read in the file
			agmap = read.asc.gz(agfile)
			ragmap = raster(agmap)
			
			# extract the values for each NRM region
			NRM.out = extract(ragmap, NRM.polys, fun=NULL, na.rm=TRUE, weights=TRUE)
			save(NRM.out, "NRM_out.RData")

			# calculate the summary statistics for each region
			for (polys in 1:length(NRM.polys)) {
			
				
			
		} # end for agfile
	} else {
	
		# record error to investigate later
		msg = paste("ERROR: Missing aggregate file, only ", length(aggregatefiles), " of 8 files exist", sep="") 
		write(msg, paste(summary.wd, "/Error.txt", sep=""))
	} # end if length
} # end es

	
	for (n in 1:length(nrms@data$SP_ID)) {
	
		nrm.id = nrms@data$SP_ID[n]
		nrm = nrms[nrms@data$SP_ID == nrm.id]
	
		
write(c(sc, index, sp, num.occur), file = outfilename, ncolumns = 4, 
append=TRUE, sep = "\t")


			