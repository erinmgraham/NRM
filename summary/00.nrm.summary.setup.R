# script to create base csv with every lon/lat from 1km map and regions associated with each

library(SDMTools)
library(raster) #rasterize, rasterToPoints
library(maptools) #readShapePoly

# define workdir
nrm.dir = "/home/jc140298/NRM"

# read in base coordinates
base.pos = read.csv(paste(nrm.dir, "/1km_lat_lon.csv", sep=""))
# read in blank asc and converst to raster
base.asc = read.asc.gz(paste(nrm.dir, "/blank_map_1km.asc.gz", sep=""))
base.raster = raster(base.asc)

# define regions and shapefiles
regions = c("State", "IBRA", "NRM", "Kimberly", "NT")
region.shps = c("State_poly.shp", "IBRA_poly.shp", "NRM_poly.shp", "RNRM_Subregion_Kimberley.shp",
	"NT_A_PP_GDA94_130208_5.shp")

# convert region shapes to rasters then extract values and append to base output file
for (i in 1:length(regions)) {

	# read in region shapefile
	reg.poly = readShapePoly(paste(nrm.dir, "/", region.shps[i], sep=""), 
		proj4string=CRS("+proj=longlat +datum=WGS84"))
	# convert it to raster
	if (!is.null(reg.poly@data$value)) {
		reg.raster = rasterize(reg.poly, base.raster, field=reg.poly@data$value) # State, IBRA, NRM
	} else {
		reg.raster = rasterize(reg.poly, base.raster) # Kimberley, NT
	}	
	# extract values from raster
	reg.vals = extract.data(cbind(base.pos$x, base.pos$y), reg.raster)
	# append to base.pos
	base.pos[,regions[i]] = reg.vals
}

# save base csv with region locations
write.csv(base.pos, paste(nrm.dir, "/region.pos.csv", sep=""), row.names = FALSE)