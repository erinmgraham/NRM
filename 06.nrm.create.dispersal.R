# this script will apply dispersal limitations to NRM species distributions
# first it reads in the current distribution (vetted and thresholded) and creates an 80yr dispersal buffer ascii
# then it loops through the decadal projections, uses the dispersal map to create the projected dispersal
#	distance clip and clips the suitability distribution

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
library(raster)
source("/home/jc140298/NRM/dev/helperFunctions.R") # function getVettingThreshold

# create the species specific working directories
taxon.dir = paste(wd, "/", taxon, sep="")
sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
dispersal.wd = paste(sp.wd, "/dispersal", sep=""); dir.create(dispersal.wd); setwd(dispersal.wd)

# get the best threshold (based on Garnett for birds, vetting process for other taxa)
threshold = getVettingThreshold(taxon, sp.wd)
if (sp == "Spilocuscus_maculatus") {
	threshold = threshold*2
}

# list the projections
tfiles = list.files(sp.wd, pattern="asc.gz", full.names=TRUE)[-1]
#emg current predicted distribution is first asc, hence -1

# extract scenario names from tfile names; remove the file type 
all.projections = basename(tfiles); all.projections = gsub("\\.asc\\.gz","",all.projections) #n=576
rcp.projections = grep("RCP85|RCP45", all.projections, value=TRUE) # only want hi and lo for now
# remove the years from projections and find unique scenarios
scenarios = substring(rcp.projections, 1, nchar(rcp.projections)-5); scenarios = unique(scenarios) #n=36

# define the dispersal distances, realistic/optimistic
if (taxon %in% c("mammals", "birds")) {
		buffers =c(1.5,3)  # 1.5km/yr and 3km/yr
} else { # reptiles, amphibians
		buffers = c(0.1,0.5) # 0.1km/yr and 0.5km/yr
}
years = c(1990, seq(2015,2085,10)) #emg assumes current dist is 1990
years.passed = c(0, 25, 35, 45, 55, 65, 75, 85, 95) # 2015-1990 = 25, 2025-1990=35, etc.
disp.dist = buffers[2]*years.passed*1000 # in meters; emg set buffer to [2] optimistic for now 

# read in the threshold vetted suitability current ascii created by 04.clip.current(.birds).R
t.vet.cur.asc = read.asc.gz(paste(sp.wd, "/realized/threshold.vet.suit.cur.asc.gz", sep=""))

# convert to raster
raster.vet.cur.asc = raster.from.asc(t.vet.cur.asc, projs=CRS("+proj=longlat +datum=WGS84"))

# change the NA's to 3's to make it easier to omit them
raster.vet.cur.asc[is.na(raster.vet.cur.asc)] = 3

# create the distance dispersal raster
gD.vet.cur = gridDistance(raster.vet.cur.asc, origin=1, omit=3)

# write dispersal distance raster
writeRaster(gD.vet.cur, paste(dispersal.wd, "/distance_current_", max(disp.dist), "m.asc", sep=""))
system("gzip *.asc")

temp.asc = read.asc.gz(paste(dispersal.wd, "/distance_current_", max(disp.dist), "m.asc.gz", sep=""))
# NOTE: if species is not present on both landmasses, gridDistance will not cross Tasman
#	and either the mainland or Tasmania will be excluded and needs to be added back
TasCheck = extract.data(cbind(147, -42), gD.vet.cur)
if (is.na(TasCheck)) { cat("Tasmania is NOT present\n")
	# read in a map with blank Tasmania (all 0's)
	blankMap = read.asc.gz("/home/jc140298/scratch/blank_Tas_only_map.asc.gz")
	# get positions of the zero's (land)
	landPos = which(blankMap == 0)
	# add back land
	temp.asc[landPos] = 0
	write.asc.gz(temp.asc, paste(dispersal.wd, "/distance_current_", max(disp.dist), "m", sep=""))
} 
OzCheck = extract.data(cbind(134, -25), gD.vet.cur)
if (is.na(OzCheck)) { cat(" Australia is NOT present\n")
	blankMap = read.asc.gz("/home/jc140298/scratch/blank_OZ_only_map.asc.gz")
	landPos = which(blankMap == 0)
	temp.asc[landPos] = 0
	write.asc.gz(temp.asc, paste(dispersal.wd, "/distance_current_", max(disp.dist), "m", sep=""))
}

# read in dispersal dist asc if you've already created it and need to run smaller set of scenarios
#gD.vet.cur.asc = read.asc.gz(paste(dispersal.wd, "/distance_current_", max(disp.dist), "m.asc.gz", sep=""))
#temp.asc = gD.vet.cur.asc

# for each decadal projection, clip the distance raster to be suitable for the time period, 
#	apply a threshold to that time period's projection, and combine the maps
for (sc in scenarios) { cat(sc,'\n')

	# create a directory to hold the output
	scenario.wd = paste(dispersal.wd, "/", sc, sep=""); dir.create(scenario.wd); setwd(scenario.wd)
		
	for (dd in 2:length(years)) { cat(years[dd],'\n')# projections start at 2015
	
		# read in the dispersal distance asc and convert it into a binary clipping asc
		#	based on dispersal distance for that year's projection
		raster.clip = raster(temp.asc)
		raster.clip[raster.clip <= disp.dist[dd]] = 1
		raster.clip[raster.clip > disp.dist[dd]] = 0
		writeRaster(raster.clip, paste("distance_clip_", years[dd], sep=""), format="ascii")
# for troubleshooting
#pdf(paste("distance_clip_", years[dd], ".pdf", sep=""))
#plot(raster.clip)
#dev.off()
		# read in projected suitability distribution asc
		proj.filename = paste(sp.wd, "/suitability/", sc, "_", years[dd], "_suitability.asc.gz", sep="")
		proj.asc = read.asc.gz(proj.filename) 

		# clip projection to dispersal dist
		# need raster as asc
		clip.asc = asc.from.raster(raster.clip)
		disp.proj.asc = proj.asc*clip.asc
		write.asc.gz(disp.proj.asc, paste(years[dd], "_realized.asc", sep=""))
# for troubleshooting
#pdf(paste(years[dd], "_realized.pdf", sep=""))
#plot(raster(disp.proj.asc))
#dev.off()
		} # end for dd	
	
	system("gzip *.asc")
} # end for scenarios