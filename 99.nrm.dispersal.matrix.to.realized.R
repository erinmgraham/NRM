# This script runs JJV's version of realized dispersal

library(SDMTools)
source("/home/jc140298/NRM/dev/helperFunctions.R") # function getVettingThreshold

# define working dir
wd = "/rdsi/ccimpacts/NRM"

# define taxa
taxa = c("mammals", "birds", "reptiles", "amphibians")

# define spatial scales
scales = c("5km", "1km", "250m")
project.scale = scales[2]

taxon=taxa[1]
taxon.dir = paste(wd, "/", taxon, sep="")
	
# get a list of species directories
species.names = list.files(paste(taxon.dir, "/models", sep="")) #get a list of all the species
#random sample mammals
samp.spp = species.names[c(120,138,151,159,189,206,207,208,230,242)]
sp=samp.spp[1]

sp.wd = paste(taxon.dir, "/models/", sp, "/", project.scale, sep="")
		
# need warren dir to get output files from 05.008.nrm.dispersal.jjv
warren.dir = paste(sp.wd, "/warren", sep=""); setwd(warren.dir)

#create the output directories
outfolder = paste(warren.dir, "/3km.per.yr.output", sep=""); dir.create(outfolder)
image.folder = paste(outfolder,"/images",sep=""); dir.create(image.folder)

# list the projections
tfiles = list.files(sp.wd, pattern="asc.gz", full.names=TRUE)[-1]
#emg current predicted distribution is first asc, hence -1

# extract scenario names from tfile names; remove the file type 
varnames = basename(tfiles); varnames = gsub("\\.asc\\.gz","",varnames)

# extract ES, GCM, year information from each scenario name
ESs = GCMs = YEARs = current = NULL
for (ii in 1:length(varnames)) {
	tt = strsplit(varnames[ii],'\\_')[[1]]
	ESs = c(ESs,tt[1]); GCMs = c(GCMs,tt[2]); YEARs = c(YEARs,tt[3]) 
}
# create variables for each unique emission scenario, GCM and year 
ESs = unique(ESs); GCMs = unique(GCMs); YEARs = unique(YEARs)

# remove the years from varnames and find unique scenarios
scenarios = substring(varnames, 1, nchar(varnames)-5); varnames = unique(varnames)

# read in the clipping ascii 
clip.asc = read.asc.gz(paste(warren.dir, "/threshold.current.realised.asc.gz", sep="")) 
#emg jjv creates this in 009.clipping.3km.per.yr.dispersal.r AND in 008.dispersal.script2run.AR.r

# read in the dispersal clipping matrix created in 008.dispersal.script2run.AR.r
clip.csv = read.csv(paste(warren.dir, "/", sp, ".realized.dist.disp.matrix.csv",sep=""))

# get the best threshold (identified through vetting)
threshold = getVettingThreshold(taxon, sp.wd)
if (sp == "Spilocuscus_maculatus") {
	threshold = threshold*2
}

# define some plot info
bins = seq(0,1,length=101); bins = cut(threshold,bins,labels=FALSE) # get the threshold bin for cols
cols = c(rep('gray',bins),colorRampPalette(c('brown','yellow','forestgreen'))(100)[bins:100])
legend.pnts = cbind(c(113,114.5,114.5,113),c(-44,-44,-38,-38))

# create output csv
out.realized = NULL

#cycle through each of the scenarios and summarize the data
for (scenario in scenarios) {

	#clip.csv matrix should be in memory

	for (YEAR in YEARs[-1]) {
	
		projection = paste(scenario, "_", YEAR, sep=""); cat(projection,'\n')
		
		# make a copy of the clipping ascii and set its values to 0
		clipasc = clip.asc; clipasc = clipasc * 0; 
		# then use the predicted dispersal values for that year to populate the ascii 
		clipasc[cbind(clip.csv$row,clip.csv$col)]=clip.csv[,grep(YEAR,colnames(clip.csv))]

		# read in the predicted future suitability -- potential distribution
		tasc = read.asc.gz(tfiles[which(varnames==projection)]) 
		# make a copy and clip the potential distribution to the dispersal ascii -- realized ascii
		tasc2 = tasc; tasc2 = tasc2 * clipasc 
		write.asc.gz(tasc2, paste(outfolder, "/", projection, "_realized.asc",sep=""))

		# create a png of realized distribution
		cols = c('gray',colorRampPalette(c("tan","forestgreen"))(100))
		png(paste(image.folder,"/",projection,"_realized.png",sep=""), 
				width=dim(tasc2)[1]/100, height=dim(tasc2)[2]/100, units='cm', res=300, pointsize=5, bg='white')
			par(mar=c(0,0,0,0))
			image(tasc2,zlim=c(0,1),col=cols)
			legend.gradient(legend.pnts,cols=cols,cex=1,title='Suitability')
		dev.off()

		# convert to binary prediction
		tasc2[which(is.finite(tasc2) & tasc2>=threshold)] = 1 ;
		tasc2[which(is.finite(tasc2) & tasc2<threshold)] = 0 
		# extract the class stats
		out.realized = rbind(out.realized, data.frame(date=projection,ClassStat(tasc2,latlon=TRUE))) 
	} #end for YEAR       
} #end for tfile

#remove information on background cells
out.realized = out.realized[which(out.realized$class==1),]

# save class stats
write.csv(out.realized,'summary.data.disp.3km.per.yr.csv',row.names=FALSE)




	
	
