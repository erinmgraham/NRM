# script to create climate summary files for each region and bioclim variable

library(SDMTools)
library(raster)

# define the working directories
wd = "/rdsi/ccimpacts/NRM"
climate.dir = paste(wd, "/climate/1km", sep="")
bioclims = c("bioclim_01", "bioclim_12")

# read in base csv with region locations
base.csv = read.csv("/home/jc140298/NRM/region.pos.csv")

for (bioclim in bioclims) { cat(bioclim, "\n")

	bioclim.dir = paste(climate.dir, "/", bioclim, sep="")
	
	# create a summary csv of values in each location(cell)
	curr.asc = read.asc.gz(paste(bioclim.dir, "/current/", bioclim, ".asc.gz", sep=""))
	current.vals = extract.data(cbind(base.csv$x, base.csv$y), raster(curr.asc))
	base.csv[,"current"] = current.vals

	# extract projected value for each scenario/year/deciles	
	# define scenarios
	eses = c("RCP45", "RCP85")
	years = seq(2015, 2085, 10)
	deciles = c("tenth", "fiftieth", "ninetieth")
	
	deciles.dir = paste(bioclim.dir, "/deciles", sep="")
Sys.time()
	for (es in eses) { cat(es, "\n")

		for (yr in years) { cat(yr, "\n")

			for (dec in deciles) { cat(dec, "\n")
			
				# define column name
				sc.name = paste(es, "_", yr, "_", dec, sep="")
				
				# define filename and read in asc
				filename = paste(deciles.dir, "/", es, "_", yr, "_", dec, ".asc.gz", sep="")
				proj.asc = read.asc.gz(filename)
				
				# extract values for each location and add to output
				proj.vals = extract.data(cbind(base.csv$x, base.csv$y), raster(proj.asc))
				base.csv[,sc.name] = proj.vals
			} # end deciles
		} # end years
	} # end eses
Sys.time()
	# define regions
	regions = c("State", "IBRA", "NRM", "Kimberly", "NT")
#	region.codes = read.csv("/home/jc140298/NRM/region.codes.csv", header=FALSE, 
#		stringsAsFactors=FALSE)

	# create separate summary files of values for each region	
	for (reg in regions) { cat(reg, "\n")
	
		# determine which column has region data	
		region.col = which(colnames(base.csv) == reg)
		# restrict the data to that particular region and remove NA's
		region.data = as.matrix(na.omit(base.csv[,c(region.col,8:56)]))
		# group the data by state subregion and calculate min, mean, and max		
		region.min = aggregate(region.data, list(region.data[,reg]), FUN=min)
		colnames(region.min)[3:51] = paste(colnames(region.min)[3:51], "_min", sep="")	
		region.max = aggregate(region.data, list(region.data[,reg]), FUN=max)
		colnames(region.max)[3:51] = paste(colnames(region.max)[3:51], "_max", sep="")
		region.mean = aggregate(region.data, list(region.data[,reg]), FUN=mean)	
		colnames(region.mean)[3:51] = paste(colnames(region.mean)[3:51], "_mean", sep="")

		region.summary = cbind(region.min, region.max[3:51], region.mean[3:51])
		colnames(region.summary)[1:2] = c("region", "region_code");  region.summary[,1]=reg

		# save output
		write.csv(region.summary, paste(deciles.dir, "/", reg, ".summary.", bioclim, ".csv", sep=""), 
			row.names=FALSE)
	} # end for region	
} # end for bioclim
