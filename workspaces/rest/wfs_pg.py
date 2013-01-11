#!/usr/bin/python

import sys
import glob
import re
import os
from geoserver.catalog import Catalog

#appserver = 'http://scale.dev.opengeo.org:8080/geoserver'
#dbserver = '10.32.180.122'
appserver = 'http://localhost:8080/geoserver'
dbserver = 'localhost'

ws_name = 'naturalearth'
ds_name = 'ne_pg'
lg_name = "ne_pg"

cat = Catalog(appserver + '/rest')

# check if workspace exists, bail if it does (safter than deleting it)
if any(ws.name == ws_name for ws in cat.get_workspaces()):
  print 'workspace already exists...'
  ws = cat.get_workspace(ws_name)
else:
  print 'creating workspace...'
  ws = cat.create_workspace(ws_name, 'http://www.naturalearth.org')

if any(ds.workspace.name == ws.name and ds.name == ds_name for ds in cat.get_stores()):
  print 'datastore already exists...'
  ds = cat.get_store(ds_name, ws_name)
else:
  print 'creating datastore'
  ds = cat.create_datastore(ds_name, ws.name)
  ds.connection_parameters.update(
    host=dbserver,
    port='5432',
    database='ne_tmp',
    user='opengeo',
    password='opengeo78902',
    dbtype='postgis')
  cat.save(ds)

ds = cat.get_store(ds_name, ws_name)
layers = []
styles = []

# add layers
os.chdir('data')
for shp in [ 'ne_10m_land', 'ne_10m_ocean', 'ne_10m_admin_0_boundary_lines_land', 'ne_10m_admin_1_states_provinces_lines_shp', 
             'ne_10m_lakes', 'ne_10m_rivers_lake_centerlines', 'ne_10m_coastline', 'ne_10m_roads', 'ne_10m_urban_areas', 'ne_10m_populated_places' ]:
  if not os.path.isfile(shp + '.shp'):
    continue
  print 'adding {0}...'.format(shp)
  components =  dict((ext, shp + '.' + ext) for ext in ['shp', 'prj', 'shx', 'dbf'])
  cat.add_data_to_store(ds, shp, components, ws, True)
  
  # collect bbox info for layergroup
  layer = cat.get_layer(shp)
  bbox = layer.resource.native_bbox
  minx = sys.float_info.max
  maxx = 0
  miny = sys.float_info.max
  maxy = 0
  if not layers:
    proj = layer.resource.projection
  else:
    minx = min(minx, float(bbox[0]))
    maxx = max(maxx, float(bbox[1]))
    miny = min(miny, float(bbox[2]))
    maxy = max(maxy, float(bbox[3]))
    if proj != layer.resource.projection:
      print 'projection mismatch...'
      sys.exit(1)
  layers.append(layer.name)
  
  # if there is a style with the same name, then add and apply it
  if os.path.isfile(shp + '.sld'):
    style = cat.get_style(shp)
    sld = open(shp + '.sld').read()
    if style is None:
      print 'adding style...'
      cat.create_style(shp, sld, False)
    else:
      print 'updating style...'
      cat.create_style(shp, sld, True)
    style = cat.get_style(shp)

    layer.default_style = style
    cat.save(layer)
    styles.append(shp)
  else:
    styles.append(cat.get_layer(shp).default_style.name)

# create a layer group
lg = cat.get_layergroup(lg_name)
if lg is None:
  lg = cat.create_layergroup(lg_name)
    
lg.layers = layers
lg.styles = styles
lg.bounds = ( str(minx), str(maxx), str(miny), str(maxy), proj )
print str(minx) + "," + str(maxx)+","+  str(miny)+","+ str(maxy)
cat.save(lg)
