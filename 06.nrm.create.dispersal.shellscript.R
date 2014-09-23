# shell file to run raster version of dispersal limitations

source("/home/jc140298/NRM/dev/helperFunctions.R") # for removeBirds()

# define location of R scripts
script.dir = "/home/jc140298/NRM/dev"

# define working dir
wd = "/rdsi/ccimpacts/NRM"
pbs.dir = paste(wd, "/tmp.pbs", sep=""); setwd(pbs.dir)

# define taxa
taxa = c("mammals", "birds", "reptiles", "amphibians")

# run on a sample of species first to test
samp.spp = list(c(106,123,134,142,167,184,185,186,207,218), 	#mammals
	c(28,47,50,88,167,225,396,492,557,558), 					#birds
	c(41,79,104,281,314,431,437,503),					#reptiles
	c(6,9,69,92,119,142,146,182,185,204))						#amphibians
	
for (taxon in taxa) {

	taxon.dir = paste(wd, "/", taxon, sep="")
	
	# get a list of species directories
	species.names = list.files(paste(taxon.dir, "/models", sep="")) #get a list of all the species
	
	if (taxon == "birds") {
		species.names = removeBirds(species.names)
	}	
	# these birds don't have realized distributions (no vetting polygons available)

	for (sp in species.names) { # cycle through each of the species

		# create the shell file
		shell.file.name = paste(pbs.dir, "/06.nrm.create.dispersal.", sp, ".sh", sep="")
		
		shell.file = file(shell.file.name, "w")
			cat('#!/bin/bash\n', file=shell.file)
			cat('#PBS -j oe\n', file=shell.file) # combine stdout and stderr into one file
			cat('#PBS -l pmem=8gb\n', file=shell.file)
			cat('#PBS -l nodes=1:ppn=1\n', file=shell.file)
			cat('#PBS -l walltime=20:00:00\n', file=shell.file)
# 			cat('#PBS -l epilogue=/home/jc140298/epilogue/epilogue.sh\n', file=shell.file)
			cat('cd $PBS_O_WORKDIR\n', file=shell.file)
			cat('module load R\n', file=shell.file) # need for R
			cat("R CMD BATCH --no-save --no-restore '--args wd=\"", wd, "\" taxon=\"", taxon, "\" sp=\"", sp, "\"' ", script.dir, "/06.nrm.create.dispersal.R ", pbs.dir, "/06.nrm.create.dispersal.", sp, ".Rout \n", sep="", file=shell.file)
		close(shell.file)

		# submit job
		system(paste("qsub ", shell.file.name, sep=""))
		Sys.sleep(5)

		} # end for species
} # end for taxon