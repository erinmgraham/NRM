# this script uses the threshold vetted current ascii to generate dispersal matrix

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

# create the species specific working directory
taxon.dir = paste(wd, "/", taxon, sep="")
sp.wd = paste(taxon.dir, "/models/", sp, "/1km", sep="")
warren.wd = paste(sp.wd, "/warren", sep=""); setwd(warren.wd)
	
# read in the threshold vetted current ascii created by 05.clip.current.R
t.vet.cur.asc = read.asc.gz("threshold.vet.cur.asc.gz")

# create a dataframe of the vetted current distrubtion
# get the array indices of presence/absences
vet.cur.df = as.data.frame(which(is.finite(t.vet.cur.asc), arr.ind = TRUE))
# get the lat and lon of those values
vet.cur.df$y = getXYcoords(t.vet.cur.asc)$y[vet.cur.df$col]
vet.cur.df$x = getXYcoords(t.vet.cur.asc)$x[vet.cur.df$row]
# get the suitability at that lat/ln
vet.cur.df$spp.oc = t.vet.cur.asc[cbind(vet.cur.df$row,vet.cur.df$col)]
Sys.time()
# create an ascii of core and edge cells
# 886 and 691 are number of rows and columns from 5km asc's
#emg 1km has 3455 rows and 4072 columns; these are reversed when rendered in R
for (rr in 1:4071) { cat(rr,'... ') #cycle through all rows and columns and extract core vs edge ... edge is 1 & core is 2
	for(cc in 1:3454) { # one less than total to avoid exceeding cc's (+1 below)
		#  get the value
		tval = t.vet.cur.asc[rr,cc]
		# if it's not NA
		if (is.finite(tval)) {
			# and equal to 1 (present)
			if (tval == 1) {
				# if any of the other values in the nearest rows and cols are 0's (and not NA) it's an edge
				tt = any(t.vet.cur.asc[(rr-1):(rr+1),(cc-1):(cc+1)] ==0); if(is.na(tt)) tt=FALSE
				# else it's a core
				if (!tt) t.vet.cur.asc[rr,cc] = 2
			}
		}
	}
} # end for rr
t.vet.cur.asc.corevedge = t.vet.cur.asc #make a copy of t.vet.cur.asc storing core vs edge
write.asc.gz(t.vet.cur.asc.corevedge, "t.vet.cur.core.edge.asc")
Sys.time()
# define taxa-specific realistic and optimistic dispersal kernels (Warren et al 2013)
# EMG for MigClim, dispersal distance is limited by cell size; cell size = 1km
if (taxon %in% c("mammals", "birds")) {
		buffers =c(1.5,3)  # actually 1.5km/yr and 3km/yr
} else { # reptiles, amphibians
		buffers = c(0.1,0.5) # supposed to be 0.1km/yr and 0.5km/yr
} # end for taxon
Sys.time()
# create a buffer matrix to be analyzed below
# the buffer distance should be related to the cell size of the asc and dispersal distance of the species
# for example, on a 250m grid, a species that can travel 1km/yr needs a buffer of 4 cells(250mx4=1km)
# in my case, on a 1km grid, if a species can travel 3km/yr, the buffer should be 3 cells(1kmx3=3km)/yr
# emg that buffer is one year; need 80 years?
buffer=buffers[2]*80 # EMG set buffer to [2] for now
for (rr in (buffer+1):4072) { cat(rr,'... ') #cycle through all rows and columns and identify buffer cells... mark them with a value 10
	for(cc in (buffer+1):3455) {
		# get the value
		tval = t.vet.cur.asc[rr,cc]
		# if it's not NA
		if (is.finite(tval)) {
			# and equal to 1 (present)
			if (tval == 1) { # if it's a presence, make a buffer around it
				# set the value on the left and top nearest 4 rows and columns to 10; 
				#emg second statement here unnecessary no? already 1?
				t.vet.cur.asc[(rr-buffer):(rr),(cc-buffer):(cc)] = 10; t.vet.cur.asc[rr,cc] = 1
			} else { # it's an absence(0) or a core(2), and there's a presence around it, make it a buffer
				# if there's a 1 in the nearest 3 rows and columns
				tt = any(t.vet.cur.asc[(rr-buffer):(rr-1),(cc-buffer):(cc-1)] == 1); if(is.na(tt)) tt=FALSE
				# make it a buffer
				if (tt) t.vet.cur.asc[rr,cc] = 10
			}
		}
	}
} # end for rr
write.asc.gz(t.vet.cur.asc, "t.vet.cur.buffer.asc")
Sys.time()
# reset our core & edge
tpos=which(t.vet.cur.asc.corevedge %in% c(1,2)); t.vet.cur.asc[tpos] = t.vet.cur.asc.corevedge[tpos] 
write.asc.gz(t.vet.cur.asc, "t.vet.cur.potential.asc")

#append 1km potential to cur.df
vet.cur.df$potential.1km=t.vet.cur.asc[cbind(vet.cur.df$row, vet.cur.df$col)]
# values of 1,2,10

# set the dispersal rate as 10m pa = disp = 10; therefore dispersal rate of 3km/yr disp=3000
disp=buffers[2]*1000 # EMG set buffer to [2] for now	

# cycle through all locations, calculate distances and append rows as appropriate
# create a matrix of the lon/lat of each t.vet.cur.asc cell that has a value of 1 - edge cell
tt = as.matrix(data.frame(lat1=vet.cur.df$y[which(vet.cur.df$potential.1km==1)],lon1=vet.cur.df$x[which(vet.cur.df$potential.1km==1)],lat2=0,lon2=0)) #prepare the matrix for getting distances
YEARS = seq(2005,2085,10)
#emg assumes current dist is 2005
dists = disp*c(0,10,20,30,40,50,60,70,80) #define the distances for the years

for (zz in YEARS) { # append a col to vet.cur.df with year and populate with current distribution 0/1
	vet.cur.df[[paste("y",YEARS[zz],sep="")]] = vet.cur.df$spp.oc
} 
Sys.time()
#for (yy in 2:length(YEARS))	{		# write csv per column year
#vet.cur.df[[paste("y",YEARS[yy],sep="")]] = vet.cur.df$spp.oc 	# write csv per column year

counter = 0 # this is just to print progress
# for each buffer cell(cell with value 10) 
cat("nrows: ", length(which(vet.cur.df$potential.1km==10)), "\n")		
for (ii in c(1:nrow(vet.cur.df))[which(vet.cur.df$potential.1km==10)]) { if (counter%%100==0) cat(counter,"... ") ; counter = counter +1 #cycle through all locations not in current distribution
	tt[,"lat2"] = vet.cur.df$y[ii]; tt[,"lon2"] = vet.cur.df$x[ii] #populate the data table
	# fill lat2 lon2 columns entirely with the buffer (cell value of 10) lon/lats
	min.dist = min(distance(tt)$distance,na.rm=TRUE) #get the minimum distance
	# from an edge cell to the buffer cell
	#check the distances
	for (yy in 2:length(YEARS)) { #start with the first year that permits some movement
		if (min.dist<=dists[yy]) {
			vet.cur.df[ii,paste('y',YEARS[yy],sep='')] = 1
		} # end if		
	} # end for yy
} # end for ii

#csvname = paste(sp, ".", yy, ".realized.dist.disp.matrix.csv", sep="") # write csv per column year
csvname = paste(sp, ".realized.dist.disp.matrix.csv", sep="")
write.csv(vet.cur.df, csvname, row.names=FALSE)
#}	
#Sys.time()

