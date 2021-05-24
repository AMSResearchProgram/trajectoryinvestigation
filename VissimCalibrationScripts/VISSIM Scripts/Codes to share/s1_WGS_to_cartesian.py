# This code converts the WGS84 coordinates (longitudes and latitudes) collected from the field to Vissim Cartesian coordinates. This conversion code uses a number of reference points. The WGS84 and Vissim coordinates for these reference points are derived and entered in the code manually.

from os import listdir
import wgs84_to_utm
from math import sqrt
import numpy as np
import pandas as pd
import csv

# Enter the field trajectory data folder address here:
data_address = r'C:\\Users\\...\\Trajectory Data\\'
# lat and lon fields in the field trajectory data
field_lat = 'Global_Y_Latitude'
field_lon = 'Global_X_Longitude'

class Reference_Point:
    p1 = []
    xy1 = []
    p2 = []
    xy2 = []
    p3 = []
    xy3 = []
class Converted_Point:
    x = []
    y = []
reference_point = Reference_Point()
converted_points = Converted_Point()

# Field reference points
reference_point.p1 = 28.149768, -82.386855
reference_point.p2 = 28.157671, -82.392362
# Vissim reference points
reference_point.xy1 = -434898.8, -1079250.8
reference_point.xy2 = -435438.7, -1078370.1

def find_csv_filenames( path_to_dir, suffix=".csv" ):
    filenames = listdir(path_to_dir)
    return [ filename for filename in filenames if filename.endswith( suffix ) ]
    
filenames = find_csv_filenames(data_address)
for name in filenames:
    if int(name[1]) == 1:
        ref = reference_point.p1
        xy = reference_point.xy1
    elif int(name[1]) == 2:
        ref = reference_point.p2
        xy = reference_point.xy2
    elif int(name[1]) == 3:
        ref = reference_point.p3
        xy = reference_point.xy3
        
    file = data_address + name
    with open(file) as csv_file:
        values_traj = pd.read_csv(csv_file)
    
    utm_ref = wgs84_to_utm.main([ref[0]],[ref[1]])
    offset_x = utm_ref.x-xy[0]
    offset_y = utm_ref.y-xy[1]
    utm_points = wgs84_to_utm.main(values_traj[field_lat],values_traj[field_lon])
    
    values_traj['X'] = utm_points.x-offset_x
    values_traj['Y'] = utm_points.y-offset_y
    
    output_file = data_address + '\\XY\\' + name[0:-4] + '_XY.csv'
    values_traj.to_csv(output_file,index=False)
    