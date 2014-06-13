# this script creates the species threshold vetted current asciis for NRM
# it uses occurrence records and expert opinion to clip the maxent predicted distribution to the empirical distribution

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
	# expecting wd, taxon and sp
}

library(SDMTools)
source("/home/jc140298/NRM/dev/helperFunctions.R") # function getVettingThreshold

vet.path = paste("/home/jc140298/NRM/vetting")

# create the species specific working directory
taxon.dir = paste(wd, "/", taxon, sep="")
sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
		
# create warren dir to hold output files
warren.wd = paste(sp.wd, "/warren", sep=""); dir.create(warren.wd); setwd(warren.wd)
	
# read in the first three columns of the species occurrence file (SPPCODE, lon, lat)
occur = read.csv(paste(sp.wd, "/occur.csv", sep=""))[1:3]

# read in the expert vetting csv generate by 03.nrm.vet.to.matrix.R
vet.states = read.csv(paste(vet.path, "/", taxon, ".states.matrix_changed.csv", sep=""),
	stringsAsFactors = FALSE)
vet.ibras = read.csv(paste(vet.path, "/", taxon, ".ibras.matrix_changed.csv", sep=""),
	stringsAsFactors = FALSE)
		
# using the occurrences, create a state clipping ascii by excluding states where species does not occur
state.clip = read.asc("/home/jc140298/NRM/State_1km_clipasc.asc")
states = extract.data(occur[,2:3], state.clip) #extract the regions occurrences fall within
ustates = unique(states[!is.na(states)]) #identify the unique regions

# check the state vet list for any changes
vet.state.changes = vet.states[vet.states$species == sp,]
if (nrow(vet.state.changes) == 1) {
	exclude.states = which(vet.state.changes == 0)-1 # first column is species name, states will be offset by 1
	new.states = ustates
	for (state in exclude.states) {
		if (state %in% ustates) {
			new.states = new.states[-which(new.states == state)]
		} # end if in
	} # end for
} else {
	new.states = ustates 
} # end if nrow

pos = which(state.clip %in% new.states) #identify locations within these regions
state.clip[which(is.finite(state.clip))] = 0; state.clip[pos] = 1 #change everything to 0 and only locations in bioregions of interest to 1
#write.asc.gz(state.clip,"State.1km.clip.asc") #write out the clipping ascii

# now to the same for IBRAs
ibra.clip = read.asc("/home/jc140298/NRM/IBRA_1km_clipasc.asc")
#EMG not sure if clipping by IBRA occurrences is a good idea??
#ibras = extract.data(occur[,2:3], ibra.clip) #extract the regions occurrences fall within
#uibras = unique(ibras[!is.na(ibras)]) #identify the unique regions
		
# check the IBRA vet list for any changes
vet.ibra.changes = vet.ibras[vet.ibras$species == sp,]
if (nrow(vet.ibra.changes) == 1) {
	presence.ibras = which(vet.ibra.changes == 1,)-1 # first column is species name, ibras will be offset by 1
	ipos = which(ibra.clip %in% presence.ibras) #identify locations within these regions	
	ibra.clip[which(is.finite(ibra.clip))] = 0; ibra.clip[ipos] = 1 #change everything to 0 and only locations in bioregions of interest to 1
} else {
	ibra.clip[which(is.finite(ibra.clip))] = 1 # change everything to 1 so clip will have no effect
}	# end if nrow
#write.asc.gz(ibra.clip,"IBRA.1km.clip.asc") #write out the clipping ascii

# read in the current maxent predicted distribution
predicted.cur.asc = read.asc.gz(paste(sp.wd, "/bioclim.asc.gz", sep="")) 
# apply the region clipping asciis
vet.cur.asc = state.clip*ibra.clip*predicted.cur.asc 
#write.asc.gz(vet.cur.asc , "vet.cur.asc")

# create binary vetted current distribution
# get the best threshold (expert vetting)
threshold = getVettingThreshold(taxon, sp.wd)
if (sp == "Spilocuscus_maculatus") {
	threshold = threshold*2
}
# make a copy of the vetted current distribution asc
t.vet.cur.asc = vet.cur.asc 
# apply threshold to change habitat suitability to binary
t.vet.cur.asc[which(is.finite(t.vet.cur.asc) & t.vet.cur.asc>=threshold)] = 1
t.vet.cur.asc[which(is.finite(t.vet.cur.asc) & t.vet.cur.asc<threshold)] = 0
write.asc.gz(t.vet.cur.asc, "threshold.vet.cur.asc")
#emg I think this is the one used in 009 script
