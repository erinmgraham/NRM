# script to translate expert vetting into matrices of changes

library(maptools)
library(SDMTools)
library(raster)
library(sp)	#over
source("/home/jc140298/NRM/dev/helperFunctions.R") # function getVettingThreshold

taxa = c("mammals", "birds", "reptiles", "amphibians")
regions = c("states", "ibras")

vet.path = paste("/home/jc140298/NRM/vetting")

for (taxon in taxa) {

	for (region in regions[2]) {
	
		# read in the region boundaries with the same CRS as current.asc and vetting lists
		# create a matrix with a line for each species needing changes
		if (region == "states") {
			polys = readShapePoly("/home/jc140298/NRM/State_poly.shp", proj4string=CRS("+proj=longlat +datum=WGS84"))
			vetted = read.csv(paste(vet.path, "/",  taxon, "_vetting_list_states.csv", sep=""),
				stringsAsFactors=FALSE)
			region.mat = matrix(data = NA, nrow = nrow(vetted), ncol = 8)
			region.names = c("NSW", "VIC", "QLD", "SA", "WA", "TAS", "NT", "ACT")
		} else {
			polys = readShapePoly("/home/jc140298/NRM/IBRA_poly.shp", proj4string=CRS("+proj=longlat +datum=WGS84"))
			vetted = read.csv(paste(vet.path, "/",  taxon, "_vetting_list_ibras.csv", sep=""),
				stringsAsFactors=FALSE)
			region.mat = matrix(data = NA, nrow = nrow(vetted), ncol = 85)
			region.names = c("ARC", "ARP", "AUA", "AVW", "BBN", "BBS", "BEL", "BCH", "BRT", "CAR", "CEA", "CEK", "CER", "CHC",
				"CMC", "COO", "COP", "CYP", "DAB", "DAC", "DAL", "DEU", "DMR", "DRP", "EIU", "ESP", "EYB", "FIN", "FLB",
				"FUR", "GAS", "GAW", "GES", "GFU", "GID", "GSD", "GUC", "GUP", "GVD", "HAM", "JAF", "KAN", "KIN", "LSD",
				"MAC", "MAL", "MDD", "MGD", "MII", "MUL", "MUR", "NAN", "NCP", "NET", "NNC", "NOK", "NSS", "NUL", "OVP", "PCK",
				"PIL", "RIV", "SCP", "SEC", "SEH", "SEQ", "SSD", "STP", "STU", "SVP", "SWA", "SYB", "TAN", "TCH",
				"TIW", "TNM", "TNS", "TSE", "TSR", "TWE", "VIB", "VIM", "WAR", "WET", "YAL")
		}
		# colnames: species threshold state_to_remove or IBRA_to_remove

		for (i in 1:nrow(vetted)) { cat(i,'of',nrow(vetted),' species\n')
		
			# get column of regions to remove and change populated
			if (region == "states") {
				to.remove = vetted[i, "state_to_remove"]
			} else {
				to.remove = vetted[i, "IBRA_to_remove"]
			}

			# get the species name
			sp = vetted[i,"species"]
			sp.wd = paste("/rdsi/ccimpacts/NRM/", taxon, "/models/", sp, "/1km", sep="")
			
			# get the expert's choice of threshold
			threshold = getVettingThreshold(taxon, sp.wd)
			
			# read in the species current asc
			current.asc = read.asc.gz(paste(sp.wd, "/bioclim.asc.gz", sep=""))

			# apply chosen threshold
			tr.current.asc = current.asc
			tr.current.asc[which(tr.current.asc < threshold)]=0
			tr.current.asc[which(tr.current.asc >= threshold)]=1
			rm("current.asc")
			# plot the maps
		#	plot(current.raster)
		#	plot(states, add=TRUE)

			# add labels to regions
		#	invisible(text(coordinates(states), labels=as.character(states$SP_ID), 
		#		cex=1.5))

			# want to know which regions are populated
			# need a SpatialPointsDataFrame (class(meuse))
			current.raster = raster(tr.current.asc)
			rm("tr.current.asc")
			current.spdf = as(current.raster, "SpatialPointsDataFrame")
			rm("current.raster")
			
			totals = over(polys, current.spdf, fn=sum)
			rm("current.spdf")

			# NOTE over() data.frame starts at row 0
			# change totals to start at row 1 and transform to P/A 1/0
			populated = totals$layer
			populated[populated > 0] = 1
			
			# there may be more than one, separate them out
			to.remove.sub = gsub(" ", ",", to.remove)
			to.remove.sep = strsplit(to.remove.sub, ",")
			
			for (j in 1:length(to.remove.sep[[1]])) {
				index = which(region.names == to.remove.sep[[1]][j])
				populated[index] = 0
			}
			
			# write PA's to matrix
			region.mat[i,] = populated
		} # end for row vetted (species)

		# append col names to matrix and save dataframe as csv
		if (region == "states") {
			col.names = c("species", "NSW-1", "VIC-2", "QLD-3", "SA-4", "WA-5", "TAS-6", "NT-7", "ACT-8")
		} else {
			ibra.ids = as.character(seq(1:89)[-c(18,42,64,66)]) # four IBRAs are no on the map
			# EMG this codes hasn't been tested since I made the change in line 104
			# EMG Need to pad the final matrix so the IBRA id's match the column numbers
			col.names = c("species", ibra.ids)
		}
		region.df = as.data.frame(cbind(vetted$species, region.mat))
		colnames(region.df) = col.names
		write.csv(region.df, file=paste(vet.path, "/", taxon, ".", region, ".matrix_changed.csv", sep=""),
			row.names = FALSE)
	} # end for region
} # end for taxa