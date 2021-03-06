# creates the shell scripts to do the species vetting clip regions for NRM

# define location of R scripts
script.dir = "/home/jc140298/NRM/dev"

# define working dir
wd = "/rdsi/ccimpacts/NRM"

# define taxa
taxa = c("mammals", "birds", "reptiles", "amphibians")

samp.spp = list(c(120,138,151,159,189,206,207,208,230,242), 	#mammals
	c(28,47,50,88,167,225,396,492,557,558), 					#birds
	c(46,91,118,251,313,361,402,507,513,588),					#reptiles
	c(6,11,81,106,133,156,160,198,202,223))						#amphibians

# create the individual shell scripts
#for (taxon in taxa) {
taxon="reptiles"
	taxon.dir = paste(wd, "/", taxon, sep="")
	
	# get a list of species directories
	species.names = list.files(paste(taxon.dir, "/models", sep="")) #get a list of all the species

#	for (sp in species.names[samp.spp[[which(taxa==taxon)]]]) { # cycle through each of the species
sp=species.names[46]
		# create the species specific working directory
		sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")

		# create the shell file
		shell.file.name = paste(sp.wd, "/05.create.dispersal.matrix.", sp, ".sh", sep="")
		
		shell.file = file(shell.file.name, "w")
			cat('#!/bin/bash\n', file=shell.file)
			cat('#PBS -j oe\n', file=shell.file) # combine stdout and stderr into one file
			cat('#PBS -l pmem=4gb\n', file=shell.file)
			cat('#PBS -l nodes=1:ppn=2\n', file=shell.file)
			cat('#PBS -l walltime=9999:00:00\n', file=shell.file)
			cat('cd $PBS_O_WORKDIR\n', file=shell.file)
			cat('source /etc/profile.d/modules.sh\n', file=shell.file) # need for java
			cat('module load java\n', file=shell.file) # need for maxent
			cat('module load R\n', file=shell.file) # need for R
			cat("R CMD BATCH --no-save --no-restore '--args wd=\"", wd, "\" taxon=\"", taxon, "\" sp=\"", sp, "\"' ", script.dir, "/05.nrm.create.dispersal.matrix.R ", sp.wd, "/05.nrm.create.dispersal.matrix.", sp, ".Rout \n", sep="", file=shell.file)
		close(shell.file)
			
		# submit job
		system(paste("qsub ", shell.file.name, sep=""))
		Sys.sleep(5)

#	} # end for species
#} # end for taxon
	
