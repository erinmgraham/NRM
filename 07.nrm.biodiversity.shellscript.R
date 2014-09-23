# shellscript to call biodiversity scripts

# define location of R scripts
script.dir = "/home/jc140298/NRM/dev"

# define working dir
wd = "/rdsi/ccimpacts/NRM"
pbs.dir = paste(wd, "/tmp.pbs", sep=""); setwd(pbs.dir)

# define taxa
taxa = c("mammals", "birds", "reptiles", "amphibians", "weeds")

doPart = "II"
# Part I : create one biodiversity map per taxa based on current realized maps
# Part II : for each taxa, create one biodiversity map per scenario based on projected dispersal maps	
# Part III : create one biodiversity map per es/year/decile combination based on projected dispersal maps
	
for (taxon in taxa) {
	
	# create the shell file
	shell.file.name = paste(pbs.dir, "/07.nrm.biodiversity.part", doPart, "_rcp85.sh", sep="")
	
	shell.file = file(shell.file.name, "w")
		cat('#!/bin/bash\n', file=shell.file)
		cat('#PBS -j oe\n', file=shell.file) # combine stdout and stderr into one file
		cat('#PBS -l pmem=2gb\n', file=shell.file)
		cat('#PBS -l nodes=1:ppn=1\n', file=shell.file)
		cat('#PBS -l walltime=500:00:00\n', file=shell.file)
#		cat('#PBS -l epilogue=/home/jc140298/epilogue/epilogue.sh\n', file=shell.file)
		cat('cd $PBS_O_WORKDIR\n', file=shell.file)
		cat('module load R\n', file=shell.file) # need for R
		cat("R CMD BATCH --no-save --no-restore '--args wd=\"", wd, "\" taxon=\"", taxon, "\" doPart=\"", doPart, "\"' ", script.dir, "/07.nrm.biodiversity.R ", pbs.dir, "/07.nrm.biodiversity.part", doPart, "_rcp85.Rout \n", sep="", file=shell.file)
	close(shell.file)

	# submit job
	system(paste("qsub ", shell.file.name, sep=""))
	Sys.sleep(5)

} # end for taxon