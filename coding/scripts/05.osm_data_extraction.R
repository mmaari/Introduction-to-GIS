# extracting data from OSM 
rm(list = ls())

# for cleaner install and import of libraries
# install.packages('pacman')
# library(pacman)

pacman::p_load(sf, # for (almost) anything spatial 
               tidyverse, tidylog, # for data wrangling
               tmap, ggplot2,  # for mapping 
               viridis, RColorBrewer, # for palettes 
               conflicted, # for conflicts 
               readr, readxl, # for importing data (readr actually already included in tidyverse)
               summarytools,  # for descriptives  
               units,  # for units of measurement
               osmdata) # for data extraction from OSM 

conflicts_prefer(tidylog::mutate)
conflicts_prefer(tidylog::rename)
conflicts_prefer(tidylog::filter)
conflicts_prefer(tidylog::select)
conflicts_prefer(dplyr::union)
conflicts_prefer(summarytools::freq)
conflicts_prefer(tidylog::left_join)
conflicts_prefer(tidylog::group_by)
conflicts_prefer(tidylog::ungroup)
conflicts_prefer(tidylog::relocate)
conflicts_prefer(tidylog::slice_head)
conflicts_prefer(tidylog::count)

# define directories 
raw_data <- "/Users/mariannamagagnoli/Library/CloudStorage/OneDrive-UniversitatdeBarcelona/UB/Introduction to GIS/coding/data/raw_data/"
final_data <- "/Users/mariannamagagnoli/Library/CloudStorage/OneDrive-UniversitatdeBarcelona/UB/Introduction to GIS/coding/data/final_data/"
maps <- "/Users/mariannamagagnoli/Library/CloudStorage/OneDrive-UniversitatdeBarcelona/UB/Introduction to GIS/coding/maps/"

# import official data 
cycleways <- read_sf(paste0(raw_data, '2023_1T_CARRIL_BICI/2023_1T_CARRIL_BICI.shp'))
bcn <- read_sf(paste0(raw_data, 'Barcelona.gpkg'))

# get cycle lanes from OSM
cycleways <- opq(bbox = 'Barcelona') %>%
  add_osm_feature(key = 'highway', value = 'cycleway') %>%
  osmdata_sp ()

cycleways
class(cycleways)

# keep linestrings 
cycleways_osm <- cycleways$osm_lines
class(cycleways_osm)

names(cycleways_osm)

# transform to sf
cycleways_osm <- st_as_sf(cycleways_osm)
st_crs(cycleways_osm)

# limit to barcelona 
cycleways_osm <- st_transform(cycleways_osm, crs = st_crs(bcn))
cycleways_osm <- st_intersection(cycleways_osm, bcn)

# map 
ggplot()+
  geom_sf(data = cycleways_osm)

# save 
write_sf(cycleways_osm, paste0(final_data, 'osm_cycleways.gpkg'))

# compare to official data on current cycle lanes 
# map 
ggplot()+
  geom_sf(data = bcn)+
  geom_sf(data = cycleways, col = 'red', lwd = 1)+
  geom_sf(data = cycleways_osm)+ 
  theme_void()









