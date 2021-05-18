# trajectoryinvestigation
This repository contains scripts for cleaning trajectory data and traffic simulation models developed as part of the FHWA Trajectory Investigation project. 
Scripts for Cleaning Trajectory Data:
To use the scripts to clean your datasets and calculate GPS locations of trajectories.
Functions include Read_data(read a dataset), Clean_data(clean the uploaded dataset), Smoth_data (smooth
trajectories), Calculate_GPS(calculate GPS locations of trajectories) and write results to a csv file.

make sure the first point in sample_GPS is consistent with local location
%(0,0) in the dataset.

1. make sure the format of your datasets are the same with example_input.csv;
2. put your datasets to the same folder with the scripts and change path = "example_input.csv" in Example.m to your datasets' name;
3. collect sample GPS points of your datasets and enter the GPS points to variable sample_GPS in Example.m;
4. then you can run the script, the results will be instored in "example_output.csv".




