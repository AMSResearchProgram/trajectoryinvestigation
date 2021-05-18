function [data_output] = Calculate_GPS(data, y, x)
pc = 12;
vpa(x,pc);
vpa(y,pc);
%here we fit GPS coordinates of the location x and y (x^G and y^G in the document)
p = polyfit(x,y,4);
y1 = polyval(p,x);
%show fitting results
figure
plot(x,y,'o')
hold on
plot(x,y1,'-')

ltop = 364000;
xmin = min(x);
xmax = max(x);
lx = xmin:10/ltop:xmax;
ly = polyval(p,lx);
ldy = lx;
ldy(1) = 0;
for i = 2:length(lx)
    ldy(i) = ldy(i-1) + ltop * sqrt((lx(i) - lx(i-1))^2 + (ly(i) - ly(i-1)) ^ 2);
end

% polynomial curve fitting function to fit 
% local moving distance ldy (M^G in the document) and 
% it's GPS coordinate lx (X^G in the document)

p2 = polyfit(ldy,lx,4);

tldx = polyval(p2,ldy);
%show fitting results
figure
plot(ldy,lx,'o')
hold on
plot(ldy,tldx,'-')

ty = data(:,5);
tdx = polyval(p2, ty);
tdy = polyval(p, tdx);

vpa(tdx, 12);
vpa(tdy, 12);
data(:,7) = tdx;
data(:,6) = tdy;
%for a signle(cx,cy);
data_output = data;
close all;
end

