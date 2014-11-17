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

library(SDMTools)
library(raster)

# define the working directories
nrm.dir = "/home/jc140298/NRM"
taxon.dir = paste(wd, "/", taxon, sep="")
sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
deciles.dir = paste(sp.wd, "/dispersal/deciles", sep="")

# read in base base csv with region locations
base.csv = read.csv(paste(nrm.dir, "/region.pos.csv", sep=""))

source("/home/jc140298/NRM/dev/helperFunctions.R") # for getVettingThreshold()
threshold = getVettingThreshold(taxon, sp.wd)

# create a summary csv of presence/absence in each location(cell)
# extract current presence/absence
if (taxon %in% c("mammals", "birds", "reptiles", "amphibians")) {
	curr.real.asc = read.asc.gz(paste(sp.wd, "/realized/threshold.vet.suit.cur.asc.gz", sep=""))
} else { # threshold not applied to current asc for freshwater species
	vet.asc = read.asc.gz(paste(sp.wd, "/realized/vet.suit.cur.asc.gz", sep=""))
	curr.real.asc = vet.asc
	curr.real.asc[which(is.finite(curr.real.asc) & curr.real.asc >= threshold)] = 1
	curr.real.asc[which(is.finite(curr.real.asc) & curr.real.asc < threshold)] = 0
}	
current.vals = extract.data(cbind(base.csv$x, base.csv$y), raster(curr.real.asc))
base.csv[,"current"] = current.vals

# extract projected presence/absence for each scenario/year/deciles	
# define scenarios
eses = c("RCP45", "RCP85")
years = seq(2015, 2085, 10)
deciles = c("tenth", "fiftieth", "ninetieth")

for (es in eses) { cat(es, "\n")

	for (yr in years) { cat(yr, "\n")

		for (dec in deciles) { cat(dec, "\n")
		
			# define column name
			sc.name = paste(es, "_", yr, "_", dec, sep="")
			
			# define filename and read in asc
			filename = paste(deciles.dir, "/", es, "_", yr, "_", dec, ".asc.gz", sep="")
			proj.asc = read.asc.gz(filename)

			# apply vetting threshold
			t.proj.asc = proj.asc
			t.proj.asc[which(is.finite(t.proj.asc) & t.proj.asc>=threshold)] = 1
			t.proj.asc[which(is.finite(t.proj.asc) & t.proj.asc<threshold)] = 0
			
			# extract presence/absence values for each location and add to output
			proj.vals = extract.data(cbind(base.csv$x, base.csv$y), raster(t.proj.asc))
			base.csv[,sc.name] = proj.vals
		} # end deciles
	} # end years
} # end eses

# create a summary file of presence/absence in each region	
# define regions
regions = c("State", "IBRA", "NRM", "Kimberly", "NT")
#region.codes = read.csv(paste(nrm.dir, "/region.codes.csv", sep=""), header=FALSE, 
#	stringsAsFactors=FALSE)
sp.summary = NULL

for (reg in regions) { cat(reg, "\n")

	# determine which column has region data
	region.col = which(colnames(base.csv) == reg)
	# restrict the data to that particular region and remove NA's
	region.data = as.matrix(na.omit(base.csv[,c(region.col,8:56)]))
	# group the data by subregion and determine if present(1) or absent(1)
	region.summary = aggregate(region.data, list(region.data[,reg]), FUN=max)
	# rename the first two columns and fill first column with region
	colnames(region.summary)[1:2] = c("region", "region_code");  region.summary[,1]=reg
	sp.summary = rbind(sp.summary, region.summary)
	Sys.time()
} # end for region

# save output
write.csv(sp.summary, paste(deciles.dir, "/summary.presence.absence.csv", sep=""), row.names=FALSE)

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

