# this script will take freshwater species future gridded data and produce realized maps

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
	# expecting wd, taxon
}

library(SDMTools)
source("/home/jc140298/NRM/dev/helperFunctions.R") #my.dataframe2asc

# define working dirs
source.dir = "/rdsi/vol07/ccimpacts/NRM/Realized_gridded"
source.taxon.dir = paste(source.dir, "/", taxon, sep="")
dest.taxon.dir = paste(wd, "/", taxon, sep="")
sp.wd = paste(dest.taxon.dir, "/models/", sp, "/1km", sep="")
disp.wd = paste(sp.wd, "/dispersal", sep=""); dir.create(disp.wd)

# define the years and scenarios low/hi
eses = c("RCP45", "RCP85")
years = seq(2015,2085,10)

for (es in eses) {

	es.sp.dir = paste(source.taxon.dir, "/", es, "/", sp, sep="")
	
	# use the list of files to get a list of gcms
	species.files = list.files(es.sp.dir, full.names=TRUE)
	scenario.names = sapply(strsplit(basename(species.files), split="[.]"), '[', 1) 
	u.sc.names.noyear = unique(substr(scenario.names, 1, nchar(scenario.names)-5))
	
	for (gcm in u.sc.names.noyear) {
	
		# create the output directory
		gcm.wd = paste(disp.wd, "/", gcm, sep=""); dir.create(gcm.wd)
		
		# get scenario grid files
		gcm.sp.files = species.files[grep(gcm, species.files)]
		
		for (yr in years) {
		
			gcm.sp.yr.file = gcm.sp.files[grep(yr, gcm.sp.files)]
			load(gcm.sp.yr.file) #tpos
		
			# use the dataframe of locations and values to generate asc
			setwd(gcm.wd) # needed for dataframe2asc
			my.dataframe2asc(tpos[,4:6], filenames=paste(yr, "_realized", sep=""), gz=TRUE)
			rm(tpos)
		} # end for year
	} # end for gcm
} # end for scenario


