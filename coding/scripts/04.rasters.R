# raster extraction
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
               raster, terra) # for raster extraction


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

# neighborhoods
neighborhoods <- read_sf(paste0(raw_data, 'BCN_UNITATS_ADM/0301040100_Barris_UNITATS_ADM.shp'))
# NDVI
# ndvi <- raster(paste0(raw_data, '2017_NDVI.tif'))
# elevation raster
ele <- raster::raster(paste0(raw_data, 'Barcelona_elevation_ICGC.tif'))
# street nodes 
nodes <- read_sf(paste0(raw_data, "BCN_GrafVial_SHP/BCN_GrafVial_Nodes_ETRS89_SHP.shp"))
# street edges 
streets <- read_sf(paste0(raw_data, "BCN_GrafVial_SHP/BCN_GrafVial_Trams_ETRS89_SHP.shp"))


#### raster to polygon ####
##### Q1: what’s the average elevation by neighborhood? ####

# terra:extract() to extract cell values of raster to polygons 
# for each polygon, it will identify all raster cells whose center lies inside the 
# polygon
# and assign the vector of values of the cells to the polygon
# x is the raster, y is the shapefile
# ?extract
ele_neigh <- terra::extract(ele, neighborhoods, fun = mean)

class(ele_neigh)
# output is a matrix 

# bind to neighborhoods
# keep only neighborhood ID
neighborhoods <- neighborhoods %>% 
  select(BARRI)

# bind 
ele_neigh_sf <- cbind(neighborhoods, ele_neigh)

# save 
write_sf(ele_neigh_sf, paste0(final_data, 'ele_neigh.gpkg'))

# map 
# import 
ele_neigh_sf <- read_sf(paste0(final_data, 'ele_neigh.gpkg'))

ggplot()+
  geom_sf(data = ele_neigh_sf, aes(fill = ndvi_neigh))+
  scale_fill_gradient(low = 'black', high = 'red', n.breaks = 10)+
  theme_void()+
  labs(fill = 'Elevation (mean)')

ggsave(paste0(maps, 'ele_neigh.png'))


#### raster to points ####
##### Q1: what’s the gradient of streets in Barcelona?  ####
# start by nodes (points at the beginning and end of each street edge)

class(nodes)
# extract elevation at each node
# get dataframe with nodes indeces
ele_nodes_raster <- raster::extract(ele, nodes, df = T)
# bind extracted values to nodes variables by index 
ele_nodes <- cbind(ele_nodes_raster, nodes)
class(ele_nodes)
names(ele_nodes)

# each of these nodes is the start of a street and the end of another. 
# we will assign elevation at start and elevation at end of each street. 
# divided by the length of each street edge, this will give us the gradient. 

# gradient = [ele(Node_F) - ele(Node_I)]/street_length*100

# calculate length of each street edge 
streets$length <- set_units(st_length(streets$geometry), NULL)
# keep only variables of interest
streets <- streets %>% 
  select(C_Tram, C_Nus_I, C_Nus_F, length)

# keep only variables of interest
ele_nodes <- ele_nodes %>% 
  rename('Elevation' = 'Barcelona_elevation_ICGC') %>% 
  select(C_Nus, Elevation)

# each street section has two nodes: Inici and Fin. Merge Nodes info and node elevation
# so get elevation Inici and Elevation Fin
streets <- tidylog::left_join(streets, ele_nodes, by = c('C_Nus_I' = 'C_Nus')) %>% 
  rename('Elevation_I' = 'Elevation')

streets <- tidylog::left_join(streets, ele_nodes, by = c('C_Nus_F' = 'C_Nus')) %>% 
  rename('Elevation_F' = 'Elevation')
names(streets)

# calculate gradient 
streets <- streets %>% 
  mutate(gradient = abs((Elevation_F-Elevation_I)/length*100))

# map street gradients
ggplot()+
  geom_sf(data = streets, aes(col = gradient), lwd = 0.3)+
  scale_color_gradient(low = '#383838', high = '#FF0000', na.value = 'black')+
  theme(line = element_blank(), #no lines in the background
        axis.text=element_blank(), #no coordinates on the axis
        axis.title=element_blank(), #no axis titles
        panel.background = element_rect(fill = 'black'), #white background
        plot.title = element_text(hjust = 0.5),  #centering title
        plot.background = element_rect(fill = 'black'), 
        legend.background = element_rect('black'), 
        legend.text = element_text(colour = '#BABABA', hjust = 0.5), 
        legend.title = element_text(colour = '#BABABA'), 
        legend.key.width = unit(0.2, 'cm'))

ggsave(paste0(maps, 'streets_gradient.png'))

# save as shapefile 
st_write(streets, paste0(final_data, 'streets_gradient.gpkg'), delete_layer = T)

