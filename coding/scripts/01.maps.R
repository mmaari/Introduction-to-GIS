rm(list = ls())

# for cleaner install and import of libraries
# install.packages('pacman')
# library(pacman)

pacman::p_load(sf, # for (almost) anything spatial 
               tmap, ggplot2,  # for mapping 
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
maps <- "/Users/mariannamagagnoli/Library/CloudStorage/OneDrive-UniversitatdeBarcelona/UB/Introduction to GIS/coding/maps/"


schools <- read_sf(paste0(raw_data, 'all_schools.gpkg'))
parks <- read_sf(paste0(raw_data, 'parks_osm.gpkg'))
bcn <- read_sf(paste0(raw_data, 'Barcelona.gpkg'))
neighborhoods <- read_sf(paste0(raw_data, 'BCN_UNITATS_ADM/0301040100_Barris_UNITATS_ADM.shp'))

#### Map 1: Where are the schools and parks in Barcelona ####

st_crs(schools)
st_crs(parks)

st_crs(schools) == st_crs(parks)


#### base ####
plot(schools$geom)
plot(parks$geom, add = T, col = 'green')

#### ggplot2 ####
##### schools #####
ggplot()+
  geom_sf(data = schools, col = 'blue')

##### + parks #####
ggplot()+
  geom_sf(data = parks, fill = 'green')+
  geom_sf(data = schools, col = 'blue')

##### + bcn #####
ggplot()+
  geom_sf(data = bcn)+  
  geom_sf(data = parks, fill = 'green')+
  geom_sf(data = schools, col = 'blue')

##### by type #####
# Note: we're gonna color schools by type 
# --> need to use the aes() argument when color is calling a variable
names(schools)
ggplot()+
  geom_sf(data = bcn)+  
  geom_sf(data = parks, fill = 'green')+
  geom_sf(data = schools, aes(col = secondary_filters_name))

##### with palette #####
# https://www.datanovia.com/en/blog/top-r-color-palettes-to-know-for-great-data-visualization/ 
# viridis palettes 
install.packages("viridis")  # Install
library("viridis")           # Load

names(schools)

ggplot()+
  geom_sf(data = bcn)+  
  geom_sf(data = parks, fill = 'green')+
  geom_sf(data = schools, aes(col = secondary_filters_name))+
  scale_color_viridis(discrete = TRUE, option = "C")

# RColorBrewer palettes 
library(RColorBrewer)
display.brewer.all()
# Note: Qualitative palettes are best suited for categorical variables 

ggplot()+
  geom_sf(data = bcn)+  
  geom_sf(data = parks, fill = 'green')+
  geom_sf(data = schools, aes(col = secondary_filters_name))+
  scale_color_brewer(palette = 'Paired')+
  labs(color = 'School type')

##### nicer background #####
# Let's focus on primary schools 

prim_schools <- schools %>% 
  filter(secondary_filters_name == 'Educació primària')

ggplot()+
  geom_sf(data = bcn)+  
  geom_sf(data = parks, fill = 'green')+
  geom_sf(data = prim_schools, col = 'blue')+
  theme(line = element_blank(), #no lines in the background
      axis.text=element_blank(), #no coordinates on the axis
      axis.title=element_blank(), #no axis titles
      panel.background = element_blank(), #white background
      plot.title = element_text(hjust = 0.5),
      legend.box.background = element_blank()) #centering title

# Alternative: themes
ggplot()+
  geom_sf(data = bcn)+  
  geom_sf(data = parks, fill = 'green')+
  geom_sf(data = prim_schools, col = 'blue')+
  theme_minimal()

ggplot()+
  geom_sf(data = bcn)+  
  geom_sf(data = parks, fill = 'green')+
  geom_sf(data = prim_schools, col = 'blue')+
  theme_classic()

ggplot()+
  geom_sf(data = bcn)+  
  geom_sf(data = parks, fill = 'green')+
  geom_sf(data = prim_schools, col = 'blue')+
  theme_void()

##### with title ##### 
ggplot()+
  geom_sf(data = bcn)+  
  geom_sf(data = parks, fill = 'green')+
  geom_sf(data = prim_schools, col = 'blue')+
  theme(line = element_blank(), #no lines in the background
        axis.text=element_blank(), #no coordinates on the axis
        axis.title=element_blank(), #no axis titles
        panel.background = element_blank(), #white background
        plot.title = element_text(hjust = 0.5),
        legend.box.background = element_blank())+ #centering title
  ggtitle('Primary schools and parks')

# add a legend 
# note: now the filling and colors refer to a variable, not directly a color 
ggplot()+
  geom_sf(data = bcn)+  
  geom_sf(data = parks, aes(fill = 'parks'))+
  geom_sf(data = prim_schools, aes(col = 'schools'))+
  theme(line = element_blank(), #no lines in the background
        axis.text=element_blank(), #no coordinates on the axis
        axis.title=element_blank(), #no axis titles
        panel.background = element_blank(), #white background
        plot.title = element_text(hjust = 0.5),
        legend.box.background = element_blank())+ #centering title
  ggtitle('Primary schools and parks')+
  scale_fill_manual(values = c('parks' = 'green'))+
  scale_color_manual(values = c('schools' = 'blue')) 
# +
#   guides(fill=guide_legend(title=NULL),
#          color=guide_legend(title=NULL)) #hide legend titles 

ggsave(paste0(maps, 'schools_parks_ggplot.png'))

##### zoom #####
eixample <- neighborhoods %>% 
  filter(DISTRICTE == '02')

ggplot()+
  geom_sf(data = eixample)

bbox_eixample <- st_bbox(eixample)
bbox_eixample

ggplot()+
  geom_sf(data = eixample)+  
  geom_sf(data = parks, aes(fill = 'parks'))+
  geom_sf(data = prim_schools, aes(col = 'schools'))+
  theme(line = element_blank(), #no lines in the background
        axis.text=element_blank(), #no coordinates on the axis
        axis.title=element_blank(), #no axis titles
        panel.background = element_blank(), #white background
        plot.title = element_text(hjust = 0.5),
        legend.box.background = element_blank())+ #centering title
  ggtitle('Primary schools and parks')+
  scale_fill_manual(values = c('parks' = 'green'))+
  scale_color_manual(values = c('schools' = 'blue'))+
  coord_sf(xlim = c(bbox_eixample[1]-200, bbox_eixample[3]+200), 
           ylim = c(bbox_eixample[2]-200, bbox_eixample[4]+200))

# ggspatial::annotation_map_tile()

#### tmap ####
##### plot (static) #####
tmap_mode('plot')

tm_shape(prim_schools)+
  tm_dots(col = 'blue')

tm_shape(prim_schools)+
  tm_dots(col = 'blue')+
  tm_shape(parks)+
  tm_polygons(col = 'green')

head(prim_schools)

tm_shape(bcn)+
  tm_polygons()+
  tm_shape(prim_schools)+
  tm_dots(col = 'blue')+
  tm_shape(parks)+
  tm_polygons(col = 'green')

##### view (interactive) #####
tmap_mode('view')

##### all schools #####
tm_shape(schools)+
  tm_dots(col = 'blue')

##### by type ##### 
tm_shape(parks)+
  tm_polygons(col = 'green')+
tm_shape(schools)+
  tm_dots(col = 'secondary_filters_name', 
          title = "School type")

##### manually defined colors #####
freq(schools$secondary_filters_name)

tm_shape(parks)+
  tm_polygons(col = 'green')+
tm_shape(schools)+
  tm_dots(col = 'secondary_filters_name', 
          title = "School type",
          palette = c(
            "Adults" = "#11467b",
            "Educació primària" = "#ffd14d", 
            "Educació secundària" = "#86909a", 
            "Ensenyament infantil (0-3 anys)" = "#14909a",
            "Ensenyament infantil (3-6 anys)" = "#7fbee9",
            "Escoles Bressol municipals" = "#df5454",
            "Formació professionala" = "#7b1072", 
            "Idiomes"  = 'red', 
            "Informàtica" = 'darkgreen', 
            "Música" = 'orange', 
            "Universitats" = 'black'))

#####  palette #####
# tmaptools::palette_explorer()
# Note: remember to close this window before running more code
# if still not running, quit the session

tm_shape(parks)+
  tm_polygons(col = 'green')+
tm_shape(schools)+
  tm_dots(col = 'secondary_filters_name', 
          palette = 'Set1', 
          title = "School type")


##### with text labels ##### 
tm_shape(parks)+
  tm_polygons(col = 'green', 
              popup.vars = 'name')+
  tm_shape(schools)+
  tm_dots(col = 'secondary_filters_name',
          palette = 'Set1', 
          title = "School type")+
  tm_text('name', 
          auto.placement = T)

##### with pop-up variables ##### 
tm_shape(parks)+
  tm_polygons(col = 'green', 
              popup.vars = 'name')+
tm_shape(schools)+
  tm_dots(col = 'secondary_filters_name',
          palette = 'Set1',
          popup.vars = c('name', 'type' = 'secondary_filters_name'), 
          title = "School type")

##### sizes ##### 
tm_shape(parks)+
  tm_polygons(col = 'green', 
              popup.vars = 'name')+
  tm_shape(schools)+
  tm_dots(col = 'secondary_filters_name',
          palette = 'Set1',
          popup.vars = c('name', 'type' = 'secondary_filters_name'), 
          size = 0.2, 
          title = "School type")

##### saving ##### 
schools_parks <- tm_shape(parks)+
  tm_polygons(col = 'green', 
              popup.vars = 'name')+
  tm_shape(schools)+
  tm_dots(col = 'secondary_filters_name',
          palette = 'Set1',
          popup.vars = c('name', 'type' = 'secondary_filters_name'), 
          size = 0.2, 
          title = "School type")
tmap_save(schools_parks, paste0(maps, 'schools_parks_tmap.html'))


#### Map 2: Neighborhoods, schools and parks of Barcelona ####

# map neighborhoods 
ggplot()+
  geom_sf(data = neighborhoods, aes(fill = BARRI))+
  scale_fill_brewer(palette = 'Set1')

# Note: Warning message:
# In RColorBrewer::brewer.pal(n, pal) :
#   n too large, allowed maximum for palette Set1 is 9
# Returning the palette you asked for with that many colors

##### expand palette #####
colourCount = length(unique(neighborhoods$BARRI))
getPalette = colorRampPalette(brewer.pal(9, "Set1"))

ggplot()+
  geom_sf(data = neighborhoods, aes(fill = BARRI))+
  scale_fill_manual(values = getPalette(colourCount))+
  theme(legend.position="left") +
  guides(fill=guide_legend(ncol=4))+
  theme_void()

# tmap
# map parks by neighborhood 
tmap_mode('view')
tm_shape(neighborhoods)+
  tm_polygons(col = 'black')+
  tm_shape(parks)+
  tm_polygons(col = 'green')


# map schools by neighborhood 
tm_shape(neighborhoods)+
  tm_polygons(col = 'black')+
  tm_shape(parks)+
  tm_polygons(col = 'green')+
  tm_shape(schools)+
  tm_dots(col = 'secondary_filters_name',
          palette = 'Set1',
          popup.vars = c('name', 'type' = 'secondary_filters_name'), 
          title = "School type")

