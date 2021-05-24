
first_row = 365;
last_row = 421;
data_folder = 'Data and results\';

% t_num 5-min timestamps. columns: flow and speed of S, flow and speed of N
t_num = last_row-first_row+1;
field_data = zeros(t_num,4); 

S_lane = cell(4,1);
N_lane = cell(4,1);
S_lane{1} = readmatrix([data_folder,'S of Gordon Blvd.xlsx'],'Sheet','Lane 1',...
    'Range',[first_row 3 last_row 13]);
S_lane{2} = readmatrix([data_folder,'S of Gordon Blvd.xlsx'],'Sheet','Lane 2',...
    'Range',[first_row 3 last_row 13]);
S_lane{3} = readmatrix([data_folder,'S of Gordon Blvd.xlsx'],'Sheet','Lane 3',...
    'Range',[first_row 3 last_row 13]);
S_lane{4} = readmatrix([data_folder,'S of Gordon Blvd.xlsx'],'Sheet','Lane 4',...
    'Range',[first_row 3 last_row 13]);
N_lane{1} = readmatrix([data_folder,'N of Gordon Blvd.xlsx'],'Sheet','Lane 1',...
    'Range',[first_row 3 last_row 13]);
N_lane{2} = readmatrix([data_folder,'N of Gordon Blvd.xlsx'],'Sheet','Lane 2',...
    'Range',[first_row 3 last_row 13]);
N_lane{3} = readmatrix([data_folder,'N of Gordon Blvd.xlsx'],'Sheet','Lane 3',...
    'Range',[first_row 3 last_row 13]);
N_lane{4} = readmatrix([data_folder,'N of Gordon Blvd.xlsx'],'Sheet','Lane 4',...
    'Range',[first_row 3 last_row 13]);

S_counts = sum(S_lane{1},2)+sum(S_lane{2},2)+sum(S_lane{3},2)+sum(S_lane{4},2);
N_counts = sum(N_lane{1},2)+sum(N_lane{2},2)+sum(N_lane{3},2)+sum(N_lane{4},2);

% getting off-ramp volume ratio for vehicle route decisions
S_ramp_ratio = sum(S_lane{4},2)./S_counts;
N_ramp_ratio = sum(N_lane{4},2)./N_counts;
S_ramp_ratio_15min = zeros(1,length(N_ramp_ratio)/3);
for i = 1:length(S_ramp_ratio_15min)
    S_ramp_ratio_15min(i) = mean(S_ramp_ratio(3*i-2:3*i));
end
S_gp_ratio_15min = 1 - S_ramp_ratio_15min;

S_lane_speeds = cell(4,1);
N_lane_speeds = cell(4,1);
S_lane_speeds{1} = zeros(length(S_counts),1);
S_lane_speeds{2} = zeros(length(S_counts),1);
S_lane_speeds{3} = zeros(length(S_counts),1);
S_lane_speeds{4} = zeros(length(S_counts),1);
N_lane_speeds{1} = zeros(length(S_counts),1);
N_lane_speeds{2} = zeros(length(S_counts),1);
N_lane_speeds{3} = zeros(length(S_counts),1);
N_lane_speeds{4} = zeros(length(S_counts),1);
for l = 1:4
    for i = 1:length(S_counts)
        S_lane_speeds{l}(i) = (S_lane{l}(i,1)*5+S_lane{l}(i,2)*15+S_lane{l}(i,3)*25+S_lane{l}(i,4)*35+...
            S_lane{l}(i,5)*45+S_lane{l}(i,6)*55+S_lane{l}(i,7)*65+S_lane{l}(i,8)*75+S_lane{l}(i,9)*85+...
            S_lane{l}(i,10)*95+S_lane{l}(i,11)*105)/sum(S_lane{l}(i,:));
        N_lane_speeds{l}(i) = (N_lane{l}(i,1)*5+N_lane{l}(i,2)*15+N_lane{l}(i,3)*25+N_lane{l}(i,4)*35+...
            N_lane{l}(i,5)*45+N_lane{l}(i,6)*55+N_lane{l}(i,7)*65+N_lane{l}(i,8)*75+N_lane{l}(i,9)*85+...
            N_lane{l}(i,10)*95+N_lane{l}(i,11)*105)/sum(N_lane{l}(i,:));
    end
end

S_speeds = (S_lane_speeds{1}.*sum(S_lane{1},2)+S_lane_speeds{2}.*sum(S_lane{2},2)+...
    S_lane_speeds{3}.*sum(S_lane{3},2)+S_lane_speeds{4}.*sum(S_lane{4},2))./S_counts;
N_speeds = (N_lane_speeds{1}.*sum(N_lane{1},2)+N_lane_speeds{2}.*sum(N_lane{2},2)+...
    N_lane_speeds{3}.*sum(N_lane{3},2)+N_lane_speeds{4}.*sum(N_lane{4},2))./N_counts;

field_data(:,1) = S_counts.*12;
field_data(:,2) = S_speeds;
field_data(:,3) = N_counts.*12;
field_data(:,4) = N_speeds;
