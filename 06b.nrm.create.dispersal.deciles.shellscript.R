# create shell files for deciles script

# define location of R scripts
script.dir = "/home/jc140298/NRM/dev"

# define working dirs
wd = "/rdsi/ccimpacts/NRM"
pbs.dir = paste(wd, "/tmp.pbs", sep=""); setwd(pbs.dir)

# define taxa
taxa = c("mammals", "birds", "reptiles", "amphibians", "crayfish", "fish", "frog", "turtles") #, "weeds")
	
for (taxon in taxa[5:8]) {

	taxon.dir = paste(wd, "/", taxon, sep="")
	
	# get a list of species directories
	species.names = list.files(paste(taxon.dir, "/models", sep="")) #get a list of all the species
	
	for (sp in species.names) { # cycle through each of the species
	
		# create the shell file
		shell.file.name = paste(pbs.dir, "/06b.nrm.create.dispersal.deciles.", sp, ".sh", sep="")
		
		shell.file = file(shell.file.name, "w")
			cat('#!/bin/bash\n', file=shell.file)
			cat('#PBS -j oe\n', file=shell.file) # combine stdout and stderr into one file
			cat('#PBS -l pmem=8gb\n', file=shell.file)
			cat('#PBS -l nodes=1:ppn=1\n', file=shell.file)
			cat('#PBS -l walltime=20:00:00\n', file=shell.file)
#			cat('#PBS -l epilogue=/home/jc140298/epilogue/epilogue.sh\n', file=shell.file)
			cat('cd $PBS_O_WORKDIR\n', file=shell.file)
			cat('module load R\n', file=shell.file) # need for R
			cat("R CMD BATCH --no-save --no-restore '--args wd=\"", wd, "\" taxon=\"", taxon, "\" sp=\"", sp, "\"' ", script.dir, "/06b.nrm.create.dispersal.deciles.R ", pbs.dir, "/06b.nrm.create.dispersal.deciles.", sp, ".Rout \n", sep="", file=shell.file)
		close(shell.file)

		# submit job
		system(paste("qsub ", shell.file.name, sep=""))
		Sys.sleep(5)

	} # end for species
} # end for taxon