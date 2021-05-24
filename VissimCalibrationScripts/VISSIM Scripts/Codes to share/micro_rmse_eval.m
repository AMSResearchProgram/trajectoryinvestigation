%% Calibration and Validation
hdwy_min = hdwy_range(1);
hdwy_max = hdwy_range(2);
% randomly divide the dataset into 2 for validation purposes
data = data.p_all;
% randomly divide the dataset into 2 for validation purposes
veh_id_all = unique(data.Vehicle_ID);
rng(rng_number)
set_vid = cell(2,1);
index_vid = sort(randperm(length(veh_id_all),round(length(veh_id_all)*calibration_percentage)))';
set_vid{1} = veh_id_all(index_vid);
set_vid{2} = find(ismember(veh_id_all,set_vid{1})==0);
field_names = data.Properties.VariableNames;
data_temp = table2array(data);

subdata = cell(2,1); % 80% & 20%
rmse_micro = zeros(length(speed_all),2); % 80% & 20%
for s = 1:2
    index_temp = [];
    for i = 1:length(set_vid{s})
        index_temp = [index_temp;find(data_temp(:,1)==set_vid{s}(i))];
    end
    data_temp2 = data_temp(index_temp,:);
    subdata{s} = array2table(data_temp2,'VariableNames',field_names);
    
    for i = 1:length(speed_all)
        sim_traj{i} = get_avg_hdwy(sim_traj{i},hdwy_range);
        index_car = sampling_v2(sim_traj{i},sample_size,bin_dist,hdwy_cutoff_car);
        pair_index = pairing(sim_traj{i},subdata{s},index_car,tol_t,tol_p);

        % calculate RSME

        num_lane = length(unique(subdata{s}.Lane_Num));
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
                    data_indices = data_first_index + find(subdata{s}.Vehicle_ID(data_first_index:end)==veh_id_data)-1;
                    data_time_all = subdata{s}.Global_Time_s(data_indices);
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
                            hdwy_data(j) = subdata{s}.Space_Highway_ft(data_indices(time_index(j)))/...
                                subdata{s}.Speed_ft_s(data_indices(time_index(j)));
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
                    else
                        continue
                    end

                    lane_sim = sim_traj{i}.lane{veh_id_sim}(time_index>0);    

                    lane_data = subdata{s}.Lane_Num(data_indices(time_index>0));
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
        rmse_micro(i,s) = rmse_micro_product/sum(sum(bin_dist));
    end
end
% [~,best_traj_index] = min(rmse_micro(:,1));
% optimal_setting_80 = settings_all(best_traj_index);
% [~,best_traj_index] = min(rmse_micro(:,2));
% optimal_setting_20 = settings_all(best_traj_index);
%% Benchmark
load('results_bench.mat')
hdwy_min = hdwy_range(1);
hdwy_max = hdwy_range(2);

sim_traj_bench = get_avg_hdwy(sim_traj_bench,hdwy_range);
index_car = sampling_v2(sim_traj_bench,sample_size,bin_dist,hdwy_cutoff_car);
rmse_bench = zeros(1,2); % 80% & 20%
for s = 1:2
    pair_index = pairing(sim_traj_bench,subdata{s},index_car,tol_t,tol_p);

    num_lane = length(unique(subdata{s}.Lane_Num));
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
                num_points = length(sim_traj_bench.time{veh_id_sim});
                veh_id_data = pair_index.car.data{o,col}(n,1);
                data_first_index = pair_index.car.data{o,col}(n,2);
                data_indices = data_first_index + find(subdata{s}.Vehicle_ID(data_first_index:end)==veh_id_data)-1;
                data_time_all = subdata{s}.Global_Time_s(data_indices);
                time_index = zeros(num_points,1);
                for j = 1:num_points
                    [min_temp,time_index(j)] = min(abs(data_time_all-sim_traj_bench.time{veh_id_sim}(j)));
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

                hdwy_sim = sim_traj_bench.hdwy{veh_id_sim};%(sim_traj.hdwy{veh_id_sim}>hdwy_min & sim_traj.hdwy{veh_id_sim}<hdwy_max);
                hdwy_sim(redundant_index) = [];
                hdwy_data = zeros(num_points,1);
                for j = 1:num_points
                    if  time_index(j)>0
                        hdwy_data(j) = subdata{s}.Space_Highway_ft(data_indices(time_index(j)))/...
                            subdata{s}.Speed_ft_s(data_indices(time_index(j)));
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
                else
                    continue
                end
                lane_sim = sim_traj_bench.lane{veh_id_sim}(time_index>0);    
                lane_data = subdata{s}.Lane_Num(data_indices(time_index>0));
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
    rmse_bench_product = sum(sum(rmse_micro_bins(index_bins).*bin_dist(index_bins)));
    rmse_bench(s) = rmse_bench_product/sum(sum(bin_dist));
end
% [~,best_traj_index] = min(rmse_micro);
% optimal_setting_80 = settings_all(best_traj_index);
