# script to create species summary file of presence/absence for each scenario/year/decile

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
	# expecting wd, taxon, sp
}

source("/home/jc140298/NRM/dev/helperFunctions.R") # for getVettingThreshold()

library(SDMTools)
library(raster)

# define the working directories
nrm.dir = "/home/jc140298/NRM"
taxon.dir = paste(wd, "/", taxon, sep="")
sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
deciles.dir = paste(sp.wd, "/dispersal/deciles", sep="")

# read in base base csv with region locations
base.csv = read.csv(paste(nrm.dir, "/region.pos.csv", sep=""))

# create a summary csv of presence/absence in each location(cell)
# extract current presence/absence
curr.real.asc = read.asc.gz(paste(sp.wd, "/realized/threshold.vet.suit.cur.asc.gz", sep=""))
current.vals = extract.data(cbind(base.csv$x, base.csv$y), raster(curr.real.asc))
base.csv[,"current"] = current.vals

# extract projected presence/absence for each scenario/year/deciles	
# define scenarios
eses = c("RCP45", "RCP85")
years = seq(2015, 2085, 10)
deciles = c("tenth", "fiftieth", "ninetieth")
Sys.time()
for (es in eses) { cat(es, "\n")

	for (yr in years) { cat(yr, "\n")

		for (dec in deciles) { cat(dec, "\n")
		
			# define column name
			sc.name = paste(es, "_", yr, "_", dec, sep="")
			
			# define filename and read in asc
			filename = paste(deciles.dir, "/", es, "_", yr, "_", dec, ".asc.gz", sep="")
			proj.asc = read.asc.gz(filename)

			# get vettting threshold and apply it
			threshold = getVettingThreshold(taxon, sp.wd)
			t.proj.asc = proj.asc
			t.proj.asc[which(is.finite(t.proj.asc) & t.proj.asc>=threshold)] = 1
			t.proj.asc[which(is.finite(t.proj.asc) & t.proj.asc<threshold)] = 0
			
			# extract presence/absence values for each location and add to output
			proj.vals = extract.data(cbind(base.csv$x, base.csv$y), raster(t.proj.asc))
			base.csv[,sc.name] = proj.vals
		} # end deciles
	} # end years
} # end eses
Sys.time()
# EMG output too big and time consuming to save

# create a summary file of presence/absence in each region	
# define regions
regions = c("State", "IBRA", "NRM", "Kimberly", "NT")
#region.codes = read.csv(paste(nrm.dir, "/region.codes.csv", sep=""), header=FALSE, 
#	stringsAsFactors=FALSE)

# State
# determine which column has region data
state.col = which(colnames(base.csv) == "State")
# restrict the data to that particular region and remove NA's
state.data = as.matrix(na.omit(base.csv[,c(state.col,8:56)]))
# group the data by state subregion and determine if present(1) or absent(1)
state.summary = aggregate(state.data, list(state.data[,"State"]), FUN=max)
# rename the first two columns and fill first column with region
colnames(state.summary)[1:2] = c("region", "region_code");  state.summary[,1]="State"
Sys.time()

# NRM
nrm.col = which(colnames(base.csv) == "NRM")
nrm.data = as.matrix(na.omit(base.csv[,c(nrm.col,8:56)]))
nrm.summary = aggregate(nrm.data, list(nrm.data[,"NRM"]), FUN=max)
colnames(nrm.summary)[1:2] = c("region", "region_code");  nrm.summary[,1]="NRM"
Sys.time()

# IBRA
ibra.col = which(colnames(base.csv) == "IBRA")
ibra.data = as.matrix(na.omit(base.csv[,c(ibra.col,8:56)]))
ibra.summary = aggregate(ibra.data, list(ibra.data[,"IBRA"]), FUN=max)
colnames(ibra.summary)[1:2] = c("region", "region_code");  ibra.summary[,1]="IBRA"
Sys.time()

# Kimberly
kim.col = which(colnames(base.csv) == "Kimberly")
kim.data = as.matrix(na.omit(base.csv[,c(kim.col,8:56)]))
kim.summary = aggregate(kim.data, list(kim.data[,"Kimberly"]), FUN=max)
colnames(kim.summary)[1:2] = c("region", "region_code");  kim.summary[,1]="Kimberly"
Sys.time()

# NT
nt.col = which(colnames(base.csv) == "NT")
nt.data = as.matrix(na.omit(base.csv[,c(nt.col,8:56)]))
nt.summary = aggregate(nt.data, list(nt.data[,"NT"]), FUN=max)
colnames(nt.summary)[1:2] = c("region", "region_code");  nt.summary[,1]="NT"
Sys.time()

# combine output into single dataframe 
sp.summary = rbind(state.summary, nrm.summary, ibra.summary, kim.summary, nt.summary)
Sys.time()

# save output
write.csv(sp.summary, paste(deciles.dir, "/summary.presence.absence.csv", sep=""), row.names=FALSE)
Sys.time()

# copy output to create gain/loss dataframe
gainloss = sp.summary
for (r in 1:nrow(gainloss)) {

	# extract currrent presence/absence value
	r.curr = gainloss[r, "current"]
	
	for (c in 4:ncol(gainloss)) {
	
		c.val = gainloss[r,c]
		#if (r.curr == 0 & c.val == 0) {} # do nothing; always absent
		#if (r.curr == 1 & c.val == 1) {} # do nothing; always present
		if (r.curr == 1 & c.val == 0) { gainloss[r,c] = 3 } # loss
		if (r.curr == 0 & c.val == 1) { gainloss[r,c] = 4 } # gain
	} # end for col
} # end for row

# save output
write.csv(gainloss, paste(deciles.dir, "/summary.gain.loss.csv", sep=""), row.names=FALSE)

