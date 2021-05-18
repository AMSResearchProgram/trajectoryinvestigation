function [data_cleaned] = Clean_data(data)
%remove short trajectories that less than 500 data points
data_cleaned = data;
vehN = max(data(:,1));
vehminN = min(data(:,1));

for n = vehminN:vehN
    datan = data(any(data(:,1) == n,2),:);
    nrows = length(datan(:,1));
    if ~isempty(nrows) && (nrows < 200 || abs(datan(1,5) - datan(end,5)) < 500)
        data_cleaned(any(data_cleaned(:,1) == n,2),:) = [];
    end
end

end


