
# this function will return the best threshold to use for clipping
getVettingThreshold = function(taxon, wd) {

	if (taxon == "birds") {
	
		# read in the maxent results thresholds
		results = read.csv(paste(wd, "/maxentResults.csv", sep=""))
		if (results$Minimum.training.presence.area > 0.8) {
			best.tr = results$Equate.entropy.of.thresholded.and.original.distributions.logistic.threshold/2
		} else {
			best.tr = results$Equate.entropy.of.thresholded.and.original.distributions.logistic.threshold
		}
		
		return(best.tr)
		
	} else if (taxon %in% c("crayfish", "fish", "frog", "turtles")) {
	
			if (taxon == "frog") {
				fw.dir = paste("/home/jc246980/SDM/models_All_", taxon, "/", sp, "/output", sep="")
			} else {
				fw.dir = paste("/home/jc246980/SDM/models_", taxon, "/", sp, "/output", sep="")
			}
			
			fw.results = read.csv(paste(fw.dir, "/maxentResults.csv", sep=""), stringsAsFactors=FALSE)
			fw.threshold.name = "Equate.entropy.of.thresholded.and.original.distributions.logistic.threshold"	
			fw.threshold = as.numeric(fw.results[1,c(fw.threshold.name)])
			
			return(fw.threshold)
	
	} else { # taxon is mammals, reptiles, amphibians but may these may include turtles and frogs
	
		# check for different path to maxentResults
		species.list = read.csv("/home/jc140298/NRM/species_list.csv", stringsAsFactors=FALSE)
		sub.taxon = species.list[species.list$taxon == taxon & species.list$species==sp,]$freshwater
		
		if (length(sub.taxon)==0 | is.na(sub.taxon)) { # there is no subtaxon
			real.taxon = taxon
		} else { 
			real.taxon = sub.taxon
		}	
			
		if (real.taxon %in% c("mammals", "reptiles", "amphibians")) {
		
			# define the possible thresholds
			choose.tr = c("T1", "T2", "T3", "T4")

			# read in aprils' vetting threshold choices
			vetting.tr = read.csv(paste("/home/jc140298/NRM/vetting/", real.taxon, "_thresholds.csv", sep=""), 
				stringsAsFactors=FALSE)

			# in maxentResults.csv, logistic threshold values are in columns 43 47 51 55 59 63 67 71 75
			# read in maxent results
			results = read.csv(paste(wd, "/maxentResults.csv", sep=""))
			# define thresholds
			threshold.names = c("Equal.training.sensitivity.and.specificity.logistic.threshold",
			"Balance.training.omission..predicted.area.and.threshold.value.logistic.threshold",
			"Equate.entropy.of.thresholded.and.original.distributions.logistic.threshold")
					
			# determine the most severe threshold
			most.severe = colnames(results)[which(results[1,]==max(results[1, c(63,71,75)]))]
			most.severe.name = most.severe[which(most.severe %in% threshold.names)][1]
			#EMG note if there are two thresholds equally severe only the first one is used
			threshold.names = c(threshold.names, most.severe.name)
			
			# get the actual values for those thresholds
			thresholds = as.numeric(results[1,c(threshold.names)])
			# adjust severe 
			if (thresholds[4] <= 0.4) {
				thresholds[4] = thresholds[4]*2
				threshold.names[4] = paste("Most.severe*2: ", most.severe.name, sep="")
			} else {
				thresholds[4] = thresholds[4]/2
				threshold.names[4] = paste("Most.severe/2: ", most.severe.name, sep="")
			}
			
			# get the desired threshold based on Aprils selection
			best.tr = thresholds[which(choose.tr == vetting.tr[vetting.tr$species==sp,]$threshold)]
			
			return(best.tr)
			
		} else if (real.taxon %in% c("frog", "turtles")) {

			if (real.taxon == "frog") {
				fw.dir = paste("/home/jc246980/SDM/models_All_", real.taxon, "/", sp, "/output", sep="")
			} else {
				fw.dir = paste("/home/jc246980/SDM/models_", real.taxon, "/", sp, "/output", sep="")
			}
			
			fw.results = read.csv(paste(fw.dir, "/maxentResults.csv", sep=""), stringsAsFactors=FALSE)
			fw.threshold.name = "Equate.entropy.of.thresholded.and.original.distributions.logistic.threshold"	
			fw.threshold = as.numeric(fw.results[1,c(fw.threshold.name)])
			
			return(fw.threshold)
		} # end if real.taxon
	} # end if taxon
} # end function	

# EMG dataframe2asc pads ncol and nrow with +1, removed so all asc have same num of cells
# used below to resample 5km region asc's
my.dataframe2asc = function (tdata, filenames = NULL, outdir = getwd(), gz = FALSE) 
{
    if (is.null(filenames)) {
        filenames = colnames(tdata)[3:length(tdata)]
    }
    else {
        if (length(filenames) != length(3:length(tdata))) 
            stop("variable names must be the same length as the files vector")
        filenames = as.character(filenames)
    }
    for (ii in 3:(length(tdata))) {
        lats = unique(tdata[, 1])
        lats = sort(lats)
        longs = unique(tdata[, 2])
        longs = sort(longs)
        cellsize = min(c(diff(lats), diff(longs)))
        nc = ceiling((max(lats) - min(lats))/cellsize) #+1
        nr = ceiling((max(longs) - min(longs))/cellsize) #+1
        out.asc = as.asc(matrix(NA, nrow = nr, ncol = nc), xll = min(longs), 
            yll = min(lats), cellsize = cellsize)
        out.asc = put.data(tdata[, c(2:1, ii)], out.asc)
        write.asc(out.asc, paste(outdir, "/", filenames[ii - 2], sep = ""), gz = gz)
    }
}

# as above but need 9 rows to make Cassie's freshwater species maps same as mine
my.dataframe2asc_plus9rows = function (tdata, filenames = NULL, outdir = getwd(), gz = FALSE) 
{
    if (is.null(filenames)) {
        filenames = colnames(tdata)[3:length(tdata)]
    }
    else {
        if (length(filenames) != length(3:length(tdata))) 
            stop("variable names must be the same length as the files vector")
        filenames = as.character(filenames)
    }
    for (ii in 3:(length(tdata))) {
        lats = unique(tdata[, 1])
        lats = sort(lats)
        longs = unique(tdata[, 2])
        longs = sort(longs)
        cellsize = min(c(diff(lats), diff(longs)))
        nc = ceiling((max(lats) - min(lats))/cellsize) +9
        nr = ceiling((max(longs) - min(longs))/cellsize) #+1
        out.asc = as.asc(matrix(NA, nrow = nr, ncol = nc), xll = min(longs), 
            yll = min(lats), cellsize = cellsize)
        out.asc = put.data(tdata[, c(2:1, ii)], out.asc)
        write.asc(out.asc, paste(outdir, "/", filenames[ii - 2], sep = ""), gz = gz)
    }
}

# this function resamples the 5km regions (state and ibra) down to 1km
library(SDMTools)
regions = c("State", "IBRA")

# resampleRegion(regions[2]) # to run
resampleRegion = function(region) {
	# read in 5km region file
	fiveKM.region.clipasc = read.asc(paste("/home/jc140298/NRM/", region, ".asc", sep=""))

	# need a 1km map of Australia to get lon/lat
	# EMG does it matter what map I read in??
	df.base = asc2dataframe("/rdsi/ctbcc_data/Climate/CIAS/Australia/1km/baseline.76to05/base.asc")

	resample.region = extract.data(df.base[,c("x", "y")], fiveKM.region.clipasc)
	df.resample = df.base
	df.resample$var.1 = resample.region
	my.dataframe2asc(df.resample, filenames=paste("NRM/", regions, "_1km_clipasc", sep=""))
}

noPolygons = c("Acrocephalus_stentoreus", "Aerodramus_terraereginae", "Alcedo_pusilla", 
		"Amaurornis_moluccana", "Anas_gibberifrons", "Anas_platyrhynchos", "Anas_querquedula", 
		"Anas_superciliosa", "Anhinga_novaehollandiae", "Anser_anser", "Ardea_cocoi", "Ardea_modesta",
		"Arses_lorealis", "Cacomantis_pallidus", "Cairina_moschata", "Carduelis_chloris", "Certhionyx_niger", 
		"Certhionyx_pectoralis", "Chrysococcyx_basalis", "Chrysococcyx_lucidus", "Chrysococcyx_minutillus", 
		"Chrysococcyx_osculans", "Circus_aeruginosus", "Corvus_splendens", "Cuculus_saturatus", "Cygnus_olor", 
		"Ducula_bicolor", "Egretta_sacra", "Elanus_caeruleus", "Eopsaltria_pulverulenta", "Esacus_magnirostris", 
		"Excalfactoria_chinensis", "Gallus_gallus", "Heteromyias_cinereifrons", "Hirundo_ariel", 
		"Ixobrychus_dubius", "Lalage_sueurii", "Lonchura_punctulata", "Meleagris_gallopavo", 
		"Meliphaga_fordiana", "Motacilla_cinerea", "Motacilla_tschutschensis", "Numida_meleagris", 
		"Pachycephala_griseiceps", "Pandion_cristatus", "Pavo_cristatus", "Petroica_boodang", 
		"Phasianus_colchicus", "Phylidonyris_albifrons", "Podargus_papuensis", "Porzana_cinerea", 
		"Pycnonotus_jocosus", "Rhipidura_albiscapa", "Rhipidura_dryas", "Sphecotheres_viridis", 
		"Sterna_nereis", "Streptopelia_senegalensis", "Sturnus_vulgaris", "Turdus_philomelos", 
		"Tyto_capensis", "Tyto_javanica")
#noPolygons = c(21,23,27,31,46,48,49,51,52,54,69,72,77,100,102,113,118,119,132:135,143,175,187,190,
#	204,209,211,219,229,235,248,279,283,288,292,319,344,346,368,369,397,409,418,426,432,448,454,
#	472,489,516,523,524,542,546,556,559,583,591,592)
		
# this function removes birds that do not have polygons by name
# I had an issue where "Anseranas_semipalmata" and "Anser_anser" were sorted differently
removeBirds = function(species.names) {
	
	new.species.names = species.names	
	for (i in 1:length(noPolygons)) {

		new.species.names = new.species.names[-which(new.species.names == noPolygons[i])]
	}
	
	return(new.species.names)
}