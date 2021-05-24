#This script splits the field data into calibration and validation datasets

import pandas as pd
from geopy.distance import distance
import random
import math
import csv


#read original field data 
def readData(file_path): #source is either 'field'
    chunks = pd.read_csv(file_path, chunksize=100000)
    df = pd.concat(chunks)  
    df = df[['Vehicle ID', 'Global Time (s)', 'Global X (Longitude)', 'Global Y (Latitude)', 'Width (ft)','Length (ft)', 'Class (1 motor; 2 auto; 3 truck)', 'Speed (ft/s)', 'Acceleration (ft/s2)', 'Lane Num', 'Space Highway (ft)']]
    df.columns = ['vehId', 'timeStamp.s','xCoord', 'yCoord', 'vehWidth.ft', 'vehLength.ft', 'Class..1.motor..2.auto..3.truck.', 'speed.ft/s', 'acceleration.ft/s2', 'laneIndex', 'spaceHeadway.ft'] 
    m = df['spaceHeadway.ft'].astype(str).str.endswith(';;')
    df['spaceHeadway.ft'].loc[m] =  df['spaceHeadway.ft'].loc[m].astype(str).str[:-2]
    df = df.astype(float)
    return df


#read road checkpoints' coordinate
def readRoadCoordFile(file_path):
    df = pd.read_csv(file_path)
    df = df.astype(float)
    return df


#calculate distance of each row of data to a fixed point
def findDistanceXYToFixedPoint(x, y, p): #x and y are coordinates taken from a row in datafram, and p (p[x],p[y]) is a coordinate of a fixed point 
    p1_inv = [p[1],p[0]]
    p2_inv = [y,x]
    dist = distance(p1_inv, p2_inv).m
    return dist


#checking if each row of data is closer than 10 m (thresh) to section's entrance or exit
def isCloseEntranceExit(dist, thresh = 10):
    isClose = 0
    if dist < thresh:
        isClose = 1
    return isClose


#checking if the trajectory is a full trajectory (it has som epoints which are close enough to entrance and exit)
def isCompleteTrj(isClose_entrance_sum, isClose_exit_sum):
    is_complete_trj = 0
    if (isClose_entrance_sum > 0) & (isClose_exit_sum > 0):
        is_complete_trj = 1
    return is_complete_trj


#adding two columns wich shows the distance of each row from the first and second checkpoint on offramp
def addDistancetoRampCols(df, df_road_coord, sectionId_ramp):
    counter = 0
    df_road_coord.sort_values(by='timeSta', ascending=True, inplace=True)
    for ind,row in df_road_coord.iterrows():
        if row['sectionId'] == sectionId_ramp:
            counter += 1
            col_name = 'dist_rampCP_' + str(counter)
            checkpoint = [row['xCoord'], row['yCoord']]
            df[col_name] = df.apply(lambda x:findDistanceXYToFixedPoint(x['xCoord'], x['yCoord'], checkpoint), axis=1)
            if counter == 2:
                break;


#check the proximity of the data row to offramp based on its distance to checkpoints 1 and 2 and its lane index        
def isCloseRamp(x1, x2, laneIndex, num_of_lane, thresh = 10):
    isClose = 0
    if ((x1 < thresh) or (x2 < thresh)) and (laneIndex <= num_of_lane):
        isClose = 1
    return isClose


#determine destination of vehicle based on the "isClose_sum" column
def findFieldDestination(isClose_sum, thresh = 5):
    if isClose_sum >= thresh:
        destination = 'offramp'
    else:
        destination = 'mainline'
    return destination


#determine destination of vehicle based on the "isClose_sum" column
def findFieldOrigin(isClose_sum, thresh = 5):
    if isClose_sum >= thresh:
        origin = 'onramp'
    else:
        origin = 'mainline'
    return origin


#making simulation vehicle types consistent with field vehicle types
def convertVehType(vehType_id, source):  #source can be 'field' or 'simulation'
    if source == 'field':
        if vehType_id == 1:
            vehType_str = 'motor'
        elif vehType_id == 2:
            vehType_str = 'car'
        elif vehType_id == 3:
            vehType_str = 'truck'
    elif source == 'simulation':
        if vehType_id <= 5:
            vehType_str = 'car'
        else:
            vehType_str = 'truck'
    return vehType_str



def splitFieldData(df, cal_portion, df_cal_path, df_val_path):
    df_cal = {}
    df_val = {}
    for b in df['bin'].unique():
        veh_ids = df[df['bin'] == b]['vehId'].unique()
        random.shuffle(veh_ids)
        cal_num = math.floor(len(veh_ids) * cal_portion)
        cal_ids = veh_ids[:cal_num]
        val_ids = veh_ids[cal_num:]
        
        df_val[b] = df[df['vehId'].isin(val_ids)]
        df_cal[b] = df[df['vehId'].isin(cal_ids)]
        
        df_cal[b] = df_cal[b][['vehId', 'timeStamp.s','xCoord', 'yCoord', 'vehWidth.ft', 'vehLength.ft', 'Class..1.motor..2.auto..3.truck.', 'speed.ft/s', 'acceleration.ft/s2', 'laneIndex', 'spaceHeadway.ft','origin','destination','enterTime','bin','originLane']]
        df_val[b] = df_val[b][['vehId', 'timeStamp.s','xCoord', 'yCoord', 'vehWidth.ft', 'vehLength.ft', 'Class..1.motor..2.auto..3.truck.', 'speed.ft/s', 'acceleration.ft/s2', 'laneIndex', 'spaceHeadway.ft','origin','destination','enterTime','bin','originLane']]
    
    df_cal = pd.concat(df_cal)
    df_val = pd.concat(df_val)
    
    df_cal.to_csv(df_cal_path, sep = ',', index=False)
    df_val.to_csv(df_val_path, sep = ',', index=False)



def main():

    files_name = ['P1_Thu_255','P1_Thu_420','P1_Thu_540','P2_Thu_255','P2_Thu_420','P2_Thu_540','P3_Thu_420','P4_Thu_420']

    #study section's beginning and end is found using anothre script and is given here as input
    entrance_dict = {}
    exit_dict = {}
    entrance_dict['P1_Thu_255'] = [-117.07848500000001, 33.028639399999996]
    exit_dict['P1_Thu_255'] = [-117.077924, 33.0320309]
    entrance_dict['P1_Thu_420'] = [-117.07848500000001, 33.028639399999996]
    exit_dict['P1_Thu_420'] = [-117.077924, 33.0320309]
    entrance_dict['P1_Thu_540'] = [-117.07848500000001, 33.028639399999996]
    exit_dict['P1_Thu_540'] = [-117.077924, 33.0320309]

    entrance_dict['P2_Thu_255'] = [-117.078547, 33.0252551]
    exit_dict['P2_Thu_255'] = [-117.078526, 33.0281236]
    entrance_dict['P2_Thu_420'] = [-117.078547, 33.0252551]
    exit_dict['P2_Thu_420'] = [-117.078526, 33.0281236]
    entrance_dict['P2_Thu_540'] = [-117.078547, 33.0252551]
    exit_dict['P2_Thu_540'] = [-117.078526, 33.0281236]

    entrance_dict['P3_Thu_420'] = [-117.099957, 32.957094579999996]
    exit_dict['P3_Thu_420'] = [-117.09913600000002, 32.958414399999995]

    entrance_dict['P4_Thu_420'] = [-117.107804, 32.945208040000004]
    exit_dict['P4_Thu_420'] = [-117.10710800000001, 32.9462636]


    df_road_dict = {}
    for key in files_name:
        road_file_path = "/Users/farnoush.khalighi/Documents/Work/Trajectory Inverstigation- FHWA/trj-based Calibration/Road_Geometry/" + key + "_checkpoint.csv"
        df_road_dict[key] = readRoadCoordFile(road_file_path) 


    files_path = {}
    df_field_dict = {}
    for file in files_name:
        path = "/Users/farnoush.khalighi/Documents/Work/Trajectory Inverstigation- FHWA/trj-based Calibration/field_trj/I-15-fixed/" + file + ".csv"
        files_path[file] = path
        df_field_dict[file] = readData(path)


    #remove incomplete trajectories
    for key in files_name:
        df_field_dict[key]['dist_entrance'] = df_field_dict[key].apply(lambda x:findDistanceXYToFixedPoint(x['xCoord'], x['yCoord'], entrance_dict[key]), axis=1)
        df_field_dict[key]['dist_exit'] = df_field_dict[key].apply(lambda x:findDistanceXYToFixedPoint(x['xCoord'], x['yCoord'], exit_dict[key]), axis=1)
        df_field_dict[key]['isClose_entrance'] = df_field_dict[key].apply(lambda x:isCloseEntranceExit(x['dist_entrance'], thresh = 10), axis=1)
        df_field_dict[key]['isClose_exit'] = df_field_dict[key].apply(lambda x:isCloseEntranceExit(x['dist_exit'], thresh = 200), axis=1)  #the threshold for exit distance is not very restrictive because otherwise a significant portion of trajectories are removed
        df_field_dict[key]['isClose_entrance_sum'] = df_field_dict[key].groupby('vehId')['isClose_entrance'].transform('sum')
        df_field_dict[key]['isClose_exit_sum'] = df_field_dict[key].groupby('vehId')['isClose_exit'].transform('sum')
        df_field_dict[key]['is_complete_trj'] = df_field_dict[key].apply(lambda x:isCompleteTrj(x['isClose_entrance_sum'], x['isClose_exit_sum']), axis=1)
        indexNames = df_field_dict[key][df_field_dict[key]['is_complete_trj'] == False].index
        df_field_dict[key].drop(indexNames, inplace=True)


     #find origin lane and etering time to the section of field vehicles
    for key in files_name:
        df_field_dict[key]['min_dist_entrance'] = df_field_dict[key].groupby('vehId')['dist_entrance'].transform('min')
        df_field_dict[key]['min_dist_diff'] = df_field_dict[key].apply(lambda x:x['dist_entrance'] - x['min_dist_entrance'], axis=1)
        df_field_dict[key]['add_lane_index'] = df_field_dict[key].apply(lambda x:x['min_dist_diff']*99999999 + x['laneIndex'], axis=1)
        df_field_dict[key]['originLane'] = df_field_dict[key].groupby('vehId')['add_lane_index'].transform('min')
        df_field_dict[key]['add_timestamp'] = df_field_dict[key].apply(lambda x:x['min_dist_diff']*9999999999 + x['timeStamp.s'], axis=1)
        df_field_dict[key]['enterTime'] = df_field_dict[key].groupby('vehId')['add_timestamp'].transform('min')


    #finding the origin of field vehicles
    for key in files_name:
        df_field_dict[key]['origin'] = 'mainline'

    p2_list_temp = ['P2_Thu_255', 'P2_Thu_420', 'P2_Thu_540']
    for i in p2_list_temp:
        addDistancetoRampCols(df_field_dict[i], df_road_dict[i], sectionId_ramp=654321)
        df_field_dict[i]['isClose'] = df_field_dict[i].apply(lambda x:isCloseRamp(x['dist_rampCP_1'], x['dist_rampCP_2'], x['laneIndex'], num_of_lane=1, thresh=10), axis=1)
        df_field_dict[i]['isClose_sum'] = df_field_dict[i].groupby('vehId')['isClose'].transform('sum')
        df_field_dict[i]['origin'] = df_field_dict[i].apply(lambda x:findFieldOrigin(x['isClose_sum'], thresh=5), axis=1)



    #finding the destination of field vehicle 
    for key in files_name:
        df_field_dict[key]['destination'] = 'mainline'

    addDistancetoRampCols(df_field_dict['P3_Thu_420'], df_road_dict['P3_Thu_420'], sectionId_ramp=22752)
    df_field_dict['P3_Thu_420']['isClose'] = df_field_dict['P3_Thu_420'].apply(lambda x:isCloseRamp(x['dist_rampCP_1'], x['dist_rampCP_2'], x['laneIndex'], num_of_lane=2, thresh=10), axis=1)
    df_field_dict['P3_Thu_420']['isClose_sum'] = df_field_dict['P3_Thu_420'].groupby('vehId')['isClose'].transform('sum')
    df_field_dict['P3_Thu_420']['destination'] = df_field_dict['P3_Thu_420'].apply(lambda x:findFieldDestination(x['isClose_sum'], thresh=5), axis=1)

    addDistancetoRampCols(df_field_dict['P4_Thu_420'], df_road_dict['P4_Thu_420'], sectionId_ramp=20301)
    df_field_dict['P4_Thu_420']['isClose'] = df_field_dict['P4_Thu_420'].apply(lambda x:isCloseRamp(x['dist_rampCP_1'], x['dist_rampCP_2'], x['laneIndex'], num_of_lane=2, thresh=10), axis=1)
    df_field_dict['P4_Thu_420']['isClose_sum'] = df_field_dict['P4_Thu_420'].groupby('vehId')['isClose'].transform('sum')
    df_field_dict['P4_Thu_420']['destination'] = df_field_dict['P4_Thu_420'].apply(lambda x:findFieldDestination(x['isClose_sum'], thresh=5), axis=1)



    #converting vehicle type from an integer to a string to make it consistent in field and simulation data so later we can use it in binning data
    for key in files_name:
        df_field_dict[key]['vehType_str'] = df_field_dict[key].apply(lambda x:convertVehType(x['Class..1.motor..2.auto..3.truck.'], source='field'), axis=1)


    #concatenate bin_related columns to create a unique bin column
    for key in files_name:
        df_field_dict[key]['bin'] = df_field_dict[key]['origin'].map(str) + df_field_dict[key]['originLane'].map(str) + df_field_dict[key]['destination'].map(str) + df_field_dict[key]['vehType_str']


    for key in files_name:
        df_field_binned = {}
    for b in df_field_dict[key]['bin'].unique():
        df_field_binned[b] = df_field_dict[key][df_field_dict[key]['bin'] == b]
    
    cal_file_path = "/Users/farnoush.khalighi/Documents/Work/Trajectory Inverstigation- FHWA/trj-based Calibration/field_trj/SplittedFieldData/20200430/" + key + "_cal.csv"
    val_file_path = "/Users/farnoush.khalighi/Documents/Work/Trajectory Inverstigation- FHWA/trj-based Calibration/field_trj/SplittedFieldData/20200430/" + key + "_val.csv"
    splitFieldData(df_field_dict[key], 0.8, cal_file_path, val_file_path)



main()























