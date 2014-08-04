# script to translate expert vetting into matrices of changes
# NOTE this script uses an alternate way to 03.nrm.vet.to.matrix.R (which uses over()) and
# is faster for states matrices, slower for ibras

library(maptools)
library(SDMTools)
library(raster)
library(sp)	#over

source("/home/jc140298/NRM/dev/helperFunctions.R") # function getVettingThreshold

taxa = c("mammals", "birds", "reptiles", "amphibians")
regions = c("states", "ibras")
vet.path = paste("/home/jc140298/NRM/vetting")

for (taxon in taxa) {

	for (region in regions[1]) {
	
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
			region.mat = matrix(data = NA, nrow = nrow(vetted), ncol = 89)
			region.names = c("ARC", "ARP", "AUA", "AVW", "BBN", "BBS", "BEL", "BCH", "BRT", "CAR", "CEA", "CEK", "CER", "CHC",
				"CMC", "COO", "COP", "COS", "CYP", "DAB", "DAC", "DAL", "DEU", "DMR", "DRP", "EIU", "ESP", "EYB", "FIN", "FLB",
				"FUR", "GAS", "GAW", "GES", "GFU", "GID", "GSD", "GUC", "GUP", "GVD", "HAM", "ITI", "JAF", "KAN", "KIN", "LSD",
				"MAC", "MAL", "MDD", "MGD", "MII", "MUL", "MUR", "NAN", "NCP", "NET", "NNC", "NOK", "NSS", "NUL", "OVP", "PCK",
				"PIL", "PSI", "RIV", "SAI", "SCP", "SEC", "SEH", "SEQ", "SSD", "STP", "STU", "SVP", "SWA", "SYB", "TAN", "TCH",
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

			# get the best threshold (expert vetting)
			threshold = getVettingThreshold(taxon, sp.wd)

			# read in the species current asc
			current.asc = read.asc.gz(paste(sp.wd, "/bioclim.asc.gz", sep=""))

			# apply chosen threshold
			tr.current.asc = current.asc
			tr.current.asc[which(tr.current.asc < threshold)]=0
			tr.current.asc[which(tr.current.asc >= threshold)]=1
			rm("current.asc")

			# want to know which regions are populated
			# need a SpatialPointsDataFrame (class(meuse))
			current.raster = raster(tr.current.asc)
			rm("tr.current.asc")

			populated = rep(NA, length(region.names))
			for (p in 1:length(region.names)) {
			
				if (!(p %in% c(18,42,64,66))) {
					poly.mask = polys[polys@data$SP_ID==p,]
					region.mask = mask(current.raster, poly.mask)
					populated[p] = region.mask@data@max
				} else {
					populated[p] = 0
				}
			}
			
			# there may be more than one region to remove, separate them out
			to.remove.sub = gsub(" ", ",", to.remove)
			to.remove.sep = strsplit(to.remove.sub, ",")
			
			# in the matrix, put absence (0) in region specified
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
			col.names = c("species", as.character(1:89))
		}
		region.df = as.data.frame(cbind(vetted$species, region.mat))
		colnames(region.df) = col.names
		write.csv(region.df, file=paste(vet.path, "/", taxon, ".", region, ".matrix_changed.csv", sep=""),
			row.names = FALSE)
	} # end for region
} # end for taxa