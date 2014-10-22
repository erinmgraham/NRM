# this script will take freshwater species gridded data and produce realized maps

library(SDMTools)
source("/home/jc140298/NRM/dev/helperFunctions.R") #my.dataframe2asc

# define working dirs
source.dir = "/home/jc246980/SDM/Realized_gridded"
wd = "/rdsi/ccimpacts/NRM"

# define taxa
taxa = c("crayfish", "fish", "frog", "turtles")

# current realized distributions
for (taxon in taxa) {

	source.taxon.dir = paste(source.dir, "/", taxon, sep="")
	taxon.dir = paste(wd, "/", taxon, sep=""); dir.create(taxon.dir)
	
	# use the list of files to get a list of species directories
	species.files = list.files(source.taxon.dir, pattern="cur.real.grid")
	species.names = sapply(strsplit(species.files, split="[.]"), '[', 1) 

	# cycle through each of the species
	for (sp in species.names) { cat(sp, "\n")
	
		# create the output directories
		sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep=""); dir.create(sp.wd, recursive = TRUE)
		real.wd = paste(sp.wd, "/realized", sep=""); dir.create(real.wd)
		
		# read in the current realized distribution dataframe
		sp.file = paste(source.taxon.dir, "/", species.files[grep(sp,species.files)], sep="")
		load(sp.file) #pos
		
		# use the dataframe of locations and values to generate asc
		setwd(real.wd) # needed for dataframe2asc
		my.dataframe2asc(pos[,4:6], filenames="vet.suit.cur", gz=TRUE)
		rm(pos)
	} # end for species
} # end for taxon

# future realized distributions

future.source.dir = "/rdsi/vol07/ccimpacts/NRM/Realized_gridded"
for (taxon in taxa) {

	source.taxon.dir = paste(source.dir, "/", taxon, sep="")
	taxon.dir = paste(wd, "/", taxon, sep=""); dir.create(taxon.dir)
	
	# use the list of files to get a list of species directories
	species.files = list.files(source.taxon.dir, pattern="cur.real.grid")
	species.names = sapply(strsplit(species.files, split="[.]"), '[', 1) 

	# cycle through each of the species
	for (sp in species.names) { cat(sp, "\n")
	
		# create the output directories
		sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep=""); dir.create(sp.wd, recursive = TRUE)
		real.wd = paste(sp.wd, "/realized", sep=""); dir.create(real.wd)
		
		# read in the current realized distribution dataframe
		sp.file = paste(source.taxon.dir, "/", species.files[grep(sp,species.files)], sep="")
		load(sp.file) #pos
		
		# use the dataframe of locations and values to generate asc
		setwd(real.wd) # needed for dataframe2asc
		my.dataframe2asc(pos[,4:6], filenames="vet.suit.cur", gz=TRUE)
		rm(pos)
	} # end for species
} # end for taxon
