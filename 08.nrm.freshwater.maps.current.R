# this script will take freshwater species gridded data and produce current realized distributions maps

# read in the arguments listed at the command line
args=(commandArgs(TRUE))  
# check to see if arguments are passed
if(length(args)==0){
    print("No arguments supplied.")
    # leave all args as default values
} else {
	for(i in 1:length(args)) { 
		eval(parse(text=args[[i]])) 
	}
	# expecting wd, taxon
}

library(SDMTools)
source("/home/jc140298/NRM/dev/helperFunctions.R") #my.dataframe2asc

# define working dirs
source.dir = "/home/jc246980/SDM/Realized_gridded"
source.taxon.dir = paste(source.dir, "/", taxon, sep="")
taxon.dir = paste(wd, "/", taxon, sep=""); dir.create(taxon.dir)

# use the list of files to get a list of species directories
species.files = list.files(source.taxon.dir, pattern="cur.real.grid")
species.names = sapply(strsplit(species.files, split="[.]"), '[', 1) 

if (taxon == "fish") {
	# some subspecies names are lost, need to add back
	matches = which(species.names == "Melanotaenia_splendida") # should be three 106-108
	species.names[matches[1]] = "Melanotaenia_splendida.inornata"
	species.names[matches[2]] = "Melanotaenia_splendida.splendida"
	species.names[matches[3]] = "Melanotaenia_splendida.tatei"
}	
		
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
	my.dataframe2asc_plus9rows(pos[,4:6], filenames="pos.dataframe", gz=TRUE)
	rm(pos)
	
	# need to remove holes (areas with no data) from converted asc
	pos.asc = read.asc.gz("pos.dataframe.asc.gz") # read in asc
	new.pos.asc = pos.asc # make a copy
	new.pos.asc[is.na(new.pos.asc)] = 10 # change NA's to 10
	base.asc = read.asc.gz("/home/jc140298/NRM/blank_map_1km.asc.gz") # read in blank asc
	new.pos.asc = new.pos.asc + base.asc # combine asc's to put NA's in right place
	new.pos.asc[new.pos.asc == 10] = 0 # change the remaining NA's to zero's (absences)
	write.asc.gz(new.pos.asc, "vet.suit.cur") # write new asc
} # end for species
