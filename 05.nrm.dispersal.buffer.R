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
library(maptools)
library(rgeos)
source("/home/jc140298/NRM/dev/helperFunctions.R") # function getVettingThreshold

# create the species specific working directories
taxon.dir = paste(wd, "/", taxon, sep="")
sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
buffer.wd = paste(sp.wd, "/buffer", sep=""); dir.create(buffer.wd); setwd(buffer.wd)

# list the projections
tfiles = list.files(sp.wd, pattern="asc.gz", full.names=TRUE)[-1]
#emg current predicted distribution is first asc, hence -1

# extract scenario names from tfile names; remove the file type 
all.projections = basename(tfiles); all.projections = gsub("\\.asc\\.gz","",all.projections) #n=576
rcp.projections = grep("RCP85|RCP45", all.projections, value=TRUE) # only want hi and lo for now
# remove the years from projections and find unique scenarios
scenarios = substring(rcp.projections, 1, nchar(rcp.projections)-5); scenarios = unique(scenarios) #n=36

# define the dispersal distances, realistic/optimistic
# EMG Need a width measurement in degrees for each buffer
if (taxon %in% c("mammals", "birds")) {
		buffers =c(1.5,3)  # 1.5km/yr and 3km/yr
} else { # reptiles, amphibians
		buffers = c(0.1,0.5) # 0.1km/yr and 0.5km/yr
}
years = seq(2005,2085,10)
#emg assumes current dist is 2005
disp.dist = buffers[2]*10 # EMG set buffer to [2] optimistic for now; there are 10 years between projections
# one degree at the equator is 111km, decreases with latitude EMG need to account for this somehow
degree.dist = disp.dist/100 # jjv says 100 (distance at ~25 S)

# get the best threshold (based on Garnett for birds, vetting process for other taxa)
threshold = getVettingThreshold(taxon, sp.wd)
if (sp == "Spilocuscus_maculatus") {
	threshold = threshold*2
}

# define some plot info
bins = seq(0,1,length=101); bins = cut(threshold,bins,labels=FALSE) # get the threshold bin for cols
cols = c(rep('gray',bins),colorRampPalette(c('brown','yellow','forestgreen'))(100)[bins:100])
legend.pnts = cbind(c(113,114.5,114.5,113),c(-44,-44,-38,-38))

# create output csv for ClassStats
out.realized = NULL

# create the first buffer polygon
# read in the threshold vetted current ascii created by 05.clip.current(.birds).R
t.vet.cur.asc = read.asc.gz(paste(sp.wd, "/warren/threshold.vet.cur.asc.gz", sep=""))

# convert asc to raster, need raster for rasterToPolygons()
raster.t.vet.cur.asc = raster(t.vet.cur.asc)

# create polygon(s) of presence data
###raster::rasterToPolygons(x, fun=NULL, n=4, na.rm=TRUE, digits=12, dissolve=FALSE)
polys = rasterToPolygons(raster.t.vet.cur.asc, fun=function(x){x==1}, n=16, 
	dissolve=TRUE)

###maptools::writeSpatialShape(x, fn, factor2char = TRUE, max_nchar=254)
#writeSpatialShape(polys, "current_poly")

# create a buffer of the dispersal distance around the presence poly
abuffpoly = gBuffer(polys, width=degree.dist)

# need to create a clipping asc with the cells inside the buffer poly equal to 1
# first, convert poly to raster to be able to extract coordinates within buffer zone using rasterToPoints
# need a map, make a copy of the threshold raster
tempmap = raster.t.vet.cur.asc
rbuffpoly = rasterize(abuffpoly, tempmap) #EMG is it okay to use threshold map?
# extract coordinates within buffer
coords = rasterToPoints(rbuffpoly)[,-3,drop=FALSE]

# need the cell number of those coordinates to be able to use them to reset map values
cellNums = cellFromXY(tempmap, coords)
tempmap[cellNums] = 1
writeRaster(tempmap, paste(buffer.wd, "/buffer_clip_", years[1], sep=""), format="ascii")
system("gzip *.asc")

# for each decade, take the previous threshold poly, add buffer, combine with next
# decade's projection 
for (sc in scenarios[1]) { cat(sc,'\n')

	# create a directory to hold the output
	scenario.wd = paste(buffer.wd, "/", sc, sep=""); dir.create(scenario.wd); setwd(scenario.wd)
	image.folder = paste(scenario.wd, "/images", sep=""); dir.create(image.folder)
		
	for (dd in 2:length(years)) { cat(years[dd],'\n')# projections start at 2015

		# read in projected distribution asc
		proj.filename = paste(sp.wd, "/", sc, "_", years[dd], ".asc.gz", sep="")
		proj.asc = read.asc.gz(proj.filename) 
# for troubleshooting		
pdf(paste("projected_", years[dd], "_buffer_clip_", years[dd-1], ".pdf", sep=""))
plot(raster(proj.asc))
if (dd == 2) {
	plot(abuffpoly, add=T)
} else {
	plot(newbuffpoly, add=T)
}
dev.off()		
		# read in the dispersal clipping asc (based on previous years' threshold map)
		if (dd == 2) {
			clip.asc = read.asc.gz(paste(buffer.wd, "/buffer_clip_", years[dd-1], ".asc.gz", sep=""))
		} else {
			clip.asc = read.asc.gz(paste("buffer_clip_", years[dd-1], ".asc.gz", sep=""))
		}
		
		# clip projection to dispersal dist
		disp.proj.asc = clip.asc*proj.asc
		write.asc.gz(disp.proj.asc, paste(years[dd], "_realized.asc", sep=""))
	
		# create a png of realized distribution
		cols = c('gray',colorRampPalette(c("tan","forestgreen"))(100))
		png(paste(image.folder,"/",sc,"_", years[dd],"_realized.png",sep=""), 
				width=dim(disp.proj.asc)[1]/100, height=dim(disp.proj.asc)[2]/100, units='cm', res=300, 
				pointsize=5, bg='white')
			par(mar=c(0,0,0,0))
			image(disp.proj.asc,zlim=c(0,1),col=cols)
			legend.gradient(legend.pnts,cols=cols,cex=1,title='Suitability')
		dev.off()

		# convert to binary prediction
		t.disp.proj.asc = disp.proj.asc
		t.disp.proj.asc[which(is.finite(t.disp.proj.asc) & t.disp.proj.asc>=threshold)] = 1
		t.disp.proj.asc[which(is.finite(t.disp.proj.asc) & t.disp.proj.asc<threshold)] = 0 
		write.asc.gz(t.disp.proj.asc, paste(years[dd], "_realized_threshold.asc",sep=""))
		# extract the class stats
		out.realized = rbind(out.realized, 
			data.frame(date=paste(sc, "_", years[dd], sep=""),ClassStat(t.disp.proj.asc,latlon=TRUE))) 
		
		# convert asc to raster
		raster.t.disp.proj = raster.from.asc(t.disp.proj.asc)
		# create a poly of presences
		newpolys = rasterToPolygons(raster.t.disp.proj, fun=function(x){x==1}, n=16, dissolve=TRUE)

		# create a buffer of the dispersal distance
		newbuffpoly = gBuffer(newpolys, width=degree.dist)
# for troubleshooting		
pdf(paste("threshold_", years[dd], "_buffer_clip_", years[dd], ".pdf", sep=""))
plot(raster.t.disp.proj)
plot(newbuffpoly, add=T)
dev.off()
		# convert poly to raster to be able to extract coordinates within buffer zone
		# need a map first, make a copy of the threshold raster
		newtempmap = raster.t.disp.proj
		raster.newbuffpoly = rasterize(newbuffpoly, newtempmap) 
		#extract coordinates within buffer
		newcoords = rasterToPoints(raster.newbuffpoly)[,-3,drop=FALSE]

		# get the cell number of those coordinates and use them to reset map values
		newcellNums = cellFromXY(newtempmap, newcoords)
		newtempmap[newcellNums] = 1
		writeRaster(newtempmap, paste("buffer_clip_", years[dd], sep=""), format="ascii")
		system("gzip *.asc")
		
	} # end for dd

	#remove information on background cells
	out.realized = out.realized[which(out.realized$class==1),]

	#save class stats
	write.csv(out.realized, paste("summary.data.disp.", buffers[2], "km.per.yr.csv", sep=""), 
		row.names=FALSE)
	
} # end for scenarios

##remove information on background cells
#out.realized = out.realized[which(out.realized$class==1),]

##save class stats
#write.csv(out.realized, paste("summary.data.disp.", buffers[2], "km.per.yr.csv", sep=""), 
#	row.names=FALSE)

## zip asc files to save space
#system("gzip *.asc")
