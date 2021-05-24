clear
hdwy_range = [0.5 5]; % sec
driver_cutoff_p = 50; %

%% Loading trajectory data
% data_path = [mydir,'\Refined Trajectories\Thu\'];
mydir  = pwd;
data_path = [mydir,'\Data and results\Trajectory Data\XY\'];
addpath(data_path)
listing = dir([data_path,'\P1*.csv']);
num_files = size(listing,1);

% time: column 3 in the old and column 2 in the new dataset
time.start = [];
time.end = [];
time.site = [];
data.p1 = [];
for i = 1:num_files
     data_temp = readmatrix(listing(i).name,'Range',2);
     data.p1 = [data.p1;data_temp];
     time.start = [time.start;min(data_temp(:,2))];
     time.end = [time.end;max(data_temp(:,2))];
     time.site = [time.site;1];
end
listing = dir([data_path,'\P2*.csv']);
num_files = size(listing,1);
data.p2 = [];
for i = 1:num_files
     data_temp = readmatrix(listing(i).name,'Range',2);
     data.p2 = [data.p2;data_temp];
     time.start = [time.start;min(data_temp(:,2))];
     time.end = [time.end;max(data_temp(:,2))];
     time.site = [time.site;2];
end
% Tabulating the data
data = tabulate_data(data,data_path);

% trajectory time limit
data.time_periods = zeros(length(time.start),3); % rows: data files, columns: start and end time and site location
data.time_periods(:,1) = time.start;
data.time_periods(:,2) = time.end;
data.time_periods(:,3) = time.site;

% trajectory locaiton limit
network.loc_limits = zeros(2,4); % rows: sites, columns: x_min,x_max,y_min,y_max 
network.loc_limits(1,1) = min(data.p1.X);
network.loc_limits(1,2) = max(data.p1.X);
network.loc_limits(1,3) = min(data.p1.Y);
network.loc_limits(1,4) = max(data.p1.Y);
network.loc_limits(2,1) = min(data.p2.X);
network.loc_limits(2,2) = max(data.p2.X);
network.loc_limits(2,3) = min(data.p2.Y);
network.loc_limits(2,4) = max(data.p2.Y);

% vehicle ids should be non-zero
min_p1_id = min(data.p1.Vehicle_ID);
if min_p1_id==0
    data.p1.Vehicle_ID = data.p1.Vehicle_ID +1;
end
% put all zones into one and make vehicle ids unique
max_p1_id = max(data.p1.Vehicle_ID);
data.p2.Vehicle_ID = data.p2.Vehicle_ID+ max_p1_id +2;
max_p2_id = max(data.p2.Vehicle_ID);
data.p_all = [data.p1;data.p2];

% calculate headways
data.p_all.Headway = data.p_all.Space_Highway_ft./data.p_all.Speed_ft_s;
valid_hdwy_car_index = (data.p_all.Class_1_motor__2_auto__3_truck==2 &...
 data.p_all.Headway>hdwy_range(1) & data.p_all.Headway<hdwy_range(2));
ID_all_car = unique(data.p_all.Vehicle_ID(valid_hdwy_car_index));
hdwy_cars = zeros(length(ID_all_car),1);
for n = ID_all_car'
    index = (data.p_all.Vehicle_ID==n).*valid_hdwy_car_index;
    if sum(index)>0
        hdwy_cars(n) = mean(data.p_all.Headway(index==1));
    end
end
hdwy_cutoff_car = prctile(hdwy_cars(hdwy_cars>0),driver_cutoff_p);
valid_hdwy_truck_index = (data.p_all.Class_1_motor__2_auto__3_truck==3 &...
 data.p_all.Headway>hdwy_range(1) & data.p_all.Headway<hdwy_range(2));
ID_all_truck = unique(data.p_all.Vehicle_ID(valid_hdwy_truck_index));
hdwy_trucks = zeros(length(ID_all_truck),1);
for n = ID_all_truck'
    index = (data.p_all.Vehicle_ID==n).*valid_hdwy_truck_index;
    if sum(index)>0
        hdwy_trucks(n) = mean(data.p_all.Headway(index==1));
    end
end
hdwy_cutoff_truck = prctile(hdwy_trucks(hdwy_trucks>0),driver_cutoff_p);

% driver type
ID_all = unique(data.p_all.Vehicle_ID);
for n = ID_all'
    index = (data.p_all.Vehicle_ID==n & data.p_all.Headway>hdwy_range(1) & data.p_all.Headway<hdwy_range(2));
    veh_type = unique(data.p_all.Class_1_motor__2_auto__3_truck(index));
    if sum(index)>1
        hdwy_avg = mean(data.p_all.Headway(index));
        if veh_type==2
            if hdwy_avg<=hdwy_cutoff_car
                data.p_all.aggressive(index) = 1;
            else
                data.p_all.aggressive(index) = 0;
            end
        elseif veh_type==3
            if hdwy_avg<=hdwy_cutoff_truck
                data.p_all.aggressive(index) = 1;
            else
                data.p_all.aggressive(index) = 0;
            end
        else
            data.p_all.aggressive(index) = NaN;
        end
    else
        data.p_all.aggressive(index) = NaN;
    end
end
    
save('main_data.mat','data','hdwy_cutoff_car', '-v7.3')
