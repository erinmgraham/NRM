# this script will apply dispersal limitations to NRM species distributions
# first it reads in the current distribution (vetted and thresholded) and applies a 10yr dispersal buffer,
# then it loops through the decadal projections, applying the previous year's dispersal buffer

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
distance.wd = paste(sp.wd, "/distance", sep=""); dir.create(distance.wd); setwd(distance.wd)

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
years = c(1990, seq(2015,2085,10))
years.since = c(25, 10, 10, 10, 10, 10, 10, 10, 10)
#emg assumes current dist is 1990; 2015-1990 = 25, 2025-2015 = 10
disp.dist = buffers[2]*years.since*1000 # in meters; emg set buffer to [2] optimistic for now 

# read in the threshold vetted current ascii created by 04.clip.current(.birds).R
t.vet.cur.asc = read.asc.gz(paste(sp.wd, "/warren/threshold.vet.cur.asc.gz", sep=""))

# convert to raster
raster.vet.cur.asc = raster.from.asc(t.vet.cur.asc, projs=CRS("+proj=longlat +datum=WGS84"))

# change the NA's to 3's to make it easier to omit them
raster.vet.cur.asc[is.na(raster.vet.cur.asc)] = 3

# create the distance raster
gD.vet.cur = gridDistance(raster.vet.cur.asc, origin=1, omit=3)
writeRaster(gD.vet.cur, paste(distance.wd, "/distance_raster_", years[1], sep=""), format="ascii")
system("gzip *.asc")

# copy distance raster and convert to binary based on dispersal distance
cp.gD.vet.cur = gD.vet.cur 
cp.gD.vet.cur[cp.gD.vet.cur <= disp.dist[1]] = 1
cp.gD.vet.cur[cp.gD.vet.cur > disp.dist[1]] = 0
#writeRaster(cp.gD.vet.cur, paste(distance.wd, "/distance_clip_", years[1], sep=""), format="ascii")

# for each decade, take the previous distance raster, combine with next year's projection, then 
#	apply a threshold to create a realized distribution and create the next year's distance raster
for (sc in scenarios) { cat(sc,'\n')

	# create a directory to hold the output
	scenario.wd = paste(distance.wd, "/", sc, sep=""); dir.create(scenario.wd); setwd(scenario.wd)
		
	for (dd in 2:length(years)) { cat(years[dd],'\n')# projections start at 2015

		# read in projected distribution asc
		proj.filename = paste(sp.wd, "/", sc, "_", years[dd], ".asc.gz", sep="")
		proj.asc = read.asc.gz(proj.filename) 
	
		# read in the dispersal clipping asc (based on previous years' threshold map)
		if (dd == 2) {
#			clip.asc = read.asc.gz(paste(distance.wd, "/distance_clip_", years[dd-1], ".asc.gz", sep=""))
			clip.asc = asc.from.raster(cp.gD.vet.cur)
		} else {
#			clip.asc = read.asc.gz(paste("distance_clip_", years[dd-1], ".asc.gz", sep=""))
			clip.asc = asc.from.raster(new.cp.gD.vet.cur)
		}
			
		# clip projection to dispersal dist
		disp.proj.asc = proj.asc*clip.asc
#		write.asc.gz(disp.proj.asc, paste(years[dd], "_realized.asc", sep=""))

		# convert to binary prediction
		t.disp.proj.asc = disp.proj.asc
		t.disp.proj.asc[which(is.finite(t.disp.proj.asc) & t.disp.proj.asc>=threshold)] = 1
		t.disp.proj.asc[which(is.finite(t.disp.proj.asc) & t.disp.proj.asc<threshold)] = 0 
		write.asc.gz(t.disp.proj.asc, paste(years[dd], "_realized_threshold.asc",sep=""))
		
		# convert to raster
		r.vet.cur.asc = raster.from.asc(t.disp.proj.asc, projs=CRS("+proj=longlat +datum=WGS84"))

		# change the NA's to 3's to make it easier to omit them
		r.vet.cur.asc[is.na(r.vet.cur.asc)] = 3

		# create the distance raster
		new.gD.vet.cur = gridDistance(r.vet.cur.asc, origin=1, omit=3)
		writeRaster(new.gD.vet.cur, paste("distance_raster_", years[dd], sep=""), format="ascii")		
	
		# copy distance raster and convert to binary based on dispersal distance
		new.cp.gD.vet.cur = new.gD.vet.cur 
		new.cp.gD.vet.cur[new.cp.gD.vet.cur <= disp.dist[dd]] = 1
		new.cp.gD.vet.cur[new.cp.gD.vet.cur > disp.dist[dd]] = 0
#		writeRaster(new.cp.gD.vet.cur, paste("distance_clip_", years[dd], sep=""), format="ascii")

	} # end for dd	
	
	system("gzip *.asc")
} # end for scenarios