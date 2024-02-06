
The data in this folder were created via simulation using the Seitzman 15 network, 288 ROI parcellation. 
	1. SIM_obs_coeff.mat contains Pearson correlation coefficients for the observed data
	2. SIM_obs_p.mat contains the associated Pearson correlation p-values binarized and thresholded at 0.05 for the observed data
	3. SIM_perm_coeff.mat contains Pearson correlation coefficients for the permuted data
	4. SIM_perm_p.mat contains the associated Pearson correlation p-values binarized and thresholded at 0.05 for the permuted data

The observed data have a set of true (significant) network pairs where the mean rho value has been set to 0.13. 
Background network pairs have a mean of 0, and standard deviation of 0.146. 
Observed data has the shape of Nroi_in_lowerTriangle x 1

Permuted data only includes 600 permutations to account for github's file size requirements
Permuted data has the shape of: Nroi_in_lowerTriangle x Npermutations

