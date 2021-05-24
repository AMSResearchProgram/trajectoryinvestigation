clear
addpath([pwd,'\Data and results']);
num_seeds = 10;

load('rmse_macro_bench.mat')
bench_trad_rmse = rmse_macro;
load('rmse_bench_micro_all')
load('rmse_macro.mat') % this version is the average of all random seeds
% first row is benchmark
rmse_macro = [bench_trad_rmse;rmse_macro];
% find the maximum rmse among all random seeds
max_micro_rmse = 0;
max_macro_rmse = zeros(1,2);
for rnd_seed = 1:num_seeds
    file_name = ['RMSE_micro_0.8_',num2str(rnd_seed),'.mat'];
    load(file_name);
    max_micro_rmse = max(max_micro_rmse,max(max(rmse_micro)));
    for i = 1:length(rmse_macro)
        max_macro_rmse(1) = max(max_macro_rmse(1),max(rmse_macro{i}(:,1)));
        max_macro_rmse(2) = max(max_macro_rmse(2),max(rmse_macro{i}(:,2)));
    end
end

normalized_rmse_all = cell(num_seeds,1);

weights = 0:0.25:1;
best_index = zeros(length(weights),10);
for rnd_seed = 1:num_seeds
    
    file_name = ['RMSE_micro_0.8_',num2str(rnd_seed),'.mat'];
    load(file_name);
    
    % first row is benchmark
    rmse_micro = [rmse_bench_all(rnd_seed,:);rmse_micro];
    % macro, micro (80%), micro (20%)
    normalized_rmse = zeros(length(rmse_micro),3); 
    
    % throughput and speed normalized rmses are between 0-0.5 and traj
    % normalized rmse is between 0-1
    normalized_rmse_throughput = zeros(length(rmse_macro),1);
    normalized_rmse_speed = zeros(length(rmse_macro),1);
    for i = 1:length(rmse_macro)
        normalized_rmse_throughput(i) = rmse_macro{i}(rnd_seed,1)/max_macro_rmse(1)/2;
        normalized_rmse_speed(i) = rmse_macro{i}(rnd_seed,2)/max_macro_rmse(2)/2;
    end

    normalized_rmse(:,1) = (normalized_rmse_throughput + normalized_rmse_speed);
    normalized_rmse(:,2) = rmse_micro(:,1)./max_micro_rmse;
    normalized_rmse(:,3) = rmse_micro(:,2)./max_micro_rmse;

    y = [];
    y = [normalized_rmse(1,1),normalized_rmse(1,2),normalized_rmse(1,3)];
    for j = 1:length(weights)
        w = weights(j);
        rmse_combine = (1-w)*normalized_rmse(:,1)+w*normalized_rmse(:,2);
        [~,best_index(j,rnd_seed)] = min(rmse_combine(2:end));
        best_index(j,rnd_seed) = best_index(j,rnd_seed)+1;
        y = [y;normalized_rmse(best_index(j,rnd_seed),1),normalized_rmse(best_index(j,rnd_seed),2),normalized_rmse(best_index(j,rnd_seed),3)];
    end
    normalized_rmse_all{rnd_seed} = y';
end

normalized_rmse_reformat = cell(size(normalized_rmse_all{1}));
normalized_rmse_avg = zeros(size(normalized_rmse_all{1}));
normalized_rmse_std = zeros(size(normalized_rmse_all{1}));
for j = 1:size(normalized_rmse_all{1},1)
    for k = 1:size(normalized_rmse_all{1},2)
        for i = 1:10
            if i==1
                normalized_rmse_reformat{j,k} = normalized_rmse_all{i}(j,k);
            else
                normalized_rmse_reformat{j,k} = [normalized_rmse_reformat{j,k},normalized_rmse_all{i}(j,k)];
            end
        end
        normalized_rmse_avg(j,k) = mean(normalized_rmse_reformat{j,k});
        normalized_rmse_std(j,k) = std(normalized_rmse_reformat{j,k});
    end
end
normalized_rmse_avg_p = normalized_rmse_avg';
normalized_rmse_std_p = normalized_rmse_std';