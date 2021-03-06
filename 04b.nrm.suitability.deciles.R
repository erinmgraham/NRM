# this script will summarize the suitability maps by taking the deciles suitability across GCMs

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
source("/home/jc140298/NRM/dev/helperFunctions.R") # my.dataframe2asc

# create the species specific working directories
taxon.dir = paste(wd, "/", taxon, sep="")
sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
suit.wd = paste(sp.wd, "/suitability/deciles", sep=""); dir.create(suit.wd); setwd(suit.wd)

# define the years and scenarios low/hi
eses = c("RCP45", "RCP85")
years = seq(2015,2085,10)

# read in 1km lon/lat 
df.locs =  read.csv("/home/jc140298/NRM/1km_lat_lon.csv")

# for each emission scenario
for (es in eses) { cat(es,'\n')

	# list the projections
	projfolders = list.files(paste(sp.wd, "/suitability", sep=""), pattern=es, full.names=TRUE)

	# for each year
	for (yr in years) { cat(yr,'\n')
	
		# limit projections to single year
		yr.projs = projfolders[grep(yr,projfolders)]
	
		# create variable for scenario name to use for naming files
		scname = paste(es, "_", yr, sep="")
	
		# create a matrix to hold the year's projections, one column per GCM (proj)
		df.proj = matrix(NA,nrow=length(df.locs$x),ncol=length(yr.projs))
		colnames(df.proj) = substring(basename(yr.projs), 1, nchar(basename(yr.projs))-24)
	
		# read in each projection map and extract data values; one map per columns
		for (i in 1:length(yr.projs)) { cat(i, "...")

			# extract values for each cell from the projection map
			projname = substring(basename(yr.projs[i]), 1, nchar(basename(yr.projs[i]))-24)
			df.proj[,projname] = extract.data(data.frame(df.locs$x, df.locs$y), 
				read.asc.gz(yr.projs[i]))

		} # end for projection folders

# EMG originally created just median suitability for all species; might decide to do all deciles		
		# calculate median suitability for each location
#		out.median = apply(df.proj, 1, quantile, probs = c(0.50), na.rm = TRUE, type=8)
			
		# use the median to create maps
#		fiftieth = data.frame(cbind(df.locs$y, df.locs$x, out.median))
#		my.dataframe2asc(fiftieth, paste(scname, "_median_suitability", sep=""), gz=TRUE)
		
		# calculate 10,50,90 deciles for each location
#		out.deciles = apply(df.proj, 1, quantile, probs = c(0.10,0.50, 0.90), na.rm = TRUE, type=8)
		out.deciles = apply(df.proj, 1, quantile, probs = c(0.10, 0.90), na.rm = TRUE, type=8)
		
		# use the deciles to create maps
		tenth = data.frame(cbind(df.locs$y, df.locs$x, t(out.deciles)[,1])); my.dataframe2asc(tenth, paste(scname, "_tenth", sep=""), gz=TRUE)
#		fiftieth = data.frame(cbind(df.locs$y, df.locs$x, t(out.deciles)[,2])); my.dataframe2asc(fiftieth, paste(scname, "_fiftieth", sep=""), gz=TRUE)
#		ninetieth = data.frame(cbind(df.locs$y, df.locs$x, t(out.deciles)[,3])); my.dataframe2asc(ninetieth, paste(scname, "_ninetieth", sep=""), gz=TRUE)
		ninetieth = data.frame(cbind(df.locs$y, df.locs$x, t(out.deciles)[,2])); my.dataframe2asc(ninetieth, paste(scname, "_ninetieth", sep=""), gz=TRUE)
	
	} # end for years		
} # end es