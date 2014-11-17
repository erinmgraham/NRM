# script to create summary files for each region

# define the working directories
wd = "/rdsi/ccimpacts/NRM"
summary.dir = paste(wd, "/summary", sep="")

# define taxa
taxa = c("mammals", "birds", "reptiles", "amphibians", "crayfish", "fish") #"weeds")

# collate all the species' summary.gain.loss.csv's
sp.summary.out = NULL
for (taxon in taxa) { cat(taxon, "\n")

	taxon.dir = paste(wd, "/", taxon, sep="")
	
	# get a list of species directories
	species.names = list.files(paste(taxon.dir, "/models", sep="")) #get a list of all the species

	for (sp in species.names) { # cycle through each of the species

		# create the species specific working directory
		sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
		deciles.dir = paste(sp.wd, "/dispersal/deciles", sep="")
		
		# get the species summary file
		sp.sum.filename = paste(deciles.dir, "/summary.gain.loss.csv", sep="")
		if (file.exists(sp.sum.filename)) {
			sp.sum.file= read.csv(sp.sum.filename)
			taxon.name = rep(taxon, nrow(sp.sum.file)) # to add column with taxon info
			sp.name = rep(sp, nrow(sp.sum.file)) # to add column with species info
			sp.sum.name = cbind(sp.sum.file, taxon.name, sp.name) # add columns together
			sp.summary.out = rbind(sp.summary.out, sp.sum.name) # rows of species together
		} else { # record for troubleshooting
			outfilename = paste(summary.dir, "/missing.sp.summary.files.txt", sep="")
			index = which(species.names == sp) 
			write(c(taxon, index, sp), file = outfilename, ncolumns = 3, append=TRUE, sep = "\t")
		} # end if
	} # end for species
} # end for taxon	

# save output
write.csv(sp.summary.out, paste(summary.dir, "/temp.combined.species.summary.csv", sep=""), row.names=FALSE)

# define regions 
regions = c("State", "IBRA", "NRM", "Kimberly", "NT")
region.codes = read.csv("/home/jc140298/NRM/region.codes.csv", header=FALSE, stringsAsFactors=FALSE)

# define climate variables
clim.vars = c("bioclim_01", "bioclim_12"); db.clim.vars = c("t", "p") # annual mean temperature, precipitation

# collate all the climate variable data into single file
clim.summary.out = NULL
for (clim in clim.vars) {

	clim.dir = paste(wd, "/climate/1km/", clim, "/deciles", sep="")
	clim.summary.data = NULL
			
	for (reg in regions) {

		reg.clim.data = read.csv(paste(clim.dir, "/", reg, ".summary.", clim, ".csv", sep=""), 
			stringsAsFactors=FALSE)
		clim.summary.data = rbind(clim.summary.data, reg.clim.data)
		clim.name.fill = rep(clim, nrow(clim.summary.data))
		clim.summary.prep = cbind(clim.name.fill, clim.summary.data); colnames(clim.summary.prep)[1] = "bioclim"
		
	}	
	clim.summary.out = rbind(clim.summary.out, clim.summary.prep)
} # end for clim	
write.csv(clim.summary.out, paste(summary.dir, "/temp.climate.summary.csv", sep=""), row.names=FALSE)


# collate summaries for each region into separate files
# read in combined species and climate output summaries if not already in memory
#sp.summary.out = read.csv(paste(summary.dir, "/temp.combined.species.summary.csv", sep=""))
#clim.summary.out = read.csv(paste(summary.dir, "/temp.climate.summary.csv", sep=""))

# define scenarios
eses = c("RCP45", "RCP85"); db.eses = c("lo", "hi")
years = seq(2015, 2085, 10)
deciles = c("tenth", "fiftieth", "ninetieth"); db.deciles = c("10th", "50th", "90th")

clim.vals = c("min", "max", "mean")

for (r in 1:length(regions)) { cat(regions[r], "\n")
	
	sub.regions = unique(sp.summary.out[sp.summary.out$region == regions[r],]$region_code)
		
	for (sr in sub.regions) { cat(sr, "\n")
	
		# create a file to hold output for region
		sub.region.name = region.codes[region.codes[,2] == regions[r] & region.codes[,3] == sr,][,4]
		sub.region.name = gsub(" ", "_", sub.region.name) # replace spaces in name with underscores
		outfilename = paste(summary.dir, "/", regions[r], "_", sub.region.name, ".txt", sep="")
		write("{", file=outfilename, append=TRUE)

		# collate baseline data
		# for climate
		clim.sub.data = clim.summary.out[clim.summary.out$region == regions[r] & clim.summary.out$region_code == sr,]
		curr.clim.sub.data = clim.sub.data[c(1:2,grep("current", colnames(clim.sub.data)))]
		for (b in 1:length(clim.vars)) {

			curr.bio.clim = curr.clim.sub.data[curr.clim.sub.data$bioclim == clim.vars[b],]
			
			for (val in clim.vals) {
			
				curr.value = as.numeric(curr.bio.clim[grep(val, colnames(curr.bio.clim))])
				write(paste("\t\"baseline_", db.clim.vars[b], "_", val, "\": ", curr.value, ",", sep=""), 
					file=outfilename, append=TRUE)
			} # end for value
		} # end for clim.vars	

		# for all taxa		
		sub.data = sp.summary.out[sp.summary.out$region == regions[r] & sp.summary.out$region_code == sr,]
	
		all.count = nrow(sub.data[sub.data$current == 1,])
		write(paste("\t\"baseline_b_all_count\": ", all.count, ",", sep=""), file=outfilename, 
			append=TRUE)
		# for each taxon
		for (taxon in taxa[-5]) {
			taxon.count = nrow(sub.data[sub.data$taxon.name == taxon & sub.data$current == 1,])
			write(paste("\t\"baseline_b_", taxon, "_count\": ", taxon.count, ",", sep=""), 
				file=outfilename, append=TRUE)
		} # end for taxon		
							
		# collate scenario data
		for (e in 1:length(eses)) {
			for (yr in years) {
				for (d in 1:length(deciles)) {
				
					# define scenario name (for output file) and column name (to access column)
					# NOTE: DB and I named things differently
					db.sc.name = paste(db.eses[e], "_", yr, sep="")	
					sc.col.name = paste(eses[e], "_", yr, "_", deciles[d], sep="")		

					# for climate
					sc.clim.sub.data = clim.sub.data[c(1:2,grep(sc.col.name, colnames(clim.sub.data)))]
					for (b in 1:length(clim.vars)) {

						sc.bio.clim = sc.clim.sub.data[sc.clim.sub.data$bioclim == clim.vars[b],]
						
						for (val in clim.vals) {
						
							sc.value = as.numeric(sc.bio.clim[grep(val, colnames(sc.bio.clim))])
							write(paste("\t\"", db.sc.name, "_", db.clim.vars[b], "_", val, "_", db.deciles[d], "\": ", sc.value, ",", sep=""), 
								file=outfilename, append=TRUE)
						} # end for value
					} # end for clim.vars
		
					# for all taxa
					sc.all.count = nrow(sub.data[sub.data[,sc.col.name] == 1 | sub.data[,sc.col.name] == 4,])
					write(paste("\t\"", db.sc.name, "_b_all_count_", db.deciles[d], "\": ", sc.all.count, ",", sep=""), 
						file=outfilename, append=TRUE)
					sc.all.kept = nrow(sub.data[sub.data[,sc.col.name] == 1,])
					write(paste("\t\"", db.sc.name, "_b_all_kept_", db.deciles[d], "\": ", sc.all.kept, ",", sep=""), 
						file=outfilename, append=TRUE)
					sc.all.loss = nrow(sub.data[sub.data[,sc.col.name] == 3,])
					write(paste("\t\"", db.sc.name, "_b_all_loss_", db.deciles[d], "\": ", sc.all.loss, ",", sep=""), 
						file=outfilename, append=TRUE)
					sc.all.gain = nrow(sub.data[sub.data[,sc.col.name] == 4,])
					write(paste("\t\"", db.sc.name, "_b_all_gain_", db.deciles[d], "\": ", sc.all.gain, ",", sep=""), 
						file=outfilename, append=TRUE)
					
					# for each taxon
					for (taxon in taxa[-5]) {
						sc.taxon.count = nrow(sub.data[sub.data$taxon.name == taxon & (sub.data[,sc.col.name] == 1 | sub.data[,sc.col.name] == 4),])
						write(paste("\t\"", db.sc.name, "_b_", taxon, "_count_", db.deciles[d], "\": ", sc.taxon.count, ",", sep=""), 
							file=outfilename, append=TRUE)
						sc.taxon.kept = nrow(sub.data[sub.data$taxon.name == taxon & sub.data[,sc.col.name] == 1,])
						write(paste("\t\"", db.sc.name, "_b_", taxon, "_kept_", db.deciles[d], "\": ", sc.taxon.kept, ",", sep=""), 
							file=outfilename, append=TRUE)
						sc.taxon.loss = nrow(sub.data[sub.data$taxon.name == taxon & sub.data[,sc.col.name] == 3,])
						write(paste("\t\"", db.sc.name, "_b_", taxon, "_loss_", db.deciles[d], "\": ", sc.taxon.loss, ",", sep=""), 
							file=outfilename, append=TRUE)			
						sc.taxon.gain = nrow(sub.data[sub.data$taxon.name == taxon & sub.data[,sc.col.name] == 4,])
						write(paste("\t\"", db.sc.name, "_b_", taxon, "_gain_", db.deciles[d], "\": ", sc.taxon.gain, ",", sep=""), 
							file=outfilename, append=TRUE)	
					} # end for taxon
				} # for each deciles
			} # for each year
		} # for each emission scenario

		write(paste("\t\"rg_id\": \"", regions[r], "_", sub.region.name, "\",", sep=""), file=outfilename, 
			append=TRUE)
		write(paste("\t\"rg_name\": \"", sub.region.name, "\",", sep=""), file=outfilename, append=TRUE)
		write(paste("\t\"rg_type\": \"", regions[r], "\"", sep=""), file=outfilename, append=TRUE)
#		write(paste("\t\"rpt_year": 2065
		write("}", file=outfilename, append=TRUE)		
	} # end for subregion
} # end for region

# create a single csv with all species and fields needed for sql query (see schema_and_data.sql)
# e.g. class = 'amphibians'; scientific_name = 'Adelotus brevis'; region_types = 'State';
#	shapefile_id = 4
for (taxon in taxa) { cat(taxon, "\n")

	taxon.dir = paste(wd, "/", taxon, sep="")
	
	# get a list of species directories
	species.names = list.files(paste(taxon.dir, "/models", sep="")) #get a list of all the species
	
	all.out = NULL
	
	for (sp in species.names) { # cycle through each of the species

		# define the species specific working directories
		sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
		deciles.dir = paste(sp.wd, "/dispersal/deciles", sep="")
		
		# get the species summary file
		sp.sum = read.csv(paste(deciles.dir, "/summary.gain.loss.csv", sep=""))
		# colnames = region region_code current + 2 RCPs x 8 years x 3 deciles (RCP45_2015_fiftieth)
		
		# create vectors of info to use as columns in output
		class.fill = rep(taxon, nrow(sp.sum)) # taxon name
		sp.name = gsub("_", " ", sp); species.fill = rep(sp.name, nrow(sp.sum)) # sp name no underscore
		sp.out = cbind(class.fill, species.fill, sp.sum)
		
		new.colnames = colnames(sp.sum)[3:51] # copy columns names and modify to match schema
		tenths = grep("tenth", new.colnames); new.colnames[tenths] = gsub("tenth", "10th", new.colnames[tenths])
		fiftieths = grep("fiftieth", new.colnames); new.colnames[fiftieths] = gsub("fiftieth", "50th", new.colnames[fiftieths])
		ninetieths = grep("ninetieth", new.colnames); new.colnames[ninetieths] = gsub("ninetieth", "90th", new.colnames[ninetieths])
		colnames(sp.out) = c("class", "scientific_name", "region_type", "shapefile_id", new.colnames)	
		# colnames = class scientific_name region_type shapefile_id + 2 RCPs x 8 years x 3 deciles (RCP45_2015_50th)
		
		sp.out[,5:53][sp.out[,5:53] == 0] = "absent"
		sp.out[,5:53][sp.out[,5:53] == 1] = "present"
		sp.out[,5:53][sp.out[,5:53] == 3] = "lost"
		sp.out[,5:53][sp.out[,5:53] == 4] = "gained"
		
		# add species data to singlt ouput
		all.out = rbind(all.out,sp.out)
	} # end for sp
	
	write.csv(all.out, paste(summary.dir, "/", taxon, ".csv", sep=""), row.names=FALSE)
} # end for taxon

#write.csv(all.out, paste(summary.dir, "/summary.csv", sep=""), row.names=FALSE)
#EMG in case Dan wants single file

