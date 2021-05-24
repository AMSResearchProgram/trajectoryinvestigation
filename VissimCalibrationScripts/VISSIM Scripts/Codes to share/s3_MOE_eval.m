% This code along with micro_rmse_eval.m are used to post-process and
% evaluate the simulation outcomes. First, macroscopic root mean square
% errors (RMSE) are calculated by comparing the field and simulation
% throughput and speed data. These RMSEs are then normalized to fit within
% a range between 0 and 1. Second, microscopic RMSEs are derived with 
% a.	Calculates time headways for
% the field data. b.	Defines a time headway cutoff and categorizes
% vehicles in the field data into “conservative” and “aggressive.” c.
% Gets a sample of vehicles in the simulated trajectory dataset for each
% bin (using “sampling” code). d.	Finds the corresponding data points in
% the field data (using “pairing” code). e.	Calculates the headway and lane
% number errors for each pair of vehicles at each bin. f.	Calculates
% microscopic RMSE for each bin and then returns the average of all bins as
% the final microscopic RMSE. g.	Finally, MOE_eval saves the macroscopic
% and microscopic RMSE values.

clear

%%
calibration_percentage = 0.8;
sample_size = 120;
% driver type headway percentile
driver_cutoff_p = 50; %
hdwy_range = [0.5 5]; % sec
tol_t = 4; % sec
tol_p = 200; % ft

mydir  = pwd;
idcs   = strfind(mydir,'\');
newdir = mydir(1:idcs(end)-1);
addpath(newdir);
addpath([pwd,'\Data and results']);
load('results.mat')
load('bin_dist.mat')
load('main_data.mat')
%%
main_data = data;
rmse_bench_all = zeros(10,2);
for rng_i = 1:10

    data = main_data;
    rng_number = rng_i;
    micro_rmse_eval;
    
    save(['Data and results\RMSE_micro_',num2str(calibration_percentage),'_',num2str(rng_number),'.mat'],...
    'rmse_micro','rmse_bench')

    % temp
    rmse_bench_all(rng_i,:) = rmse_bench;
    save('Data and results\rmse_bench_all','rmse_bench_all');
end


