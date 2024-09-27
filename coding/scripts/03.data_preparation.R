rm(list = ls())

# for cleaner install and import of libraries
# install.packages('pacman')
# library(pacman)


pacman::p_load(sf, # for (almost) anything spatial 
               tidyverse, tidylog, # for data wrangling
               conflicted, # for conflicts 
               heaven, # for importing data 
               readr, readxl, # for importing data (readr actually already included in tidyverse)
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

#### schools #### 
# import xlsx
edu <- read_excel(paste0(raw_data, 'data_preparation/opendatabcn_llista-equipaments_educacio-csv.xlsx'))

# check column names 
names(edu)
# View(edu)
# column names are stored in row 1 
# assign row 1 to column names 
colnames(edu) <- edu[1,]
# drop the first row
edu <- edu[2:nrow(edu),]
# check what's in the data
freq(edu$secondary_filters_name)
names(edu)

# keep only variable of interest
edu <- edu %>% 
  select(register_id, name, institution_id, institution_name, secondary_filters_name,
         geo_epgs_4326_x, geo_epgs_4326_y)


# all schools 
# keep only categories of interest 
schools <- edu %>% 
  filter(secondary_filters_name == 'Adults' |
           secondary_filters_name == 'Educació primària'| 
           secondary_filters_name == 'Educació secundària' | 
           secondary_filters_name == 'Ensenyament infantil (0-3 anys)' |
           secondary_filters_name == 'Ensenyament infantil (3-6 anys)' | 
           secondary_filters_name == 'Escoles Bressol municipals' | 
           secondary_filters_name == 'Formació professional' |
           secondary_filters_name == 'Idiomes' |
           secondary_filters_name == 'Informàtica' | 
           secondary_filters_name == 'Música' | 
           secondary_filters_name == 'Universitats') %>% 
  filter(!is.na(geo_epgs_4326_x) & !is.na(geo_epgs_4326_y)) # there's one row with broken/missing geometry. drop it. 

class(schools)

# transform from df to sf
schools <- st_as_sf(schools, coords = c('geo_epgs_4326_y', 'geo_epgs_4326_x'), crs = 4326)
class(schools)
st_crs(schools)
# there's a mistake in the data here. x and y are swapped.
# it should be Long (x), Lat (y) 

# map 
ggplot()+
  geom_sf(data = schools)
# something is wrong 
# a point very far away 

# restrict schools to those within barcelona's boundaries 
bcn <- read_sf(paste0(raw_data, 'Barcelona.gpkg'))
st_crs(bcn)

# check CRS
st_crs(schools) == st_crs(bcn)
# FALSE

# transform one of the two to the crs of the other
schools <- st_transform(schools, crs = st_crs(bcn))

# filter 
schools <- st_intersection(schools, bcn)

# map 
ggplot()+
  geom_sf(data = bcn)+
  geom_sf(data = schools)


# save 
write_sf(schools, paste0(raw_data, 'all_schools.gpkg'))


