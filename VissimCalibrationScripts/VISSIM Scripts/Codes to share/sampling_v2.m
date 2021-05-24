function sample_car = sampling_v2(sim_traj,sample_size,bin_dist,hdwy_cutoff_car)

rng(1)
% ignore destination 2 if there's no off-ramp

index_conservative_car = find(sim_traj.type==2 & sim_traj.hdwy_avg>=hdwy_cutoff_car);
index_aggressive_car = find(sim_traj.type==2 & sim_traj.hdwy_avg<hdwy_cutoff_car);
% for some reasons, lane numbers are zero or negative at the end of the
% simulation. So, a condition is added to avoid it
lanes_all = unique(sim_traj.lane_first(sim_traj.lane_first>0));
index_d1 = find(sim_traj.lane_last>1);
index_d2 = find(sim_traj.lane_last==1);
% columns: destination 1 conservative, destination 2 conservative,
% destination 1 aggressive, destination 2 aggressive
type_car_lane = cell(length(lanes_all),4); 
sample_car = cell(length(lanes_all),4); 

for l = 1:length(lanes_all)
    index_1 = find(sim_traj.lane_first==l);
    
    type_car_lane{l,1} = intersect(intersect(index_conservative_car,index_1),index_d1);
    max_size = round(bin_dist(l,1)*sample_size);
    if length(type_car_lane{l,1})>max_size
        sample_car{l,1} = type_car_lane{l,1}(randperm(length(type_car_lane{l,1}),max_size));
    else
        sample_car{l,1} = type_car_lane{l,1};
    end
    
    type_car_lane{l,2} = intersect(intersect(index_conservative_car,index_1),index_d2);
    max_size = round(bin_dist(l,2)*sample_size);
    if length(type_car_lane{l,2})>max_size
        sample_car{l,2} = type_car_lane{l,2}(randperm(length(type_car_lane{l,2}),max_size));
    else
        sample_car{l,2} = type_car_lane{l,2};
    end
    
    type_car_lane{l,3} = intersect(intersect(index_aggressive_car,index_1),index_d1);
    max_size = round(bin_dist(l,3)*sample_size);
    if length(type_car_lane{l,3})>max_size
        sample_car{l,3} = type_car_lane{l,3}(randperm(length(type_car_lane{l,3}),max_size));
    else
        sample_car{l,3} = type_car_lane{l,3};
    end
    
    type_car_lane{l,4} = intersect(intersect(index_aggressive_car,index_1),index_d2);
    max_size = round(bin_dist(l,4)*sample_size);
    if length(type_car_lane{l,4})>max_size
        sample_car{l,4} = type_car_lane{l,4}(randperm(length(type_car_lane{l,4}),max_size));
    else
        sample_car{l,4} = type_car_lane{l,4};
    end

end

end