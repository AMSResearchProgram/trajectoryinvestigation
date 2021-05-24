% this code enumerates through all parameter settings and calls the
% Vissim_eval code for each parameter set. It also reads the location and
% time limits of the trajectory data and passes it to the Vissim_eval code,
% so that Vissim_eval collects simulated trajectories only within the same
% location and time limits. Vissim_eval returns the macroscopic measures
% (throughput and speed) and trajectories to Enumerate. Enumerate then
% saves these outcomes. 
% In this code, the following procedures are perfromed to prepare the
% trajectory data:
% a.	Reads the field-collected trajectories. b.	Reformats the field
% data into a structure similar to Next Generation Simulation (NGSIM)
% dataset. c.	Combines all field data zones into one big table and makes
% vehicle identifications (ID) unique.

%% Parameters and variables
CC1_all = 0.7:0.1:0.9;
CC45_all = [0.25,0.35];
% deceleration reduction distance
drd_all = [50,100,200];
% accepted deceleration (trailing)
adt_all = [-1.64,-3.28,-6.27];
% safety distance reduction factor
sdrf_all = 0.2:0.2:0.6;

random_seeds_all = 1:5;

collect_traj = 1; % collect trajectory data if 1, 0 otherwise
Warm_up_Period = 900;
End_of_Simulation = 17100;

% this Vissim simulation model starts at 5:30 AM >> 19800 seconds after midnight
time_offset = 19800;

num_scenarios = length(CC1_all)*length(CC45_all)*length(drd_all)*length(adt_all)*length(sdrf_all);

throughput_all = cell(num_scenarios,1);
speed_all = cell(num_scenarios,1); 
sim_traj = cell(num_scenarios,1);
settings_all = zeros(num_scenarios,5); % parameters

%% Load trajectory data (if collect_traj is 1)
% change according to your data folder, file names, and formats
if collect_traj
    % sample and pair at every delta_t seconds
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

%% Settings and simulation run
for random_seed = random_seeds_all
    if random_seed==1
        continue
    end
    throughput_all = cell(num_scenarios,1);
    speed_all = cell(num_scenarios,1); 
    sim_traj = cell(num_scenarios,1);
    settings_all = zeros(num_scenarios,6); % parameters
    file_name = ['results_',num2str(random_seed),'.mat'];    
    i = 1;
    for CC1 = CC1_all
        for CC45 = CC45_all
            for drd = drd_all
                for adt = adt_all
                    for sdrf = sdrf_all

                        parameters(1) = CC1;
                        parameters(2) = CC45;
                        parameters(3) = drd;
                        parameters(4) = adt;
                        parameters(5) = sdrf;
                        parameters(6) = random_seed;
                        settings_all(i,:) = parameters;
                        [throughput_all{i},speed_all{i},sim_traj{i}] = vissim_eval(parameters,collect_traj,delta_t,time_periods,loc_limits,...
                            time_offset,Warm_up_Period,End_of_Simulation);
                        while sum(sum(throughput_all{i}))==0
                            % could not open vissim, trying one more time
                            !taskkill -f -im vissim.exe
                            [throughput_all{i},speed_all{i},sim_traj{i}] = vissim_eval(parameters,collect_traj,delta_t,time_periods,loc_limits,...
                                time_offset,Warm_up_Period,End_of_Simulation);
                        end
                        save(file_name,'throughput_all','speed_all','sim_traj','settings_all')
                    end
                end
            end
        end
    end
    save(file_name,'throughput_all','speed_all','sim_traj','settings_all')
end

