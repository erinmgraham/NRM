# MigClim

#library(SDMTools)
#library(raster)	# includes SDMTools, raster, and sp 
#library(maptools)
#library(png)
library(jpeg)

# define working dir
wd = "/rdsi/ccimpacts/NRM"

# define taxa
taxa = c("mammals", "birds", "reptiles", "amphibians")

# define spatial scales
scales = c("5km", "1km", "250m")
project.scale = scales[2]

# define dispersal types (for migclim rcThreshold)
dispersal.types = c("binary", "continuous")

# define dispersal scenarios (i.e., dispersal distances)
dispersal.scenarios = c("realistic", "optimistic")

# for each taxon and 10 species, prepare data for migclim and project
for (taxon in taxa[c(1,3:4)]) {

	taxon.dir = paste(wd, "/", taxon, sep="")
	
	# get a list of species directories
	species.names = list.files(paste(taxon.dir, "/models", sep="")) #get a list of all the species

	if (taxon == "mammals") {
		samp.spp = species.names[c(120,138,151,159,189,206,207,208,230,242)]
	} else if (taxon == "reptiles") {
		samp.spp = species.names[c(46,91,118,251,313,361,402,507,513,588)]
	} else if (taxon == "amphibians") {
		samp.spp = species.names[c(6,11,81,106,133,156,160,198,202,223)]
	}

	for (sp in samp.spp) { # cycle through each of the species

		sp.wd = paste(taxon.dir, "/models/", sp, "/", project.scale, sep="")
		
		# migclim dir
		migclim.dir = paste(sp.wd, "/migclim", sep=""); setwd(migclim.dir)
		
xls = c(0,100,0,100)
ybs = c(100,100,0,0)
xrs = c(100,200,100,200)
yts = c(200,200,100,100)

		# create file to compared summary output
		filename = paste(sp, "_MigClim_summary.csv", sep="")
		write(c("scenario", "iniCount", "noDispCount", "univDispCount", "occupiedCount", "absentCount", "totColonized",
			"totDecolonized"), file = filename, ncolumns = 8, append=TRUE, sep = ",")
	    
		# create .pdf to save figure
		png(file=paste(sp, "_MigClim.png", sep=""), width=28, height=19, units='cm', res=600)
		
		# change margins to make pretty
		par(mar=c(0,0,0,0), oma=c(0,0,0,0))

		plot(seq(1:200), seq(1:200), type="n", xlab="", ylab="", axes=FALSE)

		i=1	
		for (t in 1:length(dispersal.types)) {
				
			for (s in 1:length(dispersal.scenarios)) {		

				scenario = paste(dispersal.types[t], "_", dispersal.scenarios[s], sep="")
			
				out.dir = paste(migclim.dir, "/MigClimTest_",  scenario, sep="")
				in.jpg = readJPEG(paste(out.dir, "/MigClimTest_", scenario, "1_raster.jpg", sep=""))
					
				summaryfile = read.table(paste(out.dir, "/MigClimTest_", scenario, "1_summary.txt", sep=""), 
					header=TRUE)
				
				rasterImage(in.jpg, xleft=xls[i], ybottom=ybs[i], xright=xrs[i], ytop=yts[i])
				text(xls[i]+50, yts[i]-2, scenario)
				text(100, 200, sp)
				i=i+1
				
				write(c(scenario, summaryfile[,2], summaryfile[,3], summaryfile[,4], summaryfile[,5], summaryfile[,6], 
					summaryfile[,7], summaryfile[,8]), file = filename, ncolumns = 8, append=TRUE, sep = ",")
			}
		}	
		# close the .png 
		dev.off()
	} # end for species
} # end for taxa

