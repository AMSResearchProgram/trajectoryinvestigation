clear
hdwy_range = [0.5 5]; % sec
driver_cutoff_p = 50; %
addpath([pwd,'\Data and results']);

%% Loading trajectory data
load('main_data') % run main_data_save first

% calculate headways
data.p_all.Headway = data.p_all.Space_Highway_ft./data.p_all.Speed_ft_s;
valid_hdwy_car_index = (data.p_all.Class_1_motor__2_auto__3_truck==2 &...
 data.p_all.Headway>hdwy_range(1) & data.p_all.Headway<hdwy_range(2));
ID_all_car = unique(data.p_all.Vehicle_ID(valid_hdwy_car_index));
hdwy_cars = zeros(length(ID_all_car),1);
for n = ID_all_car'
    index = (data.p_all.Vehicle_ID==n).*valid_hdwy_car_index;
    if sum(index)>0
        hdwy_cars(n) = mean(data.p_all.Headway(index==1));
    end
end

save('Data and results\hdwy_cars','hdwy_cars')

% load('Data and results\hdwy_cars')

hdwy_cutoff_car = prctile(hdwy_cars(hdwy_cars>0),50);
figure(1);clf;hold on
cdfplot(hdwy_cars(hdwy_cars>0));
line([hdwy_cutoff_car hdwy_cutoff_car],[0 1],'color','r','linestyle','--')
line([0 hdwy_cutoff_car],[0.5 0.5],'color','k','linestyle',':')
text(hdwy_cutoff_car/4,0.6,'Aggressive','fontsize',12)
text(3*hdwy_cutoff_car/2,0.6,'Conservative','fontsize',12)
set(gca,'fontsize',11)
xlabel('x: time headway (sec)')
title('Time Headway Cumulative Distribution')

