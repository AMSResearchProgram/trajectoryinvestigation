#This scripts calculates trajectory-based RMSE and saves the results in a csv file

import pandas as pd
from geopy.distance import distance
import math
import csv


#read data
#sourse is either 'field' or 'simulation'
def readData(file_path, source): 
    chunks = pd.read_csv(file_path, chunksize=100000)
    df = pd.concat(chunks)  
    if source == 'field':
        df = df[['vehId', 'timeStamp.s','xCoord', 'yCoord', 'vehWidth.ft', 'vehLength.ft', 'Class..1.motor..2.auto..3.truck.', 'speed.ft/s', 'acceleration.ft/s2', 'laneIndex', 'spaceHeadway.ft']]
        df.columns = ['vehId', 'timeStamp.s','xCoord', 'yCoord', 'vehWidth.ft', 'vehLength.ft', 'Class..1.motor..2.auto..3.truck.', 'speed.ft/s', 'acceleration.ft/s2', 'laneIndex', 'spaceHeadway.ft'] 
        m = df['spaceHeadway.ft'].astype(str).str.endswith(';;')
        df['spaceHeadway.ft'].loc[m] =  df['spaceHeadway.ft'].loc[m].astype(str).str[:-2]
    elif source == 'simulation':
        df = df[['did', 'infVeh.idSection', 'infVeh.type', 'infVeh.idVeh', 'infVeh.numberLane', 'x_world', 'y_world', 'timeSta', 'infVeh.CurrentSpeed', 'infVeh.TotalDistance', 'headway']]
        df.columns = ['replication', 'sectionId', 'vehType', 'vehId', 'laneIndex', 'xCoord', 'yCoord', 'timeStamp.s', 'speed.km/hr', 'travelledDistance.m', 'headway.s']
    df = df.astype(float)
    return df


#read road checkpoints' coordinate
def readRoadCoordFile(file_path):
    df = pd.read_csv(file_path)
    df = df.astype(float)
    return df


#headway doesn't exist in the field data and is calculated as spacing/speed
def addFieldHeadwayColumn(spacing, speed):
    if (spacing <= 0) or (speed <= 0) :
        headway = -1
    else:
        headway = spacing / speed
    return headway


#x and y are coordinates taken from a row in datafram, and p (p[x],p[y]) is a coordinate of a fixed point 
def findDistanceXYToFixedPoint(x, y, p): 
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


#adding two columns wich shows the distance of each row from the first and second checkpoint on the ramp
#ramp type can be 'onramp' or 'offramp'
def addDistancetoRampCols(df, df_road_coord, ramp_type, sectionId_ramp):
    counter = 0
    df_road_coord.sort_values(by='timeSta', ascending=True, inplace=True)
    for ind,row in df_road_coord.iterrows():
        if row['sectionId'] == sectionId_ramp:
            counter += 1
            if ramp_type == 'onramp':
                col_name = 'dist_on_CP_' + str(counter)
            elif ramp_type == 'offramp':
                col_name = 'dist_off_CP_' + str(counter)
            checkpoint = [row['xCoord'], row['yCoord']]
            df[col_name] = df.apply(lambda x:findDistanceXYToFixedPoint(x['xCoord'], x['yCoord'], checkpoint), axis=1)
            if counter == 2:
                break;


#check the proximity of the data row to offramp or onramp based on its distance to checkpoints 1 and 2 and its lane index        
def isCloseRamp(x1, x2, laneIndex, num_of_lane, thresh = 10):
    isClose = 0
    if ((x1 < thresh) or (x2 < thresh)) and (laneIndex <= num_of_lane):
        isClose = 1
    return isClose


#determine destination of vehicle based on the "isClose_sum" column
def findFieldOrigin(isClose_sum, thresh = 5):
    if isClose_sum >= thresh:
        origin = 'onramp'
    else:
        origin = 'mainline'
    return origin


#determine destination of vehicle based on the "isClose_sum" column
def findFieldDestination(isClose_sum, thresh = 5):
    if isClose_sum >= thresh:
        destination = 'offramp'
    else:
        destination = 'mainline'
    return destination


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


#determining road type in order to find simulation vehicles' origin and destination
def isRamp(section_id, ramp_id):
    is_ramp = 0
    if section_id == ramp_id:
        is_ramp = 1
    return is_ramp


#determining simulation vehicle's origin
def findSimulationOrigin(is_ramp_sum):
    origin = 'mainline'
    if is_ramp_sum >= 1:
        origin = 'onramp'
    return origin


#determining simulation vehicle's destination
def findSimulationDestination(is_ramp_sum):
    destination = 'mainline'
    if is_ramp_sum >= 1:
        destination = 'offramp'
    return destination


#df_bin_field and df_bin_sim are two dataframes with field and simulation ids respectively and enter time. "thresh" is the maximum acceptable enter time difference for paired ids
#the fundction returns a pairs list with elements [field_id ,simulation_id]
#df_bin_field is a dataframe of bin xx of field data, and df_bin_sim is a dataframe of the same bin of simulation data, and entrance is the XY coordinate of the section entrance
def pairTrj(df_bin_field,df_bin_sim,entrance):        
    pairs = []
    paired_id = 0
    if df_bin_field['vehId'].nunique() <= df_bin_sim['vehId'].nunique():
        for vehId in df_bin_field['vehId'].unique():
            enterTime_field = df_bin_field[df_bin_field['vehId'] == vehId]['enterTime'].iloc[0]
            df_bin_sim['pairing_time_diff'] = df_bin_sim.apply(lambda x:x['enterTime'] - enterTime_field, axis=1)
            min_time_diff = df_bin_sim['pairing_time_diff'].min()
            if min_time_diff < 60:
                paired_id = df_bin_sim[df_bin_sim['pairing_time_diff'] == min_time_diff]['vehId'].iloc[0]
                df_bin_sim = df_bin_sim[df_bin_sim['vehId'] != paired_id]
                pairs.append([vehId, paired_id])
    else:
        for vehId in df_bin_sim['vehId'].unique():
            enterTime_sim = df_bin_sim[df_bin_sim['vehId'] == vehId]['enterTime'].iloc[0]
            df_bin_field['pairing_time_diff'] = df_bin_field.apply(lambda x:x['enterTime'] - enterTime_sim, axis=1)
            min_time_diff = df_bin_field['pairing_time_diff'].min()
            if min_time_diff < 60:
                paired_id = df_bin_field[df_bin_field['pairing_time_diff'] == min_time_diff]['vehId'].iloc[0]
                df_bin_field = df_bin_field[df_bin_field['vehId'] != paired_id]
                pairs.append([paired_id, vehId])
    return pairs
        

#df_road is the road_coordinate and df_veh_trj is field or simulation dataframe of one vehicle 
#the function loops over checkpoint in df_road and find the closest point in df_veh_trj to that checkpoint
def findClosest(df_road, df_veh_trj, thresh = 20):  
    inds = {}
    for ind1, row1 in df_road.iterrows():
        dist0 = 100000
        x1, y1 = row1['xCoord'], row1['yCoord']
        p1 = [y1,x1]
        for ind2, row2 in df_veh_trj.iterrows():
            x2, y2 = row2['xCoord'], row2['yCoord']
            p2 = [y2,x2]
            dist = distance(p1,p2).m
            if dist < thresh and dist < dist0:
                dist0 = dist
                inds.update({ind1: ind2})
    return inds


#df1 and df2 are field and simulation datasets respectively. and paired-inds is the paired indices with road geometry data
#max_lane: max differece in number of lanes, which should be set for each location
#max_headway: max headway wis 5 sec
#max_tt is calculated assuming lowest speed of 10mi/hr and max speed of 70mi/hr, and 50 meter distance between sign posts.
#the weight of headway, tt, and lane changing is 2,2,1, respectively. So if the sum of normalized values is in range of 0-1, then the range for each of those (headway, tt, and lane change) should be 0.4, 0.4, 0.2.
def calculateTrjDifference(df_veh_field, df_veh_sim, paired_inds_field, paired_inds_sim, entrance, max_lane, max_headway, max_tt, normal_total, normal_lane_total, normal_headway_total, normal_tt_total, counter_obs): 
    previous_time_field = df_veh_field['enterTime'].iloc[0]
    previous_time_sim = df_veh_sim['enterTime'].iloc[0]
    previous_cp = 0

    max_cp = max(paired_inds_field, key=int)
    for cp in range(1,max_cp+1):
        if (cp in paired_inds_field) and (cp in paired_inds_sim):
            headway_field = df_veh_field['headway.s'].loc[paired_inds_field[cp]]
            headway_sim = df_veh_sim['headway.s'].loc[paired_inds_sim[cp]]
            if (headway_field > 0) and (headway_sim > 0):
                lane_field = df_veh_field['laneIndex'].loc[paired_inds_field[cp]]
                lane_sim = df_veh_sim['laneIndex'].loc[paired_inds_sim[cp]]
                normal_lane_diff = abs(lane_field - lane_sim) / (max_lane - 1)
                normal_lane_diff_weighted = normal_lane_diff * 0.2

                if headway_field > max_headway and headway_sim > max_headway:
                    normal_headway_diff = 0
                    normal_headway_diff_weighted = 0
                elif (headway_field > max_headway and headway_sim < max_headway) or (headway_field < max_headway and headway_sim > max_headway):
                    normal_headway_diff = 1
                    normal_headway_diff_weighted = 0.4
                else:
                    normal_headway_diff = abs(headway_field - headway_sim) / max_headway
                    normal_headway_diff_weighted = normal_headway_diff * 0.4
                
                tt_field = df_veh_field['timeStamp.s'].loc[paired_inds_field[cp]] - previous_time_field
                previous_time_field = df_veh_field['timeStamp.s'].loc[paired_inds_field[cp]]
                tt_sim = df_veh_sim['timeStamp.s'].loc[paired_inds_sim[cp]] - previous_time_sim
                previous_time_sim = df_veh_sim['timeStamp.s'].loc[paired_inds_sim[cp]]
                cp_diff = cp - previous_cp
                normal_tt_diff = abs(tt_field - tt_sim) / (max_tt * cp_diff)
                normal_tt_diff_weighted = normal_tt_diff * 0.4
                previous_cp = cp

                normal_total += (normal_lane_diff_weighted + normal_headway_diff_weighted + normal_tt_diff_weighted)**2
                normal_lane_total += normal_lane_diff**2
                normal_headway_total += normal_headway_diff**2
                normal_tt_total += normal_tt_diff**2
                counter_obs += 1

    return [normal_total, normal_lane_total, normal_headway_total, normal_tt_total, counter_obs]



def main():

    #keys of dictionaries "dataset_names" and "df_road" should be the same.
    dataset_names = ['P1_Thu_255_val', 'P1_Thu_420_val', 'P1_Thu_540_val', 'P2_Thu_255_val', 'P2_Thu_420_val', 'P2_Thu_540_val', 'P3_Thu_420_val', 'P4_Thu_420_val']
    
    #read field datasets and create a dataframe for each dataset
    df_field = {}
    for key in dataset_names:
        path = r"/Users/farnoush.khalighi/Documents/Work/Trajectory Inverstigation- FHWA/trj-based Calibration/field_trj/SplittedFieldData/20200430/%s" % key + ".csv"
        df_field[key] = readData(path, 'field')
        df_field[key]['headway.s'] = df_field[key].apply(lambda x:addFieldHeadwayColumn(x['spaceHeadway.ft'], x['speed.ft/s']), axis=1)


    #read checkpoints' XY coordinate for all locations
    path_road_P1 = r"//Users/farnoush.khalighi/Documents/Work/Trajectory Inverstigation- FHWA/trj-based Calibration/Road_Geometry/P1_Thu_255_checkpoint.csv"
    path_road_P2 = r"//Users/farnoush.khalighi/Documents/Work/Trajectory Inverstigation- FHWA/trj-based Calibration/Road_Geometry/P2_Thu_255_checkpoint.csv"
    path_road_P3 = r"//Users/farnoush.khalighi/Documents/Work/Trajectory Inverstigation- FHWA/trj-based Calibration/Road_Geometry/P3_Thu_420_checkpoint.csv"
    path_road_P4 = r"//Users/farnoush.khalighi/Documents/Work/Trajectory Inverstigation- FHWA/trj-based Calibration/Road_Geometry/P4_Thu_420_checkpoint.csv"
    df_road_P1 = readRoadCoordFile(path_road_P1)
    df_road_P2 = readRoadCoordFile(path_road_P2)
    df_road_P3 = readRoadCoordFile(path_road_P3)
    df_road_P4 = readRoadCoordFile(path_road_P4)

    #create a dictionary with the same keys as "dataset_names"
    df_road = {'P1_Thu_255_val':df_road_P1, 'P1_Thu_420_val':df_road_P1, 'P1_Thu_540_val':df_road_P1, 'P2_Thu_255_val':df_road_P2, 'P2_Thu_420_val':df_road_P2, 'P2_Thu_540_val':df_road_P2, 'P3_Thu_420_val':df_road_P3, 'P4_Thu_420_val':df_road_P4}


    #the entrance and exit coordinate of studey sections has been calculated before and is given as an input here
    # keys of two dictionaries "entrance_dict" and "exit_dict" is the same as the keys of "dataset_names"
    entrance_dict = {}
    exit_dict = {}
    entrance_dict['P1_Thu_255_val'] = [-117.07848500000001, 33.028639399999996]
    exit_dict['P1_Thu_255_val'] = [-117.077924, 33.0320309]
    entrance_dict['P1_Thu_420_val'] = [-117.07848500000001, 33.028639399999996]
    exit_dict['P1_Thu_420_val'] = [-117.077924, 33.0320309]
    entrance_dict['P1_Thu_540_val'] = [-117.07848500000001, 33.028639399999996]
    exit_dict['P1_Thu_540_val'] = [-117.077924, 33.0320309]

    entrance_dict['P2_Thu_255_val'] = [-117.078547, 33.0252551]
    exit_dict['P2_Thu_255_val'] = [-117.078526, 33.0281236]
    entrance_dict['P2_Thu_420_val'] = [-117.078547, 33.0252551]
    exit_dict['P2_Thu_420_val'] = [-117.078526, 33.0281236]
    entrance_dict['P2_Thu_540_val'] = [-117.078547, 33.0252551]
    exit_dict['P2_Thu_540_val'] = [-117.078526, 33.0281236]

    entrance_dict['P3_Thu_420_val'] = [-117.099957, 32.957094579999996]
    exit_dict['P3_Thu_420_val'] = [-117.09913600000002, 32.958414399999995]

    entrance_dict['P4_Thu_420_val'] = [-117.107804, 32.945208040000004]
    exit_dict['P4_Thu_420_val'] = [-117.10710800000001, 32.9462636]


    #remove incomplete trajectories
    for key in dataset_names:
        df_field[key]['dist_entrance'] = df_field[key].apply(lambda x:findDistanceXYToFixedPoint(x['xCoord'], x['yCoord'], entrance_dict[key]), axis=1)
        df_field[key]['dist_exit'] = df_field[key].apply(lambda x:findDistanceXYToFixedPoint(x['xCoord'], x['yCoord'], exit_dict[key]), axis=1)
        df_field[key]['isClose_entrance'] = df_field[key].apply(lambda x:isCloseEntranceExit(x['dist_entrance'], thresh = 10), axis=1)
        #the threshold for exit distance is not very restrictive because otherwise a significant portion of trajectories are removed
        df_field[key]['isClose_exit'] = df_field[key].apply(lambda x:isCloseEntranceExit(x['dist_exit'], thresh = 200), axis=1)  
        df_field[key]['isClose_entrance_sum'] = df_field[key].groupby('vehId')['isClose_entrance'].transform('sum')
        df_field[key]['isClose_exit_sum'] = df_field[key].groupby('vehId')['isClose_exit'].transform('sum')
        df_field[key]['is_complete_trj'] = df_field[key].apply(lambda x:isCompleteTrj(x['isClose_entrance_sum'], x['isClose_exit_sum']), axis=1)
        indexNames = df_field[key][df_field[key]['is_complete_trj'] == False].index
        df_field[key].drop(indexNames, inplace=True)


    #finding the origin of field vehicles
    for key in dataset_names:
        df_field[key]['origin'] = 'mainline'

    #the only location with onramp is P2    
    p2_list = ['P2_Thu_255_val', 'P2_Thu_420_val', 'P2_Thu_540_val']
    for key in p2_list:
        addDistancetoRampCols(df_field[key], df_road[key], 'onramp', sectionId_ramp=654321)
        df_field[key]['isClose'] = df_field[key].apply(lambda x:isCloseRamp(x['dist_on_CP_1'], x['dist_on_CP_2'], x['laneIndex'], num_of_lane=1, thresh=10), axis=1)
        df_field[key]['isClose_sum'] = df_field[key].groupby('vehId')['isClose'].transform('sum')
        df_field[key]['origin'] = df_field[key].apply(lambda x:findFieldOrigin(x['isClose_sum'], thresh=5), axis=1)


    #find origin lane and etering time to the section of field vehicles
    for key in dataset_names:
        df_field[key]['min_dist_entrance'] = df_field[key].groupby('vehId')['dist_entrance'].transform('min')
        df_field[key]['min_dist_diff'] = df_field[key].apply(lambda x:x['dist_entrance'] - x['min_dist_entrance'], axis=1)
        df_field[key]['add_lane_index'] = df_field[key].apply(lambda x:x['min_dist_diff']*99999999 + x['laneIndex'], axis=1)
        df_field[key]['originLane'] = df_field[key].groupby('vehId')['add_lane_index'].transform('min')
        df_field[key]['add_timestamp'] = df_field[key].apply(lambda x:x['min_dist_diff']*9999999999 + x['timeStamp.s'], axis=1)
        df_field[key]['enterTime'] = df_field[key].groupby('vehId')['add_timestamp'].transform('min')


    #finding the destination of field vehicle 
    for key in dataset_names:
        df_field[key]['destination'] = 'mainline'

    addDistancetoRampCols(df_field['P3_Thu_420_val'], df_road['P3_Thu_420_val'], 'offramp', sectionId_ramp=22752)
    df_field['P3_Thu_420_val']['isClose'] = df_field['P3_Thu_420_val'].apply(lambda x:isCloseRamp(x['dist_off_CP_1'], x['dist_off_CP_2'], x['laneIndex'], num_of_lane=2, thresh=10), axis=1)
    df_field['P3_Thu_420_val']['isClose_sum'] = df_field['P3_Thu_420_val'].groupby('vehId')['isClose'].transform('sum')
    df_field['P3_Thu_420_val']['destination'] = df_field['P3_Thu_420_val'].apply(lambda x:findFieldDestination(x['isClose_sum'], thresh=5), axis=1)

    addDistancetoRampCols(df_field['P4_Thu_420_val'], df_road['P4_Thu_420_val'], 'offramp', sectionId_ramp=20301)
    df_field['P4_Thu_420_val']['isClose'] = df_field['P4_Thu_420_val'].apply(lambda x:isCloseRamp(x['dist_off_CP_1'], x['dist_off_CP_2'], x['laneIndex'], num_of_lane=2, thresh=10), axis=1)
    df_field['P4_Thu_420_val']['isClose_sum'] = df_field['P4_Thu_420_val'].groupby('vehId')['isClose'].transform('sum')
    df_field['P4_Thu_420_val']['destination'] = df_field['P4_Thu_420_val'].apply(lambda x:findFieldDestination(x['isClose_sum'], thresh=5), axis=1)


    #converting vehicle type from an integer to a string to make it consistent in field and simulation data so later we can use it in binning data
    for key in dataset_names:
        df_field[key]['vehType_str'] = df_field[key].apply(lambda x:convertVehType(x['Class..1.motor..2.auto..3.truck.'], source='field'), axis=1)


    #concatenate bin_related columns to create a unique bin column
    for key in dataset_names:
        df_field[key]['bin'] = df_field[key]['origin'].map(str) + df_field[key]['originLane'].map(str) + df_field[key]['destination'].map(str) + df_field[key]['vehType_str']


    #processing simulation data and calculating trajectory RMSEs
    inputFiles_sim = []

    for i in range(1,3):
        name = "simulation_trajectory_" + str(i)
        inputFiles_sim.append(name)
    
    df_sim = {}

    results_to_report = []

    for file_name in inputFiles_sim:

        file_path = r"/Users/farnoush.khalighi/Documents/Work/Trajectory Inverstigation- FHWA/Simulations_20200421/Trajectory_files_apa_70/%s" % file_name + ".csv"
        df_sim_all = readData(file_path, 'simulation')
        df_sim['P1_Thu_255_val'] = df_sim_all[(df_sim_all['sectionId'] == 23799) & (df_sim_all['timeStamp.s'] > 54000) & (df_sim_all['timeStamp.s'] < 54900)]
        df_sim['P1_Thu_420_val'] = df_sim_all[(df_sim_all['sectionId'] == 23799) & (df_sim_all['timeStamp.s'] > 59100) & (df_sim_all['timeStamp.s'] < 60000)]
        df_sim['P1_Thu_540_val'] = df_sim_all[(df_sim_all['sectionId'] == 23799) & (df_sim_all['timeStamp.s'] > 63900) & (df_sim_all['timeStamp.s'] < 64800)]
        df_sim['P2_Thu_255_val'] = df_sim_all[((df_sim_all['sectionId'] == 21342848) | (df_sim_all['sectionId'] == 23798)) & (df_sim_all['timeStamp.s'] > 54000) & (df_sim_all['timeStamp.s'] < 54900)]
        df_sim['P2_Thu_420_val'] = df_sim_all[((df_sim_all['sectionId'] == 21342848) | (df_sim_all['sectionId'] == 23798)) & (df_sim_all['timeStamp.s'] > 59100) & (df_sim_all['timeStamp.s'] < 60000)]
        df_sim['P2_Thu_540_val'] = df_sim_all[((df_sim_all['sectionId'] == 21342848) | (df_sim_all['sectionId'] == 23798)) & (df_sim_all['timeStamp.s'] > 63900) & (df_sim_all['timeStamp.s'] < 64800)]
        df_sim['P3_Thu_420_val'] = df_sim_all[((df_sim_all['sectionId'] == 2262591) | (df_sim_all['sectionId'] == 21342864) | (df_sim_all['sectionId'] == 22752)) & (df_sim_all['timeStamp.s'] > 59100) & (df_sim_all['timeStamp.s'] < 60000)]
        df_sim['P4_Thu_420_val'] = df_sim_all[((df_sim_all['sectionId'] == 2262585) | (df_sim_all['sectionId'] == 21342871) | (df_sim_all['sectionId'] == 20301)) & (df_sim_all['timeStamp.s'] > 59100) & (df_sim_all['timeStamp.s'] < 60000)]


        #finding the origin of simulation vehicles
        for key in dataset_names:
            df_sim[key]['origin'] = 'mainline'

        for i in p2_list:
            df_sim[i]['is_ramp'] = df_sim[i].apply(lambda x:isRamp(x['sectionId'], ramp_id=654321), axis=1)
            df_sim[i]['is_ramp_sum'] = df_sim[i].groupby('vehId')['is_ramp'].transform('sum')
            df_sim[i]['origin'] = df_sim[i].apply(lambda x:findSimulationOrigin(x['is_ramp_sum']), axis=1)


        #find origin lane and etering time to the section of simulation vehicles
        for key in dataset_names:
            df_sim[key]['dist_entrance'] = df_sim[key].apply(lambda x:findDistanceXYToFixedPoint(x['xCoord'], x['yCoord'], entrance_dict[key]), axis=1)
            df_sim[key]['dist_exit'] = df_sim[key].apply(lambda x:findDistanceXYToFixedPoint(x['xCoord'], x['yCoord'], exit_dict[key]), axis=1)
            df_sim[key]['min_dist_entrance'] = df_sim[key].groupby('vehId')['dist_entrance'].transform('min')
            df_sim[key]['min_dist_diff'] = df_sim[key].apply(lambda x:x['dist_entrance'] - x['min_dist_entrance'], axis=1)
            df_sim[key]['add_lane_index'] = df_sim[key].apply(lambda x:x['min_dist_diff']*99999999 + x['laneIndex'], axis=1)
            df_sim[key]['originLane'] = df_sim[key].groupby('vehId')['add_lane_index'].transform('min')
            df_sim[key]['add_timestamp'] = df_sim[key].apply(lambda x:x['min_dist_diff']*9999999999 + x['timeStamp.s'], axis=1)
            df_sim[key]['enterTime'] = df_sim[key].groupby('vehId')['add_timestamp'].transform('min')


        #finding the destination simulation vehicle
        for key in dataset_names:
            df_sim[key]['destination'] = 'mainline'

        df_sim['P3_Thu_420_val']['is_ramp'] = df_sim['P3_Thu_420_val'].apply(lambda x:isRamp(x['sectionId'], ramp_id=22752), axis=1)
        df_sim['P3_Thu_420_val']['is_ramp_sum'] = df_sim['P3_Thu_420_val'].groupby('vehId')['is_ramp'].transform('sum')
        df_sim['P3_Thu_420_val']['destination'] = df_sim['P3_Thu_420_val'].apply(lambda x:findSimulationDestination(x['is_ramp_sum']), axis=1)

        df_sim['P4_Thu_420_val']['is_ramp'] = df_sim['P4_Thu_420_val'].apply(lambda x:isRamp(x['sectionId'], ramp_id=20301), axis=1)
        df_sim['P4_Thu_420_val']['is_ramp_sum'] = df_sim['P4_Thu_420_val'].groupby('vehId')['is_ramp'].transform('sum')
        df_sim['P4_Thu_420_val']['destination'] = df_sim['P4_Thu_420_val'].apply(lambda x:findSimulationDestination(x['is_ramp_sum']), axis=1)


        #converting vehicle type from an integer to a string to make it consistent in field and simulation data so later we can use it in binning data
        for key in dataset_names:
            df_sim[key]['vehType_str'] = df_sim[key].apply(lambda x:convertVehType(x['vehType'], source='simulation'), axis=1) 


        #concatenate bin_related columns to create a unique bin column
        for key in dataset_names:
            df_sim[key]['bin'] = df_sim[key]['origin'].map(str) + df_sim[key]['originLane'].map(str) + df_sim[key]['destination'].map(str) + df_sim[key]['vehType_str']


        #calculating RMSE
        origin_list = ['mainline', 'onramp']
        origin_lane_list = [1.0,2.0,3.0,4.0,5.0,6.0,7.0]
        destination_list = ['mainline', 'offramp']
        vehType_list = ['motor', 'car', 'truck']
        bin_combinations = []
        for origin in origin_list:
            for origin_lane in origin_lane_list:
                for destination in destination_list:
                    for vehType in vehType_list:
                        bin_combinations.append(origin + str(origin_lane) + destination + vehType)


        normal_total = 0
        normal_lane_total = 0
        normal_headway_total = 0
        normal_tt_total = 0
        counter_obs = 0
        max_lane = 6
        max_headway = 5
        max_tt = 10  

        for key in dataset_names:
            for bin in bin_combinations:
                if len(df_field[key][df_field[key]['bin'] == bin]) > 0 and len(df_sim[key][df_sim[key]['bin'] == bin]) > 0:
                    df_bin_field = df_field[key][df_field[key]['bin'] == bin]
                    df_bin_sim = df_sim[key][df_sim[key]['bin'] == bin]
                    paired_veh = pairTrj(df_bin_field, df_bin_sim, entrance_dict[key])
                    for pair in paired_veh:
                        df_veh_field = df_field[key][df_field[key]['vehId'] == pair[0]]
                        df_veh_sim = df_sim[key][df_sim[key]['vehId'] == pair[1]]
                        paired_cp_inds_field = findClosest(df_road[key],df_veh_field,thresh = 20)
                        paired_cp_inds_sim = findClosest(df_road[key],df_veh_sim, thresh = 20)
                        pair_diff = calculateTrjDifference(df_veh_field, df_veh_sim, paired_cp_inds_field, paired_cp_inds_sim, entrance_dict[key], max_lane, max_headway, max_tt, normal_total, normal_lane_total, normal_headway_total, normal_tt_total, counter_obs)
                        normal_total = pair_diff[0]   
                        normal_lane_total = pair_diff[1]
                        normal_headway_total = pair_diff[2]
                        normal_tt_total = pair_diff[3]
                        counter_obs = pair_diff[4]


        RMSE_total = math.sqrt(normal_total / counter_obs)
        RMSE_lane = math.sqrt(normal_lane_total / counter_obs)
        RMSE_headway = math.sqrt(normal_headway_total / counter_obs)
        RMSE_tt = math.sqrt(normal_tt_total / counter_obs)

        results_to_report.append([file_name, RMSE_total, RMSE_lane, RMSE_headway, RMSE_tt])

        print([file_name,RMSE_total, RMSE_lane, RMSE_headway, RMSE_tt, normal_total, normal_lane_total, normal_headway_total, normal_tt_total, counter_obs])
        


    result_path = "/Users/farnoush.khalighi/Documents/Work/Trajectory Inverstigation- FHWA/Simulations_20200427/test.csv"
    header = ['Scenario_name', 'RMSE_total_weighted', 'RMSE_lane', 'RMSE_headway', 'RMSE_tt']
    with open(result_path, "w", newline='') as myfile:
        wr = csv.writer(myfile, quoting=csv.QUOTE_ALL)
        wr.writerow(header)
        for i in results_to_report:
            wr.writerow(i)


main()

























