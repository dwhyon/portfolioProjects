Land Cover Change in Cedar Rapids due to 2020 Derecho

Full Report with tables and images available above as .docx


Abstract

This report aims to determine the effect of the August 2020 Midwest derecho on land cover in and around Cedar Rapids, Iowa. Using Google Earth Engine, Sentinel-2 L2A images from 2019 and 2021 were processed to RGB color images. Polygons were drawn by hand to create samples of four representative land cover classes (vegetation, built up, open fields, and water), and a CART machine learning model was deployed to create supervised land cover classification images. Change in pixels between years and land cover area was extracted. RGB and classification images, as well as change metrics were exported to .tif and .csv files, respectively. R was used to clean and further process the change metrics table, where it was input into excel and visualized in a dashboard using pivot graphs/tables. The area of fields and built-up land classes were seen to decrease between the period from 2019-2021, whereas the area of vegetation increased, and water stayed relatively the same. This suggests that longer term effects of the derecho are reducing development (urban/ open fields). 

Introduction

A derecho is a widespread, long-lived, straight-line wind storm that is associated with a fast-moving group of severe thunderstorms known as a mesoscale convective system1. Derechos can cause hurricane or tornado -force winds as well as flooding. On August 10-11, a powerful derecho impacted several midwestern states and caused severe flooding. Cedar Rapids, Iowa was one of the places most damaged, suffering from prolonged blackouts and flooding.

Methods

Downloading Sentinel Data

To download Sentinel Data of interest, log into code.earthengine.google.com. After automatic authentication, user will be faced with the GEE code editor and a blank script. In the top portion of the browser window lies a search bar (Figure 1). Type  Sentinel-2 MSI: MultiSpectral Instrument, Level-2A into the search bar and click on result from drop down to open more information (Figure 2). After Clicking “Import” on either the drop-down results in the search bar or the additional information page for the dataset, the Sentinel 2 dataset will be imported into the GEE script as an asset and can be manipulated using the code editor. 

Creating RGB Image

To create RGB image from Sentinel Bands, the imported Sentinel 2 image dataset was filtered by date between 5-01 and 6-30 for both 2019 and 2021, creating two datasets. After filtering image collection by date, the two collections were filtered by location using .filterBounds() method around a point vector in Cedar Rapids. The collections were filtered again by their “CLOUDY_PIXEL_PERCENTAGE” property to select only images with cloudy pixel percentages less than or equal to 20% of total area. From here, cloudy pixels in the images were masked using a function based on the “QA60” property of the Sentinel dataset. Pixels from this band with value of 10 or 11 (clouds and cirrus) were left shifted to value of 1. These were then used to create a mask for the image, filtering out cloudy pixels and dividing all values in the image’s bands by 10000. This normalizes band values to a range of (0,1) which increases the accuracy of machine learning models. After this mask function was applied to the image collections, the .median() method was used to select the median values for all pixels and composite the image collection into a single image for the region surrounding Cedar Rapids for both 2019 and 2021. The composite images were clipped to a polygon vector outlining the Cedar Rapids area.
Minimum and maximum functions were written to sample 20000 pixels from the image of choice and find minimum and maximum values for bands B4, B3, and B2 from the composite images. These were used as the minimum and maximum range to rescale reflectance bands and yield a high contrast RGB image. 2019 and 2021 Sentinel images were exported out of Google Earth engine using Export.toDrive method and into Google Drive as .tif image.

Creating Land Cover Images using Supervised Classification Techniques

After creating RGB images for 2019 and 2021, 10-15 region of interest polygons demonstrating 4 distinct land cover classes (vegetation, built-up, water, and open fields) were created overlaying RGB images by hand for both years. Polygons were labeled with a class property and joined into one feature collection. The processed Sentinel-2 images were filtered to only reflectance bands (1-12) and the sampleRegions() method was used to create a training dataset for the classification model. Pixels intersecting the created class polygons were converted to point features with band values as properties. This training dataset was input into the ee.Classifier.smileCart() method in Earth Engine to build a CART model for the dataset. The classification model was applied to the processed Sentinel Image using the .classify() method and the Classification images were created. 2019 and 2021 classification images were exported out of Google Earth engine using Export.toDrive method and into Google Drive as .tif image. 

Extracting Land Cover Metrics

To quantify classification change, pixel values from the 2019 image were multiplied by 100, and values from the 2021 image were added. This creates an image where every pixel has a change code of “X0Y” where “x” is the class code from 2019 and “y” is the code from 2021. The .frequencyHistogram() method was used to reduce this image over its entirety and create a dictionary of change codes and total number of pixels belonging to each change code.
To quantify class area cover, the images from both 2019 and 2021 were filtered by class value, split into separate bands for each land cover class. All values in the bands were converted to Boolean presence/absence values and then multiplied by a created image (ee.Image.pixelArea()) which had the area of each pixel in square meters. This converted band values for each Class band from presence/absence to area. A sum() reducer was applied over the image to create a dictionary with total area of each land class for both 2019 and 2021. This dictionary was joined to the classification change dictionary and joined to a feature of null geometry for export out of GEE as .csv filetype. 

Cleaning Land Cover Metric Table

The land cover metrics table was imported into an R project workspace for cleaning using the tidyverse suite of packages. The .csv was cleaned of extraneous columns (geometry and Earth Engine system: index) and split into two variables, class area, and classification change. 
To format the classification change table, change codes were split into two separate columns, class in 2019 and class in 2021 using str_sub method of stringr R package. Records were grouped by class in 2019 and a total pixel sum for each 2019 class was added as a column to the table. Number of pixels (from 2021) was divided by the pixel sum to get percent change of each 2019 class. Numeric class codes were then converted to land cover type using a left join and a created code: cover key. 
To format land cover area table, area was converted from square meters to square miles. 
Both tables were exported as .csv filetypes using write_csv method. 

Import into Tableau and Creation of Dashboard

The classification change and class area tables were imported into Tableau and a 4-figure dashboard was created. A bar chart of landcover area were created to show change of class areas from 2019 to 2021. A bar chart was created to show percentage change of each classification during this time period. Two treemaps were created. One to highlight each class in 2019, and the proportion that changed to different classes in 2021. The other treemap highlights each class in 2021 and shows what proportion of 2019 land cover classes make up each 2021 class. 

Results and Conclusions

In the Cedar Rapids area before the 2020 derecho, the majority of water follows Cedar River, which runs through the city, as well as many small drainages that branch off from this. The majority of green vegetative cover surrounds these waterways with limited presence outside of this, and limited distribution throughout the city itself. The built-up class is mostly concentrated in the city of Cedar Rapids, with some sparse distribution throughout the entire image representing roads and small structures surrounding the widespread field class. 
Comparing the classification images, it is evident that after the derecho, vegetative cover becomes much more widespread outside of drainage features and throughout the city of Cedar rapids. However, along the banks of Cedar River there is a small boundary of field between the water and vegetative cover, suggesting that flooding due to the derecho cleared much of the vegetation around the banks and ordinary high-water mark. 
From 2019 to 2021 Built Up and Field classes reduced in area, where as Vegetation increased, and water remained relatively the same. This is likely due to the storm’s widespread displacement of destroyed vegetation as well as damage to human structures caused by the storm. Cleanup from the 2020 derecho is still in progress and it is not surprising in the year following the storm that vegetation cover increased from both seed and cutting dispersal but also destruction of landcover typically preventing widespread vegetative cover (asphalt, concrete, etc.)
In examining the classification change metrics, a few other interesting patterns are evident. For one, the vegetative loss is evenly distributed between the other three classes. This suggests that development, clearing of vegetative cover without building, and expansion of drainages were all about the same after the derecho. Although water pixels were the most likely to change (almost exclusively to veg) the large amount of change from vegetative cover to water meant that total water coverage remained very similar before and after the derecho. Give the storm and flooding event it makes sense that drainage boundaries throughout the region would change, but that total water would be dependent on season and remain the same. The majority of built-up cover loss comes from vegetative and field gain, suggesting that damage cause by the storm cleared human development and some of that open space was either covered by vegetative debris or plant communities spread to these disturbed areas. The majority of loss of field cover became vegetative, which again is likely a result of both debris and spread of wild plant communities into disturbed human development. 




Earth Engine Script
https://code.earthengine.google.com/4093d229898979c993fdd7cce3040a49

Sources
1.	 Corfidi, Stephen F.; Johns, Robert H.; Evans, Jeffry S. (3 December 2013). "About Derechos". Storm Prediction Center, NCEP, NWS, NOAA Web Site. Retrieved 8 January2014
