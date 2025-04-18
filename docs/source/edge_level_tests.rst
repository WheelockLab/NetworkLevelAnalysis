Edge-level Statistical Tests
==========================================

Methods
-------------------------

The non-permuted method calculates the correlation of each Region Of Interest (ROI) to all other
ROIs via the given test. These results are stored as a correlation coefficient, ``coeff``, a *p*-value, ``prob``,
and a thresholded *p*-value, ``prob_sig``. The permuted method is identical except the variables have a ``_perm`` suffix.

Common Inputs
--------------------------

:P: Edge-level *p*-value threshold
:Network Atlas: :doc:`Network Atlas </network_atlases>`
:Functional Connectivity: Initial correlation matrix (r-values or Fisher z-transformed r-values) of size N\ :sub:`ROIs`\  x  N\ :sub:`ROIs`\  x  N\ :sub:`scans`\
:Behavior: MATLAB table (``.mat``) or tab separated text file (``.txt``)
  
  ============== =================== ================
  Variable Name  Next Variable Name  More Variable...
  ============== =================== ================
  1              5                   1.5
  0              1                   3
  1              7                   2.6
  ...            ...                 ...
  ============== =================== ================

  Each column header is a name of a variable.
  Each column contains N\ :sub:`scans`\  entries.
  After loading this file, the table should display in the GUI.
  The user may mark one column as 'Behavior' for the score of interest.
  Other columns may be marked as 'Covariates' which are `partialed <https://en.wikipedia.org/wiki/Partial_correlation>`_ prior to running statistics.

  **Note**: Network Level Analysis cannot handle missing values for behavior or covariates. If there are ``NaNs`` or missing values in a column, using this column will result in errors

Provided Tests
--------------------------------

* **Pearson's** *r*
  
  * MATLAB `corr <https://www.mathworks.com/help/stats/corr.html>`_ function with (``type``, ``Pearson``)
* **Spearman's** :math:`\rho`
  
  * MATLAB `corr <https://www.mathworks.com/help/stats/corr.html>`_ function with (``type``, ``Spearman``)
* **Spearman's** :math:`\rho`  **estimator**
  
  * Faster approximation of the Spearman's rho function at the cost of slightly less accurate result.
  * Based on developer testing, rho values may differ by :math:`10^{-4}` and *p*-values by :math:`10^{-5}`.
  * This error is passed on to the network-level tests, and can cause *p*-value difference by :math:`10^{-4}` 
  * These differences were found with 10,000 permutations. Less permutations results in higher error in a less evenly distributed fashion. 
  * This is recommended for exploratory research with the Spearman's rho function for publications
* **Kendall's** :math:`tau` **-b**

  * Implements Kendall's :math:`\tau` -b using C code in a MATLAB MEX file (``+mex/+src/kendallTauB.c``)
  * Faster implementation that standard MATLAB code providing identical :math:`\tau` and *p*-values.
  * Run-time difference from *O*\ (*n*\ :sup:`2`) to *O*\ (*n* log *n*)
  * This is done with a red-black tree.
* **Welch's** *t* **-test**

  * Implements an optimized Welch's *t*-test comparing the functional connectivity of two groups.
  * :abbr:`FC (Functional Connectivity)` for both groups must be concatenated along the 3rd dimension (N\ :sub:`scans`\). As such, the third dimension will be N\ :sub:`scans`\  x 2
  * Behavior must contain Group IDs for both groups. The simplest way to do this is by creating a column vector containing 0's for subjects in Group 1 and 1's for subjects in Group 2.
  * We also recommend using that same column for setting the Permutation Groups as described in (link to �Setting Permutation Groups� here).

  :Group name(s): Names associated with each group. (For example, 'Male' and 'Female')
  :Group val(s): Behavioral value associated with each group. If 'Female' is denoted as '0', and 'Male' as '1', set the vals to the numerical values.

* **Paired** *t* **-test**
  
  * MATLAB `ttest <https://www.mathworks.com/help/stats/ttest.html>`_ function with (``Dim``, ``2``)
  * Otherwise implemented the same way as the Welch's *t*-test above

.. _precalculated:

* **Pre-calculated data loader**

  * Allows loading of observed and permuted edge-level data the user has pre-calculated outside the NLA.
  * Four ``.mat`` files needed as inputs
  * *p*-values should be thresholded

  :Observed p: ``.mat`` file containing N\ :sub:`ROI_pairs`\  x 1 matrix of logical values, the observed, thresholded edge-level *p*-values.
    N\ :sub:`ROI_pairs`\  are the lower triangle values of a N\ :sub:`ROIs`\  x N\ :sub:`ROIs`\  matrix.
  :Observed coeff: ``.mat`` file containing N\ :sub:`ROI_pairs`\  x 1 matrix of observed edge-level coefficients.
  :Permuted p: ``.mat`` file containing N\ :sub:`ROI_pairs`\  x N\ :sub:`permutations`\  of logical values. Observed, thresholded, permuted *p*-values.
  :Permuted coeff: ``.mat`` file containing N\ :sub:`ROI_pairs`\  x N\ :sub:`permutations`\  of permuted edge-level coefficients.

