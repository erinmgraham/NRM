# this script creates the species threshold vetted current asciis for NRM
# it uses occurrence records and expert opinion to clip the maxent predicted distribution to the empirical distribution

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
library(maptools)

# create the species specific working directory
taxon.dir = paste(wd, "/", taxon, sep="")
sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
		
# create realized dir to hold output files
real.wd = paste(sp.wd, "/realized", sep=""); dir.create(real.wd); setwd(real.wd)

## read in the current maxent predicted distribution
#predicted.cur.asc = read.asc.gz(paste(sp.wd, "/bioclim.asc.gz", sep="")) 
# read in the current suitability distribution
suitability.cur.asc = read.asc.gz(paste(sp.wd, "/suitability/bioclim_suitability.asc.gz", sep=""))

# read in the Birdlife to species.names key 
bird.key = read.csv("/home/jc140298/NRM/Birdlife_polygons_key.csv")

# read in the Birdlife clipping polygons and grab the one for this species
birdlife.poly = readShapePoly("/home/jc140298/NRM/out.shp", 
	proj4string=CRS("+proj=longlat +datum=WGS84"))
sp.id = bird.key$SPECIES_ID[bird.key$species.names == sp]
if (length(sp.id) != 0) {
	bird.poly = birdlife.poly[birdlife.poly$SPECIES_ID == sp.id,]
} else {
	stop("MISSING : No SPECIES_ID found with that species name!")
}	
	
# convert the poly to raster to asc 
# first need suitability asc to be a "blank" template and a raster
bird.asc = suitability.cur.asc; bird.asc[which(is.finite(bird.asc))] = 0; bird.clip.raster=raster(bird.asc)
bird.poly.raster = rasterize(bird.poly, bird.clip.raster)
coords = rasterToPoints(bird.poly.raster)[,-3,drop=FALSE]
cellNums = cellFromXY(bird.clip.raster, coords)
bird.clip.raster[cellNums] = 1
writeRaster(bird.clip.raster, "bird_clip.asc"); system("gzip bird_clip.asc")

# apply the birdlife clipping asc
bird.clip.asc = asc.from.raster(bird.clip.raster)
vet.suit.cur.asc = bird.clip.asc*suitability.cur.asc
write.asc.gz(vet.suit.cur.asc, "vet.suit.cur.asc")

# create binary vetted suitability current distribution
# read in the maxent results thresholds
results = read.csv(paste(sp.wd, "/maxentResults.csv", sep=""))
if (results$Minimum.training.presence.area > 0.8) {
	threshold = results$Equate.entropy.of.thresholded.and.original.distributions.logistic.threshold/2
} else {
	threshold = results$Equate.entropy.of.thresholded.and.original.distributions.logistic.threshold
}
# make a copy of the vetted current suitability distribution asc
t.vet.suit.cur.asc = vet.suit.cur.asc 
# apply threshold to change habitat suitability to binary
t.vet.suit.cur.asc[which(is.finite(t.vet.suit.cur.asc) & t.vet.suit.cur.asc>=threshold)] = 1
t.vet.suit.cur.asc[which(is.finite(t.vet.suit.cur.asc) & t.vet.suit.cur.asc<threshold)] = 0
write.asc.gz(t.vet.suit.cur.asc, "threshold.vet.suit.cur.asc")


