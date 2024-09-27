rm(list = ls())

# for cleaner install and import of libraries
install.packages('pacman')
library(pacman)

pacman::p_load(sf, # for (almost) anything spatial 
               tidyverse, tidylog, # for data wrangling
               tmap, ggplot2,  # for mapping 
               viridis, RColorBrewer, # for palettes 
               conflicted, # for conflicts 
               readr, readxl, # for importing data (readr actually already included in tidyverse)
               summarytools,  # for descriptives  
               units) # for units of measurement


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

schools <- read_sf(paste0(raw_data, 'all_schools.gpkg'))
parks <- read_sf(paste0(raw_data, 'parks_osm.gpkg'))
bcn <- read_sf(paste0(raw_data, 'Barcelona.gpkg'))
neighborhoods <- read_sf(paste0(raw_data, 'BCN_UNITATS_ADM/0301040100_Barris_UNITATS_ADM.shp'))
pop_age_barrio <- read.csv2(paste0(raw_data, 'pop_age_barrio.csv'))

#### Q1: how many schools per neighborhood (by type)? #### 

# Step 1: assign schools to neighborhoods 

# first clean a bit the neighborhoods df 
# keep only variables of interest 
names(neighborhoods)

neighborhoods <- neighborhoods %>% 
  select(DISTRICTE, BARRI, NOM)
# Note: geometry column automatically kept 

# rename type variable in schools df
schools <- schools %>% 
  rename(type = secondary_filters_name) 

# check uniqueness of schools id 
n_distinct(schools$register_id)
# freq(schools$register_id)

# register_id is not unique. same school might have e.g. primary and secondary 
# --> treat these cases as two different schools 
# create ID for each school-type 
schools <- schools %>% 
  mutate(school_id = row_number())


##### st_intersects #####
?st_intersects
# it's a geometric confirmation (geometric binary predicates - TRUE/FALSE)
# it does not modify geometries of x,y
# it only identifies if x and y share any space 
# since we're working with points here, there's no need to modify geometries, 
# we're just assigning schools to neighborhoods 

# spoiler: st_intersection would be different (we will see later)

# point and multipolygon
head(schools)
head(neighborhoods)

# sf class
class(schools)
class(neighborhoods)

# same CRS 
st_crs(schools)
st_crs(schools) == st_crs(neighborhoods)

# intersect 
schools_neigh <- st_join(neighborhoods, schools, join = st_intersects)
head(schools_neigh)

# resulting variables
names(schools_neigh)

# Step 2: count schools within each neighborhood 

schools_neigh <- schools_neigh %>% 
  group_by(BARRI) %>% # count total schools by neighborhood 
  mutate(tot_schools = n_distinct(school_id)) %>% 
  group_by(BARRI, type) %>% # count schools by type and neighborhood
  mutate(n_schools_type = n_distinct(school_id)) %>% 
  slice_head(n=1) %>% # or filter(row_number()==1)
  select(BARRI, NOM, tot_schools, type, n_schools_type) %>%  # keep variables of interest
  ungroup()

View(schools_neigh)

# Step 3: let's map the results 
head(schools_neigh)

# total number of schools
ggplot()+
  geom_sf(data = schools_neigh, aes(fill = tot_schools))+
  scale_fill_viridis(discrete = FALSE, option = "C")+
  theme_void()+
  labs(fill = 'Tot. schools')

# infantil (0-3)
freq(schools_neigh$type)

ggplot()+
  geom_sf(data = neighborhoods)+
  geom_sf(data = schools_neigh[schools_neigh$type == 'Ensenyament infantil (0-3 anys)',], aes(fill = n_schools_type))+
  scale_fill_viridis(discrete = FALSE, option = "C")+
  theme_void()+
  labs(fill = 'Nursery (0-3)')

# infantil (3-6)
ggplot()+
  geom_sf(data = neighborhoods)+
  geom_sf(data = schools_neigh[schools_neigh$type == 'Ensenyament infantil (3-6 anys)',], aes(fill = n_schools_type))+
  scale_fill_viridis(discrete = FALSE, option = "C")+
  theme_void()+
  labs(fill = 'Nursery (3-6)')

# primary 
ggplot()+
  geom_sf(data = neighborhoods)+
  geom_sf(data = schools_neigh[schools_neigh$type == 'Educació primària',], aes(fill = n_schools_type))+
  scale_fill_viridis(discrete = FALSE, option = "C")+
  theme_void()+
  labs(fill = 'Primary')

# secondary
ggplot()+
  geom_sf(data = neighborhoods)+
  geom_sf(data = schools_neigh[schools_neigh$type == 'Educació secundària',], aes(fill = n_schools_type))+
  scale_fill_viridis(discrete = FALSE, option = "C")+
  theme_void()+
  labs(fill = 'Secondary')

# university 
ggplot()+
  geom_sf(data = neighborhoods)+
  geom_sf(data = schools_neigh[schools_neigh$type == 'Universitats',], aes(fill = n_schools_type))+
  scale_fill_viridis(discrete = FALSE, option = "C")+
  theme_void()+
  labs(fill = 'University')


##### balance dataset #####
# we've seen that dataset is unbalanced 
# if we need a balanced df with 0 values (if there is no school in the neighborhood)

# create structure of balanced dataset 
df_b <- data.frame(type = rep(unique(schools$type), length(unique(neighborhoods$BARRI))),
                   BARRI = rep(unique(neighborhoods$BARRI), each = length(unique(schools$type))))

# join datasets 
schools_neigh <- left_join(df_b, schools_neigh, by = c('BARRI', 'type'))
# Note1: obs only in x are neighborhood-type pairs for which there is no school 
# --> replace these values to 0 
# Note2: geometry of observations only in x is empty and class is now data.frame()
# --> won't be able to map with this df unless we correct for the empty geometries 

# replace NA values with 0 
schools_neigh <- schools_neigh %>% 
  mutate(tot_schools = ifelse(is.na(tot_schools), 0, tot_schools), 
         n_schools_type = ifelse(is.na(n_schools_type), 0, n_schools_type))

# correct geometries 
class(schools_neigh)
names(schools_neigh)

# schools_neigh <- st_drop_geometry(schools_neigh)
# will only work with objects class sf 

schools_neigh <- schools_neigh %>% 
  select(-c(geometry, NOM))

# join with neighborhoods df with full geometry
schools_neigh <- left_join(schools_neigh, neighborhoods, by = 'BARRI')

class(schools_neigh)

##### activate geometry column #####
st_geometry(schools_neigh) <- schools_neigh$geometry

class(schools_neigh)

# you might want to save this 
write.csv2(schools_neigh, paste0(final_data, 'schools_neigh_type.csv'))
write_sf(schools_neigh, paste0(final_data, 'schools_neigh_type.gpkg'))

# try mapping now 
# university 
ggplot()+
  geom_sf(data = schools_neigh[schools_neigh$type == 'Educació primària',], aes(fill = n_schools_type))+
  scale_fill_viridis(discrete = FALSE, option = "C")+
  theme_void()+
  labs(fill = 'Primary')
# balanced and 0 included 
ggsave(paste0(maps, 'schools_neigh_prim_r.png'))

# try the same in QGIS. 

#### Q1.1: how many schools per kid by neighborhood? ####
# Note: still, we miss information about number of places available in each school

# merge in information about population by age and neighborhood (2022)

# schools_neigh <- left_join(schools_neigh, pop_age_barrio, by = c('BARRI' = 'BARRIO'))
# this will throw an error
# make sure key is of the same class
schools_neigh$BARRI <- as.numeric(schools_neigh$BARRI)

schools_neigh <- left_join(schools_neigh, pop_age_barrio, by = c('BARRI' = 'BARRIO'))

names(schools_neigh)

# create per capita variables
freq(schools$type)

schools_neigh <- schools_neigh %>%
  mutate(schools_pc = case_when(type == 'Ensenyament infantil (0-3 anys)' ~ n_schools_type/age0_3,
                                type == 'Ensenyament infantil (3-6 anys)' ~ n_schools_type/age3_6,
                                type == 'Educació primària' ~ n_schools_type/age6_12,
                                type == 'Educació secundària' ~ n_schools_type/age12_18,
                                .default = NULL))

# map this

# infantil (0-3)
ggplot()+
  geom_sf(data = schools_neigh[schools_neigh$type == 'Ensenyament infantil (0-3 anys)',], aes(fill = schools_pc))+
  scale_fill_viridis(discrete = FALSE, option = "C")+
  theme_void()+
  labs(fill = 'Nursery (0-3)')

# infantil (3-6)
ggplot()+
  geom_sf(data = neighborhoods)+
  geom_sf(data = schools_neigh[schools_neigh$type == 'Ensenyament infantil (3-6 anys)',], aes(fill = schools_pc))+
  scale_fill_viridis(discrete = FALSE, option = "C")+
  theme_void()+
  labs(fill = 'Nursery (3-6)')

# primary
ggplot()+
  geom_sf(data = neighborhoods)+
  geom_sf(data = schools_neigh[schools_neigh$type == 'Educació primària',], aes(fill = schools_pc))+
  scale_fill_viridis(discrete = FALSE, option = "C")+
  theme_void()+
  labs(fill = 'Primary')

# secondary
ggplot()+
  geom_sf(data = neighborhoods)+
  geom_sf(data = schools_neigh[schools_neigh$type == 'Educació secundària',], aes(fill = schools_pc))+
  scale_fill_viridis(discrete = FALSE, option = "C")+
  theme_void()+
  labs(fill = 'Secondary')

#### Q2: how many m2 of parks per neighborhood? #### 
##### st_intersection #####
# st_intersection intersects geometries of x and y 
# cuts geometries according to overlap 
# --> if there were parks outside of Barcelona, they would be dropped 
# --> if overlapping linestrings or polygons to other polygons, st_intersection 
# returns objects with new geometries resulting from the intersection

parks_neigh <- st_intersection(parks, neighborhoods)
names(parks_neigh)

# visual check 
tmap_mode('view')
tmap_options(max.categories = 72)

tm_shape(neighborhoods)+
  tm_polygons()+
tm_shape(parks_neigh)+
  tm_polygons(col = 'BARRI', 
              popup.vars = c('osm_id', 'name', 'BARRI'))

# compute area of each polygon of park 
# (after geometries have been broken by neighborhood)
# st_area returns are in m^2 as default 
# unit of measure can be changed with set_units()
# in this case, since we want to map these values later, 
# we're going to transform to km^2 (less decimals) and 
# we're going to drop the unit of measure (still km^2, but variable is 
# simple numerical variable)

parks_neigh <- parks_neigh %>% 
  mutate(area = set_units(set_units(st_area(geom), 'km^2'), NULL))

# compute total area of park by neighborhood 
parks_neigh <- parks_neigh %>% 
  group_by(BARRI) %>% 
  mutate(park_area_neigh = sum(area)) %>% 
  slice_head(n=1) %>% 
  select(BARRI, park_area_neigh) %>% 
  ungroup()

# let's map this 
class(parks_neigh)
head(parks_neigh)
ggplot()+
  geom_sf(data = parks_neigh)

# what we want is a map by neighborhoods  
# assign geometry of neighborhoods 

##### drop current geometry #####
parks_neigh <- st_drop_geometry(parks_neigh)

# merge in geometry of neighborhoods 
parks_neigh <- left_join(parks_neigh, neighborhoods)
class(parks_neigh)

# activate geometry column 
st_geometry(parks_neigh) <- parks_neigh$geometry
class(parks_neigh)

##### scale_fill_gradient ##### 
# R colors 
# https://www.nceas.ucsb.edu/sites/default/files/2020-04/colorPaletteCheatsheet.pdf
# https://r-charts.com/colors/

# Grandient colours scales 
# https://ggplot2.tidyverse.org/reference/scale_gradient.html 

ggplot()+
  geom_sf(data = neighborhoods)+
  geom_sf(data = parks_neigh, aes(fill = park_area_neigh))+
  geom_sf(data = parks, fill = 'purple')+
  scale_fill_gradient(low = '#CAFF70', high = '#008B00', n.breaks = 8)+
  theme_void()+
  labs(fill = 'parks (km2)')

ggsave(paste0(maps, 'parks_neigh.png'))

#### Q3: how many schools have a park within 150m? (by neighborhood) #### 
# let's focus on primary schools 

##### approach 1: st_buffer, st_intersection ##### 

# take buffer of 150m radius around each school 
freq(schools$type)
schools_buffer <- st_buffer(schools[schools$type == 'Educació primària',], 150)
head(schools_buffer)

# intersect 
start <- Sys.time()
schools_buffer_parks1 <- st_intersection(schools_buffer, parks)
end <- Sys.time()
# these schools are the ones for which the 150m buffer intersects at least 1 park 
# when x intersects more than one y, x is repeated. 
time_diff1 <- end - start 
print(paste0('approach 1 took ', time_diff1))

##### approach 2: st_buffer, st_join(join = st_intersects) #####
start <- Sys.time()
schools_buffer_parks2 <- st_join(schools_buffer, parks, join = st_intersects)
# this is like a left_join. all x are included, but those that do not intersect 
# with any y, are assigned NA y values (in this case, look at osm_id). 
# when x intersects more than one y, x is repeated. 
schools_buffer_parks2 <- schools_buffer_parks2 %>% 
  filter(!is.na(osm_id))
end <- Sys.time()
time_diff2 <- end - start 
print(paste0('approach 2 took ', time_diff2))

##### approach 3: st_buffer, st_intersects ##### 
start <- Sys.time()
# create binary variable for intersection with parks within 150m 
schools_buffer$park150 <- st_intersects(schools_buffer, parks)
# park150 will contain the indices of the parks which fall within the buffer 
# if we only want to know whether the buffer intersects at least one park: 
schools_buffer_parks3 <- schools_buffer[lengths(schools_buffer$park150) > 0,]
end <- Sys.time()
time_diff3 <- end - start 
print(paste0('approach 3 took ', time_diff3))

##### approach 4: st_distance #####
start <- Sys.time()
schools_parks4 <- st_distance(schools[schools$type == 'Educació primària',], parks, by_element = F, which = 'Euclidean') %>% 
  as.data.frame()
# this returns a dataframe with all the distances of each x to each y. 
# row and column names are the indices of the original x and y dataframes 
# Note: by_element = FALSE returns a matrix with distance between 
# the first element of x and each element of y, 
# the second element of x and each element of y, 
# etc.  

# drop units for the whole dataframe 
schools_parks4 <- drop_units(schools_parks4)

# count how many parks are within 150m 
schools_parks4 <- schools_parks4 %>% 
  mutate(park150_2 = rowSums(schools_parks4 < 150)) %>% 
  select(park150_2)

freq(schools_parks4$park150_2)

# bind information to schools_buffer dataframe 
schools_parks4 <- cbind(schools_buffer, schools_parks4)

# keep only schools which have at least one park within 150m 
schools_parks4 <- schools_parks4 %>% 
  filter(park150_2 != 0)

end <- Sys.time()
time_diff4 <- end - start 
print(paste0('approach 4 took ', time_diff4))

##### approach 5: st_nearest_feature, st_distance #####
start <- Sys.time()
schools_parks5 <- st_join(schools[schools$type == 'Educació primària',], parks, join = st_nearest_feature)
# this is like a left join. each x is matched to the closest y. 

# assign geometry of park to each of the closest parks identified 
# (now geometry of schools_park5 is the point of the schools.
# we need the geometry of the parks.)

# drop geometry of schools 
schools_parks5 <- schools_parks5 %>% 
  as.data.frame() %>% 
  select(osm_id)
# match to original park dataframe 
schools_parks5 <- left_join(schools_parks5, parks, by = 'osm_id')
# activate geometry 
st_geometry(schools_parks5) <- schools_parks5$geom
head(schools_parks5)

# calculate distance between each x and each y (closest feature)
schools_parks5 <- st_distance(schools[schools$type == 'Educació primària',], schools_parks5, which = 'Euclidean', by_element = T) %>% 
  as.data.frame() %>% 
  rename('dist_closest_park' = '.') 
# Note: by_element = TRUE 
# returns a vector with the distance between 
# the first element of x and the first element of y,
# the second element of x and the second element of y, 
# etc.

# drop units 
schools_parks5$dist_closest_park <- set_units(schools_parks5$dist_closest_park, NULL)

# generate dummy for distance < 150m 
schools_parks5 <- schools_parks5 %>% 
  mutate(park150_3 = ifelse(dist_closest_park < 150, 1, 0))
freq(schools_parks5$park150_3) 

# bind information to schools_buffer dataframe 
schools_parks5 <- cbind(schools_buffer, schools_parks5)

# keep only schools which have at least one park within 150m 
schools_parks5 <- schools_parks5 %>% 
  filter(park150_3 != 0)

end <- Sys.time()
time_diff5 <- end - start 
print(paste0('approach 5 took ', time_diff5))

# -----------------------------------------------
# Note: notice great time differenece between approach 1,4,5 and 2,3. 
# This becomes very relevant when data is big. 
print(paste0('approach 1 took ', time_diff1))
print(paste0('approach 2 took ', time_diff2))
print(paste0('approach 3 took ', time_diff3))
print(paste0('approach 4 took ', time_diff4))
print(paste0('approach 5 took ', time_diff5))

# still, they reach the same goal 
n_distinct(schools_buffer$school_id)

n_distinct(schools_buffer_parks1$school_id)
n_distinct(schools_buffer_parks2$school_id)
n_distinct(schools_buffer_parks3$school_id)
n_distinct(schools_parks4$school_id)
n_distinct(schools_parks5$school_id)
# -----------------------------------------------
# recall Q3: how many schools have a park within 150m? (by neighborhood)

# need the points geometry, because we want to match it to the neighborhoods 
# from the schools df, keep only the schools which appear in this intersection 
list_schools_park150 <- as.list(unique(schools_buffer_parks3$school_id))
class(list_schools_park150)

schools_park <- schools %>% 
  filter(school_id %in% list_schools_park150)

# intersect to neighborhoods 
schools_park <- st_join(schools_park, neighborhoods, join = st_intersects)
names(schools_park)

# count the number of schools with a park within 150m by neighborhood 
schools_park_neigh <- schools_park %>% 
  group_by(BARRI) %>% 
  mutate(n_schools_park150 = n_distinct(school_id)) %>% 
  slice_head(n=1) %>% 
  select(BARRI, n_schools_park150)

class(schools_park_neigh)

# transform from sf to datframe 
schools_park_neigh <- schools_park_neigh %>% 
  as.data.frame() %>% 
  select(-geom)

# you might want to save this 
write.csv2(schools_park_neigh, paste0(final_data, 'schools_park_neigh.csv'))

# let's take the share over the total number of primary schools in the neighborhood
# go back to schools_neigh (which has geometry of neighborhoods and count of total 
# schools and by type)
# keep number of primary schools for each neighborhood 

prim_schools_neigh <- schools_neigh %>% 
  filter(type == 'Educació primària') %>% 
  select(BARRI, n_schools_type)

# merge 
# number of primary schools by neighborhood to 
# number of prim. schools with a park within 150m 
# Note: recall that schools_neigh was balanced. 
# --> use it as x, so that you can identify obs only in x 
# as neighborhoods where no school has a park within 150m 
# --> replace those cases (n_schools_park150 == NA) with 0 
prim_schools_neigh$BARRI <- as.numeric(prim_schools_neigh$BARRI)
schools_park_neigh$BARRI <- as.numeric(schools_park_neigh$BARRI)

schools_park_neigh <- left_join(prim_schools_neigh, schools_park_neigh)

schools_park_neigh[is.na(schools_park_neigh$n_schools_park150),]$n_schools_park150 <- 0

# compute share of primary schools with a park within 150m 
schools_park_neigh <- schools_park_neigh %>% 
  mutate(share_schools_park = n_schools_park150/n_schools_type*100)
# Note: neighborhoods with the numerator (n_schools_type) == 0 
# have share_schools_park == NaN (not a number) 

# map 
ggplot()+
  geom_sf(data = neighborhoods)+
  geom_sf(data = schools_park_neigh, aes(fill = share_schools_park), col = 'black')+
  geom_sf(data = parks, fill = '#00CD66', col = '#00CD66')+
  geom_sf(data = schools[schools$type == 'Educació primària',], col = 'black')+
  scale_fill_gradient(low = '#FFD700', high = '#CD0000', n.breaks = 10, na.value = '#FFFAFA')+
  theme(line = element_blank(), #no lines in the background
        axis.text=element_blank(), #no coordinates on the axis
        axis.title=element_blank(), #no axis titles
        panel.background = element_blank(), #white background
        plot.title = element_text(hjust = 0.5),
        legend.box.background = element_blank())+ #centering title
  labs(fill = '(%)')+
  ggtitle('Primary schools with a park within 150m')

ggsave(paste0(maps, 'prim_school_park150.png'))

