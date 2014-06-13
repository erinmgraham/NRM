# shell file to run raster version of dispersal limitations

# define location of R scripts
script.dir = "/home/jc140298/NRM/dev"

# define working dir
wd = "/rdsi/ccimpacts/NRM"

# define taxa
taxa = c("mammals", "birds", "reptiles", "amphibians")

# run on a sample of species first to test
samp.spp = list(c(106,123,134,142,167,184,185,186,207,218), 	#mammals
	c(28,47,50,88,167,225,396,492,557,558), 					#birds
	c(41,79,104,281,314,431,437,503),					#reptiles
	c(6,9,69,92,119,142,146,182,185,204))						#amphibians

#for (taxon in taxa) {
taxon=taxa[3]
	taxon.dir = paste(wd, "/", taxon, sep="")
	
	# get a list of species directories
	species.names = list.files(paste(taxon.dir, "/models", sep="")) #get a list of all the species

	for (sp in species.names[-samp.spp[[which(taxa==taxon)]]][81:120]) { # cycle through each of the species
#sp=species.names[samp.spp[[3]][1]]
#sp=species.names[206]
		# create the species specific working directory
		sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")

		# create the shell file
		shell.file.name = paste(sp.wd, "/05.nrm.gridDistance.", sp, ".sh", sep="")
		
		shell.file = file(shell.file.name, "w")
			cat('#!/bin/bash\n', file=shell.file)
			cat('#PBS -j oe\n', file=shell.file) # combine stdout and stderr into one file
			cat('#PBS -l pmem=8gb\n', file=shell.file)
			cat('#PBS -l nodes=1:ppn=4\n', file=shell.file)
#			cat('#PBS -q bigmem\n', file=shell.file)
			cat('#PBS -l walltime=100:00:00\n', file=shell.file)
			cat('cd $PBS_O_WORKDIR\n', file=shell.file)
			cat('source /etc/profile.d/modules.sh\n', file=shell.file) # need for java
			cat('module load java\n', file=shell.file) # need for maxent
			cat('module load R\n', file=shell.file) # need for R
			cat("R CMD BATCH --no-save --no-restore '--args wd=\"", wd, "\" taxon=\"", taxon, "\" sp=\"", sp, "\"' ", script.dir, "/05.nrm.gridDistance.R ", sp.wd, "/05.nrm.gridDistance.", sp, ".Rout \n", sep="", file=shell.file)
		close(shell.file)

		# submit job
		system(paste("qsub ", shell.file.name, sep=""))
		Sys.sleep(10)

		} # end for species
#} # end for taxon