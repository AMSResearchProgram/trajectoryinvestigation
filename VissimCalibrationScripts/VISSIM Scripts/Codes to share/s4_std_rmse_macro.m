clear
addpath([pwd,'\Data and results']);
bar_chart;
settings = unique(best_index)-1;
normlizer_coefficient = max(rmse_macro);
ignore_first_index = 6; % ignore the first x 5-min intervals
load('field_data')

% benchmark
% load('traditional_RMSE_benchmark.mat')

% rmse_macro = zeros(10,2); % throughput, speed
% for rnd_seed = 1:10
%     % between 0 and 0.5, and then sum them
%     
%     rsme_macro_normalized = zeros(1,3); % throughput, speed, sum
%     error = zeros(1,2); % throughput, speed
%     for ti = (rnd_seed-1)*num_ti+ignore_first_index+1:rnd_seed*num_ti
%         ti_field = ti - (rnd_seed-1)*num_ti;
%         if ti_field==7
%             speeds{1}(ti,1)
%         end
%         error(1) = error(1) + (throughputs{1}(ti,1)-field_data(ti_field,1))^2 +...
%             (throughputs{1}(ti,2)-field_data(ti_field,3))^2;
%         error(2) = error(2) + (speeds{1}(ti,1)-field_data(ti_field,2))^2 +...
%             (speeds{1}(ti,2)-field_data(ti_field,4))^2;   
%     end
%     rmse_macro(rnd_seed,1) = sqrt(error(1)./(num_ti-ignore_first_index)./2);
%     rmse_macro(rnd_seed,2) = sqrt(error(2)./(num_ti-ignore_first_index)./2);
% end


std_rmse = zeros(length(settings),1);
rmse_macro_throughput = zeros(length(settings),10);
rmse_macro_speed = zeros(length(settings),10);
for i = 1:length(settings)
    for rnd_seed = 1:10
        load(['results_traditional_',num2str(rnd_seed),'.mat'])
        % between 0 and 0.5, and then sum them
        num_ti = length(speed_all{1});
%         rmse_macro_normalized = zeros(num_ti,3); % throughput, speed, sum
        error = zeros(1,2); % throughput, speed
        for ti = ignore_first_index+1:num_ti
            error(1) = error(1) + (throughput_all{settings(i)}(ti,1)-field_data(ti,1))^2 +...
                (throughput_all{settings(i)}(ti,2)-field_data(ti,3))^2;
            error(2) = error(2) + (speed_all{settings(i)}(ti,1)-field_data(ti,2))^2 +...
                (speed_all{settings(i)}(ti,2)-field_data(ti,4))^2;   
        end
        rmse_macro_throughput(i,rnd_seed) = sqrt(error(1)./(num_ti-ignore_first_index)./2);
        rmse_macro_speed(i,rnd_seed) = sqrt(error(2)./(num_ti-ignore_first_index)./2);
    end
end
normalized_rmse_throughput = rmse_macro_throughput./normlizer_coefficient(1)./2;
normalized_rmse_speed = rmse_macro_speed./normlizer_coefficient(2)./2;
normalized_rmse = (normalized_rmse_throughput + normalized_rmse_speed);
for i = 1:size(normalized_rmse,1)
    std_rmse(i) = std(normalized_rmse(i,~isnan(normalized_rmse(i,:))));
end

std_weights = zeros(size(best_index,1),1);
for i = 1:size(best_index,1)
    std_sum = 0;
    for j = 1:10
        index = find(settings==best_index(i,j)-1);
        std_sum = std_sum+std_rmse(index);
    end
    std_weights(i) = std_sum/10;
end