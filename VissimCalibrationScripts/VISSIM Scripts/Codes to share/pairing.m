function pair_index = pairing(sim_traj,data,sim_index_car,tol_t,tol_p)

% to match simulated trajectories with the field collected ones, first we
% filter them according to vehicle types. Second, we
% find the data points that have the same time as the first timestamp
% of a simulated trajectory. Then, we filter the ones within a certain
% distance from the first location point of the simulated trajectory.
rng(1)
% ignore destination 2 if there's no off-ramp

data_types = data.Class_1_motor__2_auto__3_truck;
data_times = data.Global_Time_s;

tol_x = tol_p; % ft
tol_y = tol_p; % ft

pair_index = [];
pair_index.car = [];
pair_index.truck = [];
pair_index.car.sim = sim_index_car;
% just for variable initialization
pair_index.car.data = sim_index_car;

data_index_car = data_types==2;
for col = 1:4
    for l = 1:size(sim_index_car,1)
        sim_index = sim_index_car{l,col};
        pair_index.car.data{l,col} = zeros(length(sim_index),2); % veh id and row in the data
        for i = 1:size(sim_index,1)
            if isempty(sim_index)
                continue
            end

            t_sim = sim_traj.time{sim_index(i)};
            x_sim = sim_traj.coordx{sim_index(i)};
            y_sim = sim_traj.coordy{sim_index(i)};
            data_index_time = abs(data_times-t_sim(1))<tol_t;
            data_index_xcoord = abs(data.X-x_sim(1))<tol_x;
            data_index_ycoord = abs(data.Y-y_sim(1))<tol_y;
            if col<3
                % conservative
                data_index_driver = data.aggressive==0;
            else
                % aggressive
                data_index_driver = data.aggressive==1;
            end
            data_index = data_index_car.*data_index_time.*data_index_xcoord.*data_index_ycoord.*data_index_driver==1;
            car_id_all = unique(data.Vehicle_ID(data_index));
            % choose randomly from the candidate vehicles
            while 1
                if isempty(car_id_all)
                    break
                end
                veh_id = car_id_all(randi(length(car_id_all)));
                % checking lane requirements
                lane_check = 1;
                data_veh_id_index = data.Vehicle_ID==veh_id;
                data_index_specific = data_index_time.*data_veh_id_index;
                first_index = find(data_index_specific==1,1);
                first_lane = data.Lane_Num(first_index);
                last_index = find(data_index_specific==1,1,'last');
                last_lane = data.Lane_Num(last_index);
                if first_lane~=l
                    lane_check = 0;
                end
                % d=1 or d=3 if the last lane is gp, 2 or 4 if off-ramp 
                % (or the right lane)
                if (rem(col,2)==1 && last_lane==1) || (rem(col,2)==0 && last_lane>1)
                    lane_check = 0;
                end
                if lane_check==1
                    pair_index.car.data{l,col}(i,1) = veh_id;
                    veh_id_index = data.Vehicle_ID==veh_id;
                    pair_index.car.data{l,col}(i,2) = find(data_index.*veh_id_index==1,1);
                    break
                else
                    car_id_all(car_id_all==veh_id) = [];
                end
            end
        end
    end
end


end