# shellscripts to create vetting maps for experts to vet
# NOTE "birds" have been vetted previously by Birdlife

# define location of R scripts
script.dir = "/home/jc140298/NRM/dev"

# define working dir
wd = "/rdsi/ccimpacts/NRM"
pbs.dir = paste(wd, "/tmp.pbs", sep=""); setwd(pbs.dir)

# define taxa
taxa = c("mammals", "reptiles", "amphibians", "weeds")

# create the individual shell scripts
for (taxon in taxa) {

	taxon.dir = paste(wd, "/", taxon, sep="")
	
	# get a list of species directories
	species.names = list.files(paste(taxon.dir, "/models", sep="")) #get a list of all the species

	for (sp in species.names) { # cycle through each of the species

		# set the species arg
		species.arg = sp

		# create the species specific working directory argument
		sp.wd.arg = paste(taxon.dir, "/models/", sp, "/1km", sep="")
			
		# create the shell file
		shell.file.name = paste(pbs.dir, "/02.nrm.vet.current.", sp, ".sh", sep="")
		
		shell.file = file(shell.file.name, "w")
			cat('#!/bin/bash\n', file=shell.file)
			cat('#PBS -j oe\n', file=shell.file) # combine stdout and stderr into one file
			cat('#PBS -l pmem=8gb\n', file=shell.file)
			cat('#PBS -l nodes=1:ppn=1\n', file=shell.file)
			cat('#PBS -l walltime=100:00:00\n', file=shell.file)
#			cat('#PBS -l epilogue=/home/jc140298/epilogue/epilogue.sh\n', file=shell.file)
			cat('cd $PBS_O_WORKDIR\n', file=shell.file)
			cat('module load R\n', file=shell.file) # need for R
			cat("R CMD BATCH --no-save --no-restore '--args sp.wd=\"", sp.wd.arg, "\" sp=\"", species.arg, "\"' ", script.dir, "/02.nrm.vet.current.R ", pbs.dir, "/02.nrm.vet.current.", sp, ".Rout \n", sep="", file=shell.file)
		close(shell.file)
			
		# submit job
		system(paste("qsub ", shell.file.name, sep=""))
		Sys.sleep(5) # wait 5 sec between job submissions
		
	} # end for species
} # end for taxon