# script to create biodversity maps
# 1 - one per taxa based on current realized maps
# 2 - 288 per taxa based on projected dispersal maps
# 3 - 48 per taxa based on projected dispersal decile maps

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
	# expecting wd, taxon, doPart
}

library(SDMTools)

source("/home/jc140298/NRM/dev/helperFunctions.R") # for getVettingThreshold()

# set the species specific working directories
taxon.dir = paste(wd, "/", taxon, sep="")
biodiv.dir = paste(taxon.dir, "/biodiversity", sep=""); dir.create(biodiv.dir)

# get a list of species directories
species.names = list.files(paste(taxon.dir, "/models", sep="")) #get a list of all the species

# Part I : create one biodiversity map per taxa based on current realized maps
if (doPart == "I") {

	# read in a blank (all 0's) 1km asc to use as base map
	base.asc = read.asc.gz("/home/jc140298/NRM/blank_map_1km.asc.gz")
	
	# cycle through each of the species
	for (sp in species.names) { cat(which(species.names == sp),"...",sep="")

		# set the species specific working directories
		sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
		realized.wd = paste(sp.wd, "/realized", sep="") 

		# read in the vetted current distribution	
		curr.asc = read.asc.gz(paste(realized.wd, "/vet.suit.cur.asc.gz", sep=""))

#for troubleshooting
#pdf(paste(realized.wd, "/vet.suit.cur.pdf", sep=""))		
#plot(raster(curr.asc))
#dev.off()
		# get and apply threshold
		threshold = getVettingThreshold(taxon, sp.wd)
		curr.asc[which(is.finite(curr.asc) & curr.asc >= threshold)] = 1		
		curr.asc[which(is.finite(curr.asc) & curr.asc < threshold)] = 0

		# add curr.asc to base.asc
		base.asc = base.asc + curr.asc
	} # end for species
	
	# write biodiversity map
	write.asc.gz(base.asc, paste(biodiv.dir, "/biodiversity_current", sep=""))
} # end doPart I
	
# Part II : create one biodiversity map per scenario based on projected dispersal maps		
eses = c("RCP45", "RCP85")
gcms = c("cccma-cgcm31", "ccsr-miroc32hi", "ccsr-miroc32med", "cnrm-cm3", "csiro-mk30", "gfdl-cm20",
	"gfdl-cm21", "giss-modeleh", "giss-modeler", "iap-fgoals10g", "inm-cm30", "ipsl-cm4", 
	"mpi-echam5", "mri-cgcm232a", "ncar-ccsm30", "ncar-pcm1", "ukmo-hadcm3", "ukmo-hadgem1")  
years = seq(2015,2085,10)

if (doPart == "II") {
	
	# for each emission scenario
	for (es in eses) { cat(es,"\n")
	
		# for each global circulation model
		for (gcm in gcms) { cat(gcm,"\n")
		
			# create scenario name and output folder
			scenario = paste(es, "_", gcm, sep="")
			sc.out = paste(biodiv.dir, "/", scenario, sep=""); dir.create(sc.out)

			# for each year			
			for (yr in years) { cat(yr,"\n")

				# read in a blank (all 0's) 1km asc to use as base map
				sc.base.asc = read.asc.gz("/home/jc140298/NRM/blank_map_1km.asc.gz")
			
				# for each species
				for (sp in species.names) { cat(which(species.names == sp),"...",sep="")
		
					# set the species specific working directories
					sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
					dispersal.wd = paste(sp.wd, "/dispersal", sep="")
					sc.wd = paste(dispersal.wd, "/", scenario, sep="")
					
					# read in the projected realized distribution
					proj.asc = read.asc.gz(paste(sc.wd, "/", yr, "_realized.asc.gz",sep=""))
	
					# get and apply threshold
					threshold = getVettingThreshold(taxon, sp.wd)
					proj.asc[which(is.finite(proj.asc) & proj.asc >= threshold)] = 1		
					proj.asc[which(is.finite(proj.asc) & proj.asc < threshold)] = 0

					# add curr.asc to sc.base.asc
					sc.base.asc = sc.base.asc + proj.asc
				} # end for spp
				
				# write biodiversity map
				out.filename = paste(sc.out, "/biodiversity_", yr, sep="")
				write.asc.gz(sc.base.asc, out.filename)				
				
			} # end for years	
		} # end for gcms	
	} # end eses
} # end doPart II

# Part III : create one biodiversity map per es/year/decile combination based on projected dispersal maps
deciles = c("tenth", "fiftieth", "ninetieth")

if (doPart == "III") {
	
	# create output folder
	dec.out = paste(biodiv.dir, "/deciles", sep=""); dir.create(dec.out)
	
	# for each emission scenario
	for (es in eses[2]) { cat(es,"\n")
	
		# for each year			
		for (yr in years[4:8]) { cat(yr,"\n")
		
			# for each deciles
			for (dec in deciles) { cat(dec,"\n")

				# create dec.name
				dec.name = paste(es, "_", yr, "_", dec, sep="")
				
				# read in a blank (all 0's) 1km asc to use as base map
				dec.base.asc = read.asc.gz("/home/jc140298/NRM/blank_map_1km.asc.gz")

				# for each species
				for (sp in species.names) { cat(which(species.names == sp),"...",sep="")
		
					# set the species specific working directories
					sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
					dispersal.wd = paste(sp.wd, "/dispersal/deciles", sep="")
					
					# read in the projected realized distribution
					dec.asc = read.asc.gz(paste(dispersal.wd, "/", dec.name, ".asc.gz",sep="" ))

					# get and apply threshold
					threshold = getVettingThreshold(taxon, sp.wd)
					dec.asc[which(is.finite(dec.asc) & dec.asc >= threshold)] = 1		
					dec.asc[which(is.finite(dec.asc) & dec.asc < threshold)] = 0
					
					# add curr.asc to dec.base.asc
					dec.base.asc = dec.base.asc + dec.asc
				} # end for spp
				
				# write biodiversity map
				out.filename = paste(dec.out, "/biodiversity_", dec.name, sep="")
				write.asc.gz(dec.base.asc, out.filename)				
				
			} # end for deciles	
		} # end for years	
	} # end eses
} # end doPart III

			