function [data_smoth] = Smoth_data(data)
%this function smooth given trajectory data
% 1. let v = vi-1 + a*t
% 2. let y = yi-1 + v*t
% 3. smoth y
% 4. recalculate speed and acceleration
% 5. smoth speed and reculate acc
% 6. smoth acc
% 7. reculate tra
vehn1 = min(data(:,1));
vehn2 = max(data(:,1));
data_smoth = [];
for i = vehn1:vehn2
    vehidata = data(any(data(:,1) == i,2),:);
    if(~isempty(vehidata))
        vehiy = vehidata(:,5);

        vehiy = smoothdata(vehiy,'gaussian',4*30);

        vehispd = diff(vehiy);
        vehispd = [vehispd; vehispd(end)] * 30;

        vehispd = smoothdata(vehispd,'gaussian',2*30);

        vehiacc = diff(vehispd);
        vehiacc = [vehiacc; vehiacc(end)] * 30;

        vehiacc = smoothdata(vehiacc,'gaussian',2*30);
        

        detspd = cumsum(vehiacc / 30);
        vehispd = vehispd(1) + detspd;
        vehispd(:) = min(vehispd(:),150);

        dety = cumsum(vehispd/30);
        vehiy = vehiy(1) + dety;

        vehidata(:,5) = vehiy(:);
        vehidata(:,11) = vehispd(:);
        vehidata(:,12) = vehiacc(:);
        data_smoth = [data_smoth ; vehidata];
    end
end

end

