% this code does everything enumerate.m does, but for the benchmark case

%% Parameters and variables

collect_traj = 1; % collect trajectory data if 1, 0 otherwise
Warm_up_Period = 900;
End_of_Simulation = 17100;

% This VISSIM simulation model starts at 5:30 AM >> 19800 seconds after midnight
time_offset = 19800;

%% Load trajectory data (if collect_traj is 1)
if collect_traj
    delta_t = 2;
    
    % trajectory data
    data_path = 'C:\Users\...\Trajectory data\';
    addpath(data_path)
    mydir  = pwd;
    idcs   = strfind(mydir,'\');
    newdir = mydir(1:idcs(end)-1);
    addpath(newdir);
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
    listing = dir([data_path,'\P3*.csv']);
    num_files = size(listing,1);
    data.p3 = [];
    for i = 1:num_files
         data_temp = readmatrix(listing(i).name,'Range',2);
         data.p3 = [data.p3;data_temp];
         time.start = [time.start;min(data_temp(:,2))];
         time.end = [time.end;max(data_temp(:,2))];
         time.site = [time.site;3];
    end
    
    data = tabulate_data(data,data_path);
    time_periods = zeros(length(time.start),3); % rows: data files, columns: start and end time and site location
    time_periods(:,1) = time.start;
    time_periods(:,2) = time.end;
    time_periods(:,3) = time.site;
    loc_limits = zeros(3,4); % rows: sites, columns: x_min,x_max,y_min,y_max 
    loc_limits(1,1) = min(data.p1.X);
    loc_limits(1,2) = max(data.p1.X);
    loc_limits(1,3) = min(data.p1.Y);
    loc_limits(1,4) = max(data.p1.Y);
    loc_limits(2,1) = min(data.p2.X);
    loc_limits(2,2) = max(data.p2.X);
    loc_limits(2,3) = min(data.p2.Y);
    loc_limits(2,4) = max(data.p2.Y);
    loc_limits(3,1) = min(data.p3.X);
    loc_limits(3,2) = max(data.p3.X);
    loc_limits(3,3) = min(data.p3.Y);
    loc_limits(3,4) = max(data.p3.Y);
else
    delta_t = 0;
    time_periods = 0;
    loc_limits = 0;
end

%% Simulation

parameters = [];
[throughput_bench,speed_bench,sim_traj_bench] = vissim_eval(parameters,collect_traj,delta_t,time_periods,loc_limits,...
    time_offset,Warm_up_Period,End_of_Simulation);
while sum(sum(throughput_bench{i}))==0
    % could not open vissim, trying one more time
    !taskkill -f -im vissim.exe
    [throughput_bench,speed_bench,sim_traj_bench] = vissim_eval(parameters,collect_traj,delta_t,time_periods,loc_limits,...
        time_offset,Warm_up_Period,End_of_Simulation);
end
