# shell file to run freshwater current map creation script

# define location of R scripts
script.dir = "/home/jc140298/NRM/dev"

# define working dir
wd = "/rdsi/ccimpacts/NRM"
pbs.dir = paste(wd, "/tmp.pbs", sep=""); setwd(pbs.dir)

# define taxa
taxa = c("crayfish", "fish", "frog", "turtles")

for (taxon in taxa) {

	# create the shell file
	shell.file.name = paste(pbs.dir, "/08.nrm.freshwater.maps.current.", taxon, ".sh", sep="")
	
	shell.file = file(shell.file.name, "w")
		cat('#!/bin/bash\n', file=shell.file)
		cat('#PBS -j oe\n', file=shell.file) # combine stdout and stderr into one file
		cat('#PBS -l pmem=4gb\n', file=shell.file)
		cat('#PBS -l nodes=1:ppn=1\n', file=shell.file)
		cat('#PBS -l walltime=6:00:00\n', file=shell.file)
		cat('#PBS -l epilogue=/home/jc140298/epilogue/epilogue.sh\n', file=shell.file)
		cat('cd $PBS_O_WORKDIR\n', file=shell.file)
		cat('module load R\n', file=shell.file) # need for R
		cat("R CMD BATCH --no-save --no-restore '--args wd=\"", wd, "\" taxon=\"", taxon, "\"' ", script.dir, "/08.nrm.freshwater.maps.current.R ", pbs.dir, "/08.nrm.freshwater.maps.current.", taxon, ".Rout \n", sep="", file=shell.file)
	close(shell.file)

	# submit job
	system(paste("qsub ", shell.file.name, sep=""))
	Sys.sleep(5)

} # end for taxon