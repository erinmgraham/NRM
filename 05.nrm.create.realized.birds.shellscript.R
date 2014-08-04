# shellscripts to create realized distribution maps for birds

# define location of R scripts
script.dir = "/home/jc140298/NRM/dev"

# define working dir
wd = "/rdsi/ccimpacts/NRM"

# define taxa
taxon = "birds"; taxon.dir = paste(wd, "/", taxon, sep="")

# get a list of species directories
species.names = list.files(paste(taxon.dir, "/models", sep="")) #get a list of all the species
noPolygons = c(21,23,27,31,46,48,49,51,52,54,69,72,77,100,102,113,118,119,132:135,143,175,187,190,
	204,209,211,219,229,235,248,279,283,288,292,319,344,346,368,369,397,409,418,426,432,448,454,
	472,489,516,523,524,542,546,556,559,583,591,592)

for (sp in species.names[-noPolygons]) { # cycle through each of the species

	# create the species specific working directory
	sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")

	# create the shell file
	shell.file.name = paste(sp.wd, "/05.nrm.create.realized.birds.", sp, ".sh", sep="")
	
	shell.file = file(shell.file.name, "w")
		cat('#!/bin/bash\n', file=shell.file)
		cat('#PBS -j oe\n', file=shell.file) # combine stdout and stderr into one file
		cat('#PBS -l pmem=8gb\n', file=shell.file)
		cat('#PBS -l nodes=1:ppn=3\n', file=shell.file)
		cat('#PBS -l walltime=1:00:00\n', file=shell.file)
		cat('cd $PBS_O_WORKDIR\n', file=shell.file)
		cat('source /etc/profile.d/modules.sh\n', file=shell.file) # need for java
		cat('module load java\n', file=shell.file) # need for maxent
		cat('module load R\n', file=shell.file) # need for R
		cat("R CMD BATCH --no-save --no-restore '--args wd=\"", wd, "\" taxon=\"", taxon, "\" sp=\"", sp, "\"' ", script.dir, "/05.nrm.create.realized.birds.R ", sp.wd, "/05.nrm.create.realized.birds.", sp, ".Rout \n", sep="", file=shell.file)
	close(shell.file)
		
	# submit job
	system(paste("qsub ", shell.file.name, sep=""))
	Sys.sleep(5)
	
} # end for species