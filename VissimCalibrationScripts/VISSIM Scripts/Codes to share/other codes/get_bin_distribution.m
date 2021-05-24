clear
addpath([pwd,'\Data and results']);
load('results.mat') % replace this with the enumerate.m outputs
load('field_data.mat')
load('main_data.mat')
data = data.p_all;

%% Get first and last lane IDs for all vehicles
veh_ids_all = unique(data.Vehicle_ID);
veh_num = length(veh_ids_all);
veh_lane_info = zeros(max(veh_ids_all),2); % lane_first, lane_last
for n = veh_ids_all'
    index = find(data.Vehicle_ID==n);
    veh_lane_info(n,1) = data.Lane_Num(index(1));
    veh_lane_info(n,2) = data.Lane_Num(index(end));
end
index_d1 = find(veh_lane_info(:,1)>1);
index_d2 = find(veh_lane_info(:,1)==1);

%% Get driver type indices
index_conservative_car = find(data.Class_1_motor__2_auto__3_truck==2 & data.aggressive==1);
index_aggressive_car = find(data.Class_1_motor__2_auto__3_truck==2 & data.aggressive==0);

%% Get vehicle distributions
lanes_all = unique(data.Lane_Num);
type_car_lane = cell(length(lanes_all),4); % d1 cons, d2 cons, d1 aggres, d2 aggres
bin_dist = zeros(length(lanes_all),4);

for l = 1:length(lanes_all)
    index_1 = find(veh_lane_info(:,1)==l);
    
    type_car_lane{l,1} = intersect(intersect(index_conservative_car,index_1),index_d1);
    
    type_car_lane{l,2} = intersect(intersect(index_conservative_car,index_1),index_d2);
    
    type_car_lane{l,3} = intersect(intersect(index_aggressive_car,index_1),index_d1);
    
    type_car_lane{l,4} = intersect(intersect(index_aggressive_car,index_1),index_d2);
end
for i = 1:size(type_car_lane,1)
    for j = 1:size(type_car_lane,2)
        bin_dist(i,j) = length(type_car_lane{i,j})/veh_num;
    end
end
save('bin_dist','bin_dist')