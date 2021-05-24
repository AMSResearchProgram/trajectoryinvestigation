clear
addpath([pwd,'\Data and results']);
load('field_data.mat')
num_settings = 162;
num_seeds = 10;
ignore_first_index = 6; % ignore the first x 5-min intervals

% benchmark with 10 random seeds
load('results_bench.mat')
% between 0 and 0.5, and then sum them
rmse_macro = zeros(length(throughput_all),2); % throughput, speed
for i = 1:length(throughput_all) 
    error = zeros(1,2); % throughput, speed
    for ti = ignore_first_index+1:length(speed_all{i})
        error(1) = error(1) + (throughput_all{i}(ti,1)-field_data(ti,1))^2 +...
            (throughput_all{i}(ti,2)-field_data(ti,3))^2;
        error(2) = error(2) + (speed_all{i}(ti,1)-field_data(ti,2))^2 +...
            (speed_all{i}(ti,2)-field_data(ti,4))^2;   
    end
    rmse_macro(i,1) = sqrt(error(1)./(length(speed_all{i})-ignore_first_index)./2);
    rmse_macro(i,2) = sqrt(error(2)./(length(speed_all{i})-ignore_first_index)./2);
end

save('Data and results\rmse_macro_bench_v3.mat','rmse_macro')

% all settings with 10 random seeds
% first, load data of all random seeds to save time
speeds = cell(num_seeds,1);
throughputs = cell(num_seeds,1);
for rnd_seed = 1:num_seeds
    file_name = ['results_traditional_',num2str(rnd_seed),'.mat'];
    load(file_name)
    speeds{rnd_seed} = speed_all;
    throughputs{rnd_seed} = throughput_all;
end

rmse_macro = cell(num_settings,1);
for i = 1:num_settings
    rmse_macro{i} = zeros(num_seeds,2);
    for rnd_seed = 1:num_seeds
        error = zeros(1,2); % throughput, speed
        count_nan_thr = 0;
        count_nan_spd = 0;
        for ti = ignore_first_index+1:length(speed_all{i})
            error_thr = (throughputs{rnd_seed}{i}(ti,1)-field_data(ti,1))^2 +...
                (throughputs{rnd_seed}{i}(ti,2)-field_data(ti,3))^2;
            error_spd = (speeds{rnd_seed}{i}(ti,1)-field_data(ti,2))^2 +...
                (speeds{rnd_seed}{i}(ti,2)-field_data(ti,4))^2;
            
            % count corrupt data points
            if isnan(error_thr)
                count_nan_thr = count_nan_thr+1;
            else
                error(1) = error(1) + error_thr;
            end
            if isnan(error_spd)
                count_nan_spd = count_nan_spd+1;
            else
                error(2) = error(2) + error_spd;
            end
        end
        rmse_macro{i}(rnd_seed,1) = sqrt(error(1)./(length(speeds{rnd_seed}{i})-ignore_first_index-count_nan_thr)./2);
        rmse_macro{i}(rnd_seed,2) = sqrt(error(2)./(length(speeds{rnd_seed}{i})-ignore_first_index-count_nan_spd)./2);
    end
end
save('Data and results\rmse_macro_v3.mat','rmse_macro')
