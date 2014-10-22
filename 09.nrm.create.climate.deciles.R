# this script will produce decile (10/50/90) maps for temperature and rainfall at 1km resolution

library(SDMTools)
source("/home/jc140298/NRM/dev/helperFunctions.R") # my.dataframe2asc

# define the location of the environmental layers
current.clim.dir = "/rdsi/vol07/ctbcc_data/Climate/CIAS/Australia/1km/baseline.76to05/bioclim"
future.clim.dir = "/rdsi/vol07/ctbcc_data/Climate/CIAS/Australia/1km/bioclim_asc"

# define working dirs
wd = "/rdsi/ccimpacts/NRM/climate/1km"

# define the years,  scenarios low/high, climate variables
eses = c("RCP45", "RCP85")
years = seq(2015,2085,10)
climate = c("bioclim_01", "bioclim_12")

# read in 1km lon/lat 
df.locs =  read.csv("/home/jc140298/NRM/1km_lat_lon.csv")

# current - just copy original file
#for (clim in climate) { 
	
#	# create the output directory
#	clim.wd = paste(wd, "/", clim, "/current", sep=""); dir.create(clim.wd, recursive=T)

#	# copy the current projection
#	curr.proj = paste(current.clim.dir, "/", clim, ".asc", sep="")
#	system(paste("cp ", curr.proj, " ", clim.wd, sep=""))
#	system(paste("gzip ", clim.wd, "/", clim, ".asc", sep=""))
#}

# future - need to calculate deciles
for (clim in climate) { 
	
	# create the output directory
	clim.wd = paste(wd, "/", clim, sep="")
	deciles.wd = paste(clim.wd, "/deciles", sep=""); dir.create(deciles.wd); setwd(deciles.wd)

	for (es in eses[2]) { cat(es,'\n')

		# list the projections
		future.projs = list.files(future.clim.dir, pattern=es, full.names=TRUE) #n=144

		# for each year
		for (yr in years[4:8]) { cat(yr,'\n')
		
			# limit projections to single year
			yr.projs = future.projs[grep(yr,future.projs)] # n=18
		
			# create variable for scenario name to use for naming files
			scname = paste(es, "_", yr, sep="")
		
			# create a matrix to hold the year's projections, one column per GCM (proj)
			df.proj = matrix(NA,nrow=length(df.locs$x),ncol=length(yr.projs))
			colnames(df.proj) = basename(yr.projs)
			
			# read in each projection map and extract data values; one map per columns
			for (i in 1:length(yr.projs)) { cat(i, "...")

				# extract values for each cell from the projection map
				filename = paste(yr.projs[i], "/", clim, ".asc", sep="")
				df.proj[,basename(yr.projs[i])] = extract.data(data.frame(df.locs$x, df.locs$y), 
					read.asc(filename))

			} # end for projection folders

			# calculate 10,50,90 deciles for each location
			out.deciles = apply(df.proj, 1, quantile, probs = c(0.10,0.50, 0.90), na.rm = TRUE, type=8)
			#EMG not sure what type to use, 7 is the default
				
			# use the deciles to create maps
			tenth = data.frame(cbind(df.locs$y, df.locs$x, t(out.deciles)[,1])); my.dataframe2asc(tenth, paste(scname, "_tenth", sep=""), gz=TRUE)
			fiftieth = data.frame(cbind(df.locs$y, df.locs$x, t(out.deciles)[,2])); my.dataframe2asc(fiftieth, paste(scname, "_fiftieth", sep=""), gz=TRUE)
			ninetieth = data.frame(cbind(df.locs$y, df.locs$x, t(out.deciles)[,3])); my.dataframe2asc(ninetieth, paste(scname, "_ninetieth", sep=""), gz=TRUE)

		} # end for years		
	} # end for es	
} # end es