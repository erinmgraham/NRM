# MigClim

library(MigClim)	# includes SDMTools, raster, and sp 
source("/home/jc140298/NRM/dev/helperFunctions.R") # function getVettingThreshold

##############################################################################
#MigClim.migrate(iniDist = "InitialDist", 
#	hsMap = "HSmap",
#	rcThreshold = 0, 
#	envChgSteps = 1,
#	dispSteps = 1, 
#	dispKernel = c(1,1),
#	barrier = "", 
#	barrierType = "strong", 
#	iniMatAge = 1, 
#	propaguleProd = c(1),
#	lddFreq = 0, 
#	lddMinDist = NULL, 
#	lddMaxDist = NULL,
#	simulName = "MigClimTest", 
#	replicateNb = 1,
#	overWrite = FALSE, 
#	testMode = FALSE,
#	fullOutput = FALSE, 
#	keepTempFiles = FALSE)

#MigClim.plot(asciiFile, outDir = "", fileFormat = "jpeg", fullOutput = FALSE)

##############################################################################

# define working dir
wd = "/rdsi/ccimpacts/NRM"

# define taxa
taxa = c("mammals", "birds", "reptiles", "amphibians")

# run on a sample of species first to test
samp.spp = list(c(120,138,151,159,189,206,207,208,230,242), 	#mammals
	c(28,47,50,88,167,225,396,492,557,558), 					#birds
	c(46,91,118,251,313,361,402,507,513,588),					#reptiles
	c(6,11,81,106,133,156,160,198,202,223))						#amphibians
	
# define spatial scales
scales = c("5km", "1km", "250m")
project.scale = scales[2]

# define dispersal types (for migclim rcThreshold)
dispersal.types = c("binary", "continuous")

# define dispersal scenarios (i.e., dispersal distances)
dispersal.scenarios = c("realistic", "optimistic")

# EMG dataframe2asc pads ncol and nrow with +1, removed so all asc have same num of cells
my.dataframe2asc = function (tdata, filenames = NULL, outdir = getwd(), gz = FALSE) 
{
    if (is.null(filenames)) {
        filenames = colnames(tdata)[3:length(tdata)]
    }
    else {
        if (length(filenames) != length(3:length(tdata))) 
            stop("variable names must be the same length as the files vector")
        filenames = as.character(filenames)
    }
    for (ii in 3:(length(tdata))) {
        lats = unique(tdata[, 1])
        lats = sort(lats)
        longs = unique(tdata[, 2])
        longs = sort(longs)
        cellsize = min(c(diff(lats), diff(longs)))
        nc = ceiling((max(lats) - min(lats))/cellsize) #+1
        nr = ceiling((max(longs) - min(longs))/cellsize) #+1
        out.asc = as.asc(matrix(NA, nrow = nr, ncol = nc), xll = min(longs), 
            yll = min(lats), cellsize = cellsize)
        out.asc = put.data(tdata[, c(2:1, ii)], out.asc)
        write.asc(out.asc, paste(outdir, "/", filenames[ii - 
            2], sep = ""), gz = gz)
    }
}

# for each taxon and 10 species, prepare data for migclim and project
for (taxon in taxa[4]) {

	taxon.dir = paste(wd, "/", taxon, sep="")
	
	# define taxa-specific realistic and optimistic dispersal kernels (Warren et al 2013)
	# EMG for MigClim, dispersal distance is limited by cell size; cell size = 1km
	if (taxon %in% c("mammals", "birds")) {
		dispersal.distances=list(c(1,0.5), c(1,1,1))  # actually 1.5km/yr and 3km/yr
	} else { # reptiles, amphibians
		dispersal.distances = list(c(0.1), c(0.5)) # supposed to be 0.1km/yr and 0.5km/yr
	}
	
	# get a list of species directories
	species.names = list.files(paste(taxon.dir, "/models", sep="")) #get a list of all the species

	for (sp in samp.spp) { # cycle through each of the species

		sp.wd = paste(taxon.dir, "/models/", sp, "/", project.scale, sep="")
		
		# create migclim dir to hold files
		migclim.dir = paste(sp.wd, "/migclim", sep=""); dir.create(migclim.dir); setwd(migclim.dir)

		# get the best threshold (identified through polygons for birds, vetting for other taxa)
		threshold = getVettingThreshold(taxon, sp.wd)
		if (sp == "Spilocuscus_maculatus") {
			threshold = threshold*2
		}
		
		# read in thresholded current distribution
		current.asc = read.asc.gz(paste(sp.wd, "/bioclim.asc.gz", sep=""))

		# apply the threshold
		tr_current = current.asc
		tr_current[which(tr_current<best.tr)]=0
		tr_current[which(tr_current>=best.tr)]=1

		# write the new asc
		write.asc(tr_current, file="tr_current.asc") # asc option

		# now need to modify future projections for use by migclim
		# read in each asc.gz as a dataframe, transform values and convert to integers for MigClim
		es.files = list.files(sp.wd, pattern = "RCP85_ukmo-hadcm3", full.names=TRUE)
		for (i in 1:length(es.files)) {
			df.proj = asc2dataframe(es.files[i], gz = TRUE)	#1.2GB
			df.proj[,3] = as.integer(df.proj[,3]*1000)
			my.dataframe2asc(df.proj, filenames=c(paste("mig_proj", i, ".asc", sep=""))) #1.8GB
		}	

		for (type in dispersal.types) {
		
			if (type == "binary") {
				mig.tr = as.integer(best.tr*1000)
			} else {
				mig.tr = 0
			}
		
			for (s in 1:length(dispersal.scenarios)) {			
			
				output = MigClim.migrate(iniDist = "tr_current.asc", 
					hsMap = "mig_proj",
					rcThreshold = mig.tr, 
					envChgSteps = 8,
					dispSteps = 10, 
					dispKernel = dispersal.distances[[s]],
		#			barrier = MigClim.testData[,9], 
		#			barrierType = "strong", 
		#			iniMatAge = 1, 
		#			propaguleProd = c(0.01,0.08,0.5,0.92),
		#			lddFreq = 0.1, 
		#			lddMinDist = 6, 
		#			lddMaxDist = 15,
					simulName = paste("MigClimTest_", type, "_", dispersal.scenarios[s], sep=""), 
					replicateNb = 3,
					overWrite = TRUE, 
		#			testMode = FALSE,
		#			fullOutput = FALSE, 
					keepTempFiles = FALSE)
			} # end for scenario
		} # end for type

		# convert asc to jpegs
		asc.dirs = list.dirs(paste("/rdsi/ccimpacts/NRM/", taxon, "/models/", sp, "/1km/migclim", sep=""), 
			full.names=TRUE)
		asc.files = list.files(asc.dirs[-1], pattern=".asc", full.names=TRUE, recursive = TRUE)
		for (f in asc.files) {
			MigClim.plot(f)
		}
	} # end for species
} # end for taxa

	
