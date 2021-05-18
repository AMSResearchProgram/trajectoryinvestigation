function [data] = Read_data(path)
%this function is used to read data from a csv file.
%format of the csv file should be consistent with the format showed in
%the data_description.docx.
data = csvread(path,1,0);
data = sortrows(data,1,'ascend');
end
