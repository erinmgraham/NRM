#script to run maxent model for NRM

# define the working directory
wd = "/rdsi/ccimpacts/NRM" 

# define the taxa
taxa =  c("mammals", "birds", "reptiles", "amphibians")

# define the spatial scales
scales = c("5km", "1km", "250m")

# define the location of the environmental layers
scenarios.dir = "/rdsi/ctbcc_data/Climate/CIAS/Australia"

# define location of maxent.jar file
maxent.jar = "/home/jc140298/maxent.jar" 

# for each taxon
for (taxon in taxa[1]) {

	# define the taxon dir
	taxon.dir = paste(wd, "/", taxon, sep="")
	
	# get the species list
	species = list.files(paste(taxon.dir, "/models", sep=""))

	# for each species
	for (sp in species[161]) {
	
		# for each scale
#		for (m in 1:length(scales)) {
m=2		
		# define the taxon specific background data
		bkgd.data = paste(wd, "/", taxon, "/", scales[m], "_bkgd.csv", sep="")

		# set the species specific working directory argument
		sp.wd = paste(taxon.dir, "/models/", sp, "/", scales[m], sep=""); setwd(sp.wd) 
		
		# define the sp specific occur data
		occur.data = paste(sp.wd, "/occur.csv", sep="")
		
		# define location of current and future projections
		if (scales[m] == "1km") {
			# no mxe files for current 1km
			current.scenario = paste(scenarios.dir, "/", scales[m], "/baseline.76to05/bioclim", sep="")
#		} else {
#			current.scenario = list.files(paste(scenarios.dir, "/", scales[m], "/baseline.76to05/bioclim_asc", sep=""), 
#				full.names=TRUE)
# EMG need to fix this for asc vs mxe and different scales
		}
		future.scenarios.all = list.files(paste(scenarios.dir, "/", scales[m], "/bioclim_mxe", sep=""),
			full.names=TRUE)
		rcp.future.scenarios = future.scenarios.all[grep("RCP", future.scenarios.all)]
		scenarios.torun = c(current.scenario, rcp.future.scenarios)

		# create the shell file
		shell.file.name = paste(sp.wd, "/01.nrm.model.", sp, ".sh", sep="")
		shell.file = file(shell.file.name, "w")
			cat('#!/bin/bash\n', file=shell.file)
			cat('#PBS -j oe\n', file=shell.file) # combine stdout and stderr into one file
			cat('#PBS -l pmem=8gb\n', file=shell.file)
			cat('#PBS -l nodes=1:ppn=4\n', file=shell.file)
			cat('#PBS -l walltime=100:00:00\n', file=shell.file)
			cat('cd $PBS_O_WORKDIR\n', file=shell.file)
			cat('source /etc/profile.d/modules.sh\n', file=shell.file) # need for java
			cat('module load java\n', file=shell.file) # need for maxent
			# first run maxent with 10 replicates
			cat('java -mx2048m -jar ',maxent.jar, ' -e ',bkgd.data, ' -s ',occur.data, ' -o ',sp.wd, ' nothreshold nowarnings novisible replicates=10 nooutputgrids -r -a \n', sep="", file=shell.file)
			# rename the results file so it won't be overwritten
			cat('cp -af ',sp.wd, '/maxentResults.csv ',sp.wd, '/maxentResults.crossvalid.csv\n', sep="", file=shell.file)
			# run maxent again on full model
			cat('java -mx2048m -jar ',maxent.jar, ' -e ',bkgd.data, ' -s ',occur.data, ' -o ',sp.wd, ' nothreshold nowarnings novisible nowriteclampgrid nowritemess writeplotdata -P -J -r -a \n', sep="", file=shell.file)
			
			# project maxent model
			for (pr in scenarios.torun) {
				cat('java -cp ',maxent.jar, ' density.Project ',sp.wd, '/',sp, '.lambdas ',pr, ' ', basename(pr), '.asc nowriteclampgrid nowritemess fadebyclamping \n', sep="", file=shell.file)
				# zip it
				cat('gzip ', basename(pr), '.asc\n', sep="", file=shell.file)
			}
		close(shell.file)
		
		system(paste("qsub ", shell.file.name, sep=""))
		Sys.sleep(5) # wait 5 sec between job submissions
	} # end for species
} # end for taxon
