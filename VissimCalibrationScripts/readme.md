The codes should be run in the following order:

-	“s1_WGS_to_cartesian” to convert the gps coordinates of the field trajectory data into the Vissim one.
-	 “s2_main_data_save” to read, reformat, and save the field trajectory data.
-	“s3_benchmark” and “s3_enumerate” to enumerate different combinations of the model parameters and run simulations for each of them.
-	“s4_MOE_eval” to run the post-processing MOE evaluations.
-	“s5_analysis”, “s5_get_rmse_macro”, “s5_std_rmse_macro” are the codes to analyze the MOE results.

Other files in the main folder are some functions that are being called in the main codes mentioned above.

Some scripts in the “other codes” folder were used for miscellaneous purposes such as:
-	Getting the bin distributions according to the field trajectory data
-	Finding the best optimal model parameters using 100% of the trajectory data
-	Getting the time headway distribution from the field trajectory data
-	Reading the macroscopic measures from the csv files, 
-	Plotting macro validation 


