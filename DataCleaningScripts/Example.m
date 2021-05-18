path = "example_input.csv";
data = Read_data(path);
data_cleaned = Clean_data(data);
data_smothed = Smoth_data(data_cleaned);
%sample_GPS gives gps sample points on I-270
sample_GPS = [39.077407	-77.168394
39.07775	-77.168674
39.078045	-77.168917
39.07836	-77.169179
39.078675	-77.169458
39.078934	-77.169666
39.079277	-77.169901
39.079592	-77.170126
39.079866	-77.170325
39.080195	-77.170541
39.080545	-77.170785
39.080846	-77.170992
39.081119	-77.171146
39.081334	-77.171272
39.081488	-77.171385
39.081638	-77.171475
];
%calculate GPS points
data_GPS = Calculate_GPS(data_smothed,sample_GPS(:,1), sample_GPS(:,2));
dlmwrite("example_output.csv", data_GPS, 'delimiter', ',', 'precision', 9);
