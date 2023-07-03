
# Load Packages -----------------------------------------------------------

library(dismo)
library(tidyverse)
library(tmap)
library(sf)
library(rgdal)
library(geosphere)
library(terra)
library(rgeos)

tmap_mode("view")


dir.create("./Data/2_clusterExport")



# Cluster All IDs ---------------------------------------------------------

poolID <- read_csv("./Data/1_idGroup/poolId.csv") %>% 
  distinct(id, lon, lat)

sentID <- read_csv("./Data/1_idGroup/sentinelId.csv") %>% 
  distinct(id, lon, lat)

birdID <- read_csv("./Data/1_idGroup/birdId.csv") %>% 
  distinct(id, lon, lat)

clusterFunc <- function(shp) {
  
  
  
  allIDSpatialPoints <- SpatialPointsDataFrame(shp[,c("lon", "lat")], 
                                               shp[,"id"]
  )
  
  # use the distm function to generate a geodesic distance matrix in meters
  mdistAllID <- distm(allIDSpatialPoints)
  
  # cluster all points using a hierarchical clustering approach
  hcAllID <- hclust(as.dist(mdistAllID), method="complete")
  
  
  # define the distance threshold
  d = 2960
  
  # define clusters based on a tree "height" 
  # cutoff "d" and add them to the SpDataFrame
  allIDSpatialPoints$clust <- cutree(hcAllID, h = d)
  
  addClustRaw <- allIDSpatialPoints %>% 
    st_as_sf() %>%
    st_drop_geometry() 

  return(addClustRaw)
  
}
  
  
createPoly <- function(clustTable, shp) {
  addClustRaw2 <- clustTable %>% 
    right_join(shp, by = "id") %>% 
    #Create centroids for groups
    group_by(clust) %>% 
    mutate(
      x = lon,
      y = lat,
      .keep = "unused"
    ) 
  
  # Transform to NAD83 albers
  addCl <- addClustRaw2 %>%
    st_as_sf(coords = c("x", "y"), crs = "EPSG:4326")  %>%  
    st_transform(crs = "EPSG:3310") %>% 
    # Get number of points in cluster to appropriately handle center
    dplyr::group_by(clust) %>% 
    mutate(
      numPoints = n()
    )
  #return(addCl)
  
  # Cluster with 1 location
  points <- addCl %>% 
    filter(numPoints == 1) %>% 
    dplyr::summarise()
  
  
  # Clusters with 2 locations
  lines <- addCl %>% 
    filter(numPoints == 2) %>% 
    dplyr::summarise() %>% 
    st_cast("LINESTRING")
  
  # CLusters with 3 or more
  polys <- addCl %>% 
    filter(numPoints > 2) %>% 
    dplyr::summarise() %>% 
    # Need to cast to polygon and create convex hull around points
    st_cast("POLYGON") %>% 
    st_convex_hull()
  
  
  # Get lines and polys to make circumscribing circle
  allFeats <- lines %>% 
    bind_rows(polys)
  
  
  # Create circumscibing circle for line and poly clusters
  allFeatsCircle <- lwgeom::st_minimum_bounding_circle(allFeats) %>%
    # Find center of circle
    st_centroid() %>% 
    # Add in point clusters
    bind_rows(points) %>% 
    # Buffer by radius
    st_buffer((2960/2))
  
  return(allFeatsCircle)

}



# Run Clustering function on all three datasets ---------------------------



poolKey <- clusterFunc(poolID)

poolShp <- createPoly(poolKey, poolID)



sentKey <- clusterFunc(sentID)


sentShp <- createPoly(sentKey, sentID)


birdKey <- clusterFunc(birdID)

birdShp <- createPoly(birdKey, birdID)



# Export ------------------------------------------------------------------


dir.create("./Data/2_clusterExport/pool1500")
dir.create("./Data/2_clusterExport/pool2000")
dir.create("./Data/2_clusterExport/pool3000")


dir.create("./Data/2_clusterExport/sentinel1500")
dir.create("./Data/2_clusterExport/sentinel2000")
dir.create("./Data/2_clusterExport/sentinel3000")


dir.create("./Data/2_clusterExport/bird1500")
dir.create("./Data/2_clusterExport/bird2000")
dir.create("./Data/2_clusterExport/bird3000")


write_csv(poolKey, "./Data/2_clusterExport/poolClusterIDKey.csv")
write_sf(poolShp, "./Data/2_clusterExport/pool1500/pool1500.shp")
write_sf(poolShp %>% 
           st_buffer(520), 
         "./Data/2_clusterExport/pool2000/pool2000.shp")
write_sf(poolShp %>% 
           st_buffer(1520), 
         "./Data/2_clusterExport/pool3000/pool3000.shp")


# 
# poolShp %>% 
#   st_buffer(520) %>% 
#   tm_shape() + 
#   tm_borders() +
#   tm_shape(poolShp) +
#   tm_fill(col = "blue", alpha = 0.5)


write_csv(sentKey, "./Data/2_clusterExport/sentinelClusterIDKey.csv")
write_sf(sentShp, "./Data/2_clusterExport/sentinel1500/sentinel1500.shp")
write_sf(sentShp %>% 
           st_buffer(520), 
         "./Data/2_clusterExport/sentinel2000/sentinel2000.shp")
write_sf(sentShp %>% 
           st_buffer(1520), 
         "./Data/2_clusterExport/sentinel3000/sentinel3000.shp")


write_csv(birdKey, "./Data/2_clusterExport/birdClusterIDKey.csv")
write_sf(birdShp, "./Data/2_clusterExport/bird1500/bird1500.shp")
write_sf(birdShp %>% 
           st_buffer(520), 
         "./Data/2_clusterExport/bird2000/bird2000.shp")
write_sf(birdShp %>% 
           st_buffer(1520), 
         "./Data/2_clusterExport/bird3000/bird3000.shp")



# 
# 
# sentShp %>%
#   tm_shape() +
#   tm_polygons()
# 
# 
# 
# polysSent <- sentKey %>% 
#   group_by(clust) %>% 
#   mutate(n = n()) %>% 
#   filter( n > 2)
# 
# 
# 
# senPoints <- sentID %>% 
#   filter(id %in% polysSent$id) %>% 
#   st_as_sf(coords = c("lon", "lat"))
# 
# 
# senPols <- sentShp %>% 
#   filter(clust %in% polysSent$clust)
# 
# 
# tm_shape(senPoints) +
#   tm_dots(col = "id", style = "cat") +
#   tm_shape(senPols) +
#   tm_borders()
# 
# 
# sentShp %>% 
#   glimpse()
# 
# sentID %>% 
#   distinct(id) %>% view()
# 
# #
# # write_csv(addClustRaw, "./Data/3_clusterExport/idClusterKey.csv")
# #
# #
# # write_sf(allFeatsCircle,
# #          "./Data/3_clusterExport/clusterSHP/clusterPolys.shp",
# #          #overwrite = T
# # )
# #
# 
# # Map of Methods, Red shows the convex hull of polygon clusters, and blue is the
# # final shape. Clusters are grouped by color points
# tm_shape(sentKey %>% filter(clust < 31)) +
#   tm_borders(col = "red") +
#   tm_shape(sentShp %>% filter(clust < 31)) +
#   tm_borders(col = "blue") #+
#   tm_shape(allIDSpatialPoints %>% st_as_sf() %>% filter(clust < 31)) +
#   tm_dots(col = "clust", style = "cat", palette = "Set3")
# 
# tm_shape(allFeats ) +
#   tm_borders(col = "red") +
#   tm_shape(allIDSpatialPoints %>% st_as_sf() ) +
#   tm_dots() +
#   tm_shape(allFeatsCircle ) +
#   tm_borders(col = "blue") +
#   tm_shape(centSF) +
#   tm_borders(col = "green")
# 
# tm_shape(allFeats ) +
#   tm_borders(col = "red") +
#   tm_shape(allIDSpatialPoints %>% st_as_sf() ) +
#   tm_dots() +
#   tm_shape(allFeatsCircle ) +
#   tm_borders(col = "blue")
