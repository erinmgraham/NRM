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

library(SDMTools)
#library(raster)
#library(maptools)
#library(rgeos)
#source("/home/jc140298/NRM/dev/helperFunctions.R") # function getVettingThreshold

# create the species specific working directories
taxon.dir = paste(wd, "/", taxon, sep="")
sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
dispersal.wd = paste(sp.wd, "/dispersal", sep="") 
summary.wd = paste(sp.wd, "/summary", sep=""); dir.create(summary.wd); setwd(summary.wd)

eses = c("RCP45", "RCP85")
#years = c(1990, seq(2015,2085,10)) # emg need to do something with the baseline
years = seq(2015,2085,10)

# read in generic map to get lon/lat 
df.locs =  asc2dataframe("/rdsi/ctbcc_data/Climate/CIAS/Australia/1km/bioclim_asc/current.76to05/bioclim_01.asc")
# EMG could make this quicker using same loc's csv?

# for each emission scenario
for (es in eses) { cat(es,'\n')

	# list the projections
	projfolders = list.files(dispersal.wd, pattern=es, full.names=TRUE)

	# for each year
	for (yr in years) { cat(yr,'\n')
	
		# create variable for scenario name to use for naming files
		scname = paste(es, "_", yr, sep="")
	
		# create a matrix to hold the year's projections, one column per GCM (proj)
		df.proj = data.frame(df.locs$x, df.locs$y)
	
		# read in each projection map and extract data values; one map per columns
		for (i in 1:length(projfolders)) { cat(i, "...")
		
			# read in the projection map
			filename = paste(projfolders[i], "/", yr, "_realized.asc.gz", sep="")
			proj.map = read.asc.gz(filename)
		
			# extract values for each cell
			df.proj[,basename(projfolders[i])] = extract.data(df.proj[,1:2], proj.map)

		} # end for projection folders

		# calculate 10,50,90 deciles for each location
		out.deciles = apply(as.matrix(df.proj[,3:20]), 1, quantile, probs = c(0.10,0.50, 0.90),  
			na.rm = TRUE, type=7)
		#EMG not sure what type to use, 7 is the default
		
		# combine output and save
		df.out = cbind(df.proj, t(out.deciles))
		save(df.out, file=paste(summary.wd, "/", scname, "_values.RData", sep=""))	
		#EMG Do I need to save these? Takes a lot of memory (8GB) and some space
			
		# use the deciles to create maps
		tenth = data.frame(df.out[,c(2,1,21)]); dataframe2asc(tenth, paste(scname, "_tenth", sep=""), gz=TRUE)
		fiftieth = data.frame(df.out[,c(2,1,22)]); dataframe2asc(fiftieth, paste(scname, "_fiftieth", sep=""), gz=TRUE)
		ninetieth = data.frame(df.out[,c(2,1,23)]); dataframe2asc(ninetieth, paste(scname, "_ninetieth", sep=""), gz=TRUE)

	} # end for years		
} # end es