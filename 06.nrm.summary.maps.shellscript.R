# create shell files for summary script

# define location of R scripts
script.dir = "/home/jc140298/NRM/dev"

# define working dir
wd = "/rdsi/ccimpacts/NRM"

# define taxa
taxa = c("mammals", "birds", "reptiles", "amphibians")

#for (taxon in taxa) {
taxon=taxa[4]
	taxon.dir = paste(wd, "/", taxon, sep="")
	
	# get a list of species directories
	species.names = list.files(paste(taxon.dir, "/models", sep="")) #get a list of all the species

#	for (sp in species.names[4:length(species.names)]) { # cycle through each of the species
sp=species.names[1]
		# create the species specific working directory
		sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")

		# create the shell file
		shell.file.name = paste(sp.wd, "/06.nrm.aggregate.maps.", sp, ".sh", sep="")
		
		shell.file = file(shell.file.name, "w")
			cat('#!/bin/bash\n', file=shell.file)
			cat('#PBS -j oe\n', file=shell.file) # combine stdout and stderr into one file
			cat('#PBS -l pmem=2gb\n', file=shell.file)
			cat('#PBS -l nodes=1:ppn=1\n', file=shell.file)
#			cat('#PBS -q bigmem\n', file=shell.file)
			cat('#PBS -l walltime=9999:00:00\n', file=shell.file)
			cat('cd $PBS_O_WORKDIR\n', file=shell.file)
			cat('source /etc/profile.d/modules.sh\n', file=shell.file) # need for java
			cat('module load java\n', file=shell.file) # need for maxent
			cat('module load R\n', file=shell.file) # need for R
			cat("R CMD BATCH --no-save --no-restore '--args wd=\"", wd, "\" taxon=\"", taxon, "\" sp=\"", sp, "\"' ", script.dir, "/06.nrm.aggregate.maps.R ", sp.wd, "/06.nrm.aggregate.maps.", sp, ".Rout \n", sep="", file=shell.file)
		close(shell.file)

		# submit job
		system(paste("qsub ", shell.file.name, sep=""))
		Sys.sleep(5)

#	} # end for species
#} # end for taxon