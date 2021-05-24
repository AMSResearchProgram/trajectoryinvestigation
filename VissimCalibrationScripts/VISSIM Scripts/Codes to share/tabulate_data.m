function data = tabulate_data(data,data_path)
% This function converts the data into a table. The header names are taken
% from the csv files in data_path

listing = dir([data_path,'\P1*.csv']);
fid = fopen([data_path,listing(1).name]);
str = textscan(fid,'%s',1,'delimiter','\n');
fclose(fid);

% remove the last comma
str = char(str{1});
str = str(1:end);
% remove spaces
str = regexprep(str, ' ', '_');
% remove paranthesis
str = regexprep(str, '(', '');
str = regexprep(str, ')', '');
% remove semicolon
str = regexprep(str, ';', '_');
% remove slash
str = regexprep(str, '/', '_');

field_names = strsplit(str,',');

data.p1 = array2table(data.p1,'VariableNames',field_names);
data.p2 = array2table(data.p2,'VariableNames',field_names);
data.p3 = array2table(data.p3,'VariableNames',field_names);
end

