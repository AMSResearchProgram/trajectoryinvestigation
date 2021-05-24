clear
addpath([pwd,'\Data and results']);
load('main_data.mat') % run main_data_save first
load('results.mat') % replace this with the enumerate.m outputs
load('bin_dist.mat')
hdwy_range = [0.5 5]; % sec
sample_size = 120;
hdwy_cutoff_truck = 0; % trucks are ignored
tol_t = 4; % sec
tol_p = 200; % ft
hdwy_min = hdwy_range(1);
hdwy_max = hdwy_range(2);
data = data.p_all;

rmse_micro = zeros(length(speed_all),1);
for i = 1:length(speed_all)
    sim_traj{i} = get_avg_hdwy(sim_traj{i},hdwy_range);
    index_car = sampling_v2(sim_traj{i},sample_size,bin_dist,hdwy_cutoff_car);
    pair_index = pairing(sim_traj{i},data,index_car,tol_t,tol_p);

    % calculate RSME
    
    num_lane = length(unique(data.Lane_Num));
    rmse_micro_bins = zeros(size(pair_index.car.sim));
    for o = 1:size(pair_index.car.sim,1)
        for col = 1:4
            fx = 0;
            counter = 0;
            for n = 1:size(pair_index.car.sim{o,col},1)
                redundant_index = [];
                if isempty(pair_index.car.sim{o,col})
                    continue
                end
                if pair_index.car.sim{o,col}(n)==0 || pair_index.car.data{o,col}(n,2)==0
                    continue
                end
                veh_id_sim = pair_index.car.sim{o,col}(n);
                num_points = length(sim_traj{i}.time{veh_id_sim});
                veh_id_data = pair_index.car.data{o,col}(n,1);
                data_first_index = pair_index.car.data{o,col}(n,2);
                data_indices = data_first_index + find(data.Vehicle_ID(data_first_index:end)==veh_id_data)-1;
                data_time_all = data.Global_Time_s(data_indices);
                time_index = zeros(num_points,1);
                for j = 1:num_points
                    [min_temp,time_index(j)] = min(abs(data_time_all-sim_traj{i}.time{veh_id_sim}(j)));
                    if j>1 && time_index(j)==time_index(j-1)
                        if min_temp<min_pre
                            redundant_index = [redundant_index;j-1];
                        else
                            redundant_index = [redundant_index;j];
                        end
                    end
                    if min_temp>tol_t
                        time_index(j) = 0;
                        redundant_index = [redundant_index;j];
                    end
                    min_pre = min_temp;
                end
                if ~isempty(redundant_index)
                    time_index(time_index==0) = [];
                    time_index = unique(time_index);
                    num_points = length(time_index);
                    if length(data_indices)<num_points
                        warning('See here')
                    end
                end

                hdwy_sim = sim_traj{i}.hdwy{veh_id_sim};%(sim_traj.hdwy{veh_id_sim}>hdwy_min & sim_traj.hdwy{veh_id_sim}<hdwy_max);
                hdwy_sim(redundant_index) = [];
                hdwy_data = zeros(num_points,1);
                for j = 1:num_points
                    if  time_index(j)>0
                        hdwy_data(j) = data.Space_Highway_ft(data_indices(time_index(j)))/...
                            data.Speed_ft_s(data_indices(time_index(j)));
                    end
                end
                hdwy_sim(hdwy_sim>0 & hdwy_sim<hdwy_min) = hdwy_min;
                hdwy_sim(hdwy_sim<Inf & hdwy_sim>hdwy_max) = hdwy_max;
                hdwy_data(hdwy_data>0 & hdwy_data<hdwy_min) = hdwy_min;
                hdwy_data(hdwy_data<Inf & hdwy_data>hdwy_max) = hdwy_max;
                index_sim = hdwy_sim>0 & hdwy_sim<Inf;
                index_data = hdwy_data>0 & hdwy_data<Inf;
                index = index_sim.*index_data;
                if sum(index)>0
                    hdwy_error = mean(abs(hdwy_sim(index==1)-hdwy_data(index==1)));
                    hdwy_error = hdwy_error*(0.5/(hdwy_max-hdwy_min));
                end

                lane_sim = sim_traj{i}.lane{veh_id_sim}(time_index>0);    

                lane_data = data.Lane_Num(data_indices(time_index>0));
                lane_error = mean(abs(lane_sim-lane_data));
                % convert error to a number between 0 and 0.5
                lane_error = lane_error*(0.5/(num_lane-1));

                fx = fx + (hdwy_error)^2+(lane_error)^2;
                counter = counter + 1;
            end
            rmse_micro_bins(o,col) = sqrt(fx/counter);
        end
    end
    index_bins = ~isnan(rmse_micro_bins);
    rmse_micro_product = sum(sum(rmse_micro_bins(index_bins).*bin_dist(index_bins)));
    rmse_micro(i) = rmse_micro_product/sum(sum(bin_dist));
end
[rmse_calibration_traj,best_traj_index] = min(rmse_micro);
optimal_setting = settings_all(best_traj_index,:);
save('Data and results\optimal_setting_100','optimal_setting','rmse_micro');