# apply functions
rm(list = ls())

# for cleaner install and import of libraries
# install.packages('pacman')
# library(pacman)

pacman::p_load(tmap, ggplot2,  # for mapping 
               tidyverse, tidylog, # for data wrangling
               conflicted, # for conflicts 
               readr, readxl, # for importing data 
               summarytools) # for descriptives 


conflicts_prefer(tidylog::mutate)
conflicts_prefer(tidylog::rename)
conflicts_prefer(tidylog::filter)
conflicts_prefer(tidylog::select)
conflicts_prefer(dplyr::union)
conflicts_prefer(summarytools::freq)
conflicts_prefer(tidylog::left_join)
conflicts_prefer(tidylog::group_by)

# define directories 
raw_data <- "/Users/mariannamagagnoli/Library/CloudStorage/OneDrive-UniversitatdeBarcelona/UB/Introduction to GIS/coding/data/raw_data/"
final_data <- "/Users/mariannamagagnoli/Library/CloudStorage/OneDrive-UniversitatdeBarcelona/UB/Introduction to GIS/coding/data/final_data/"
maps <- "/Users/mariannamagagnoli/Library/CloudStorage/OneDrive-UniversitatdeBarcelona/UB/Introduction to GIS/coding/maps/"

# import 
schools_neigh <- read_sf(paste0(final_data, 'schools_neigh_type.gpkg'))
neighborhoods <- read_sf(paste0(raw_data, 'BCN_UNITATS_ADM/0301040100_Barris_UNITATS_ADM.shp'))

freq(schools_neigh$type)

# list unique values of type
list_types <- as.list(unique(schools_neigh$type))

# define function to apply to each element of the list 
MapByType <- function(i){
  print(i)
  ggplot()+
    geom_sf(data = neighborhoods)+
    geom_sf(data = schools_neigh[schools_neigh$type == i,], aes(fill = n_schools_type))+
    scale_fill_viridis(discrete = FALSE, option = "C")+
    theme_void()+
    labs(fill = 'n')+
    ggtitle(i)
  ggsave(paste0(maps, 'maps_by_type/', i, '.png'))
}

# apply the function
lapply(list_types, FUN = MapByType)

# alternatively, for more coincise names of pictures 
MapByType2 <- function(n){
  i <- list_types[n]
  print(n)
  print(i)
  ggplot()+
    geom_sf(data = neighborhoods)+
    geom_sf(data = schools_neigh[schools_neigh$type == i,], aes(fill = n_schools_type))+
    scale_fill_viridis(discrete = FALSE, option = "C")+
    theme_void()+
    labs(fill = 'n')+
    ggtitle(i)
  ggsave(paste0(maps, 'maps_by_type/schools_neigh', n, '.png'))
}

# apply the function
list_types_indices <- seq(1, length(list_types), 1)
lapply(list_types_indices, FUN = MapByType2)
