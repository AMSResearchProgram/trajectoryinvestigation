function sim_traj = get_avg_hdwy(sim_traj,hdwy_range)

sim_traj.hdwy_avg = zeros(length(sim_traj.veh),1);
for i = 1:length(sim_traj.veh)
    index = (sim_traj.hdwy{i}>hdwy_range(1) & sim_traj.hdwy{i}<hdwy_range(2));
    sim_traj.hdwy_avg(i) = mean(sim_traj.hdwy{i}(index));
end

end