Network-level Statistical Tests
======================================

Methods
--------------------------

The non-permuted method measures how significant each network is compared to the entire connectome using
the given statistical test. The non-permuted method, like its name suggests, does not employ permutation testing. 
:math:`\chi^2`  and Hypergeometric tests are two sample and compare a network block against the rest of the connectome. 
Student's *t*-test, Welch's *t*-test, Wilcoxon Signed-Rank, and Kolmogorov-Smirnov tests are performed single-sample for each network pair using edge-level data.

The full connectome method ranks the non-permuted (observed) significance of each network against the
significance of the same network calculated over many permutations using the same test. The full connectome method compares edge-level statistics 
for a given network pair against edge-level statistics for the full connectome using two-sample tests. 
These two sample tests are performed both on non-permuted and on permuted edge-level data and then ranked to determine statistical significance. 
The Wilcoxon Rank-Sum test is used for two sample data instead of the Wilcoxon Signed-Rank test

The within network-pair method measures how significant each network is compared to all permutations of
only the selected network. The within-network pair method utilizes single sample tests to compare a non-permuted network pair of interest against permuted versions of itself. 
As :math:`\chi^2`  and Hypergeometric tests do not have a single sample form, they are computed identically to the non-permuted method. Student's *t*-test, Welch's *t*-test, 
Wilcoxon Signed-Rank test are performed on both the non-permuted and permuted data. Ranking for these tests is performed identically to the full connectome method

Common Inputs
------------------------

:P: Network-level *p*-value threshold
:Behavior Count: Number of different behavior vectors intended to test. *p*-values can be Bonferroni corrected by this number

Provided Tests
---------------------------

* **Hypergeomtric**

  * MATLAB's `hypercdf <https://www.mathworks.com/help/stats/hygecdf.html>`_ used to find the probablity

  *Inputs:*
    * :math:`O_i`: non-permuted, nominally thresholded, and binarized edge-level *p*-values for the network-pair of interest
    * :math:`\sum_{}O_i`
    * :math:`\textstyle E_i = \sum_{}\frac{\text{thresholded & binarized ROIs}}{\text{number of ROIs}} \scriptstyle * (\text{number of ROIs in the network-pair of interest})`
    * Number of ROI pairs across the full connectome
    * Number of ROI pairs within the network pair of interest
  
* **Chi-squred**

  * Runs a :math:`\chi^2`  test. 

  .. math:: 
    
    \chi^2 = \sum_{n=1}^n \frac{(O_i - E_i)^2}{E_i}
    
  ..
    
    * :math:`\textstyle E_i = \sum_{}\frac{\text{thresholded & binarized ROIs}}{\text{number of ROIs}} \scriptstyle * (\text{number of ROIs in the network-pair of interest})`
    * :math:`O_i`: non-permuted, nominally thresholded, and binarized edge-level *p*-values for the network-pair of interest

* **Kolmogorov-Smirnov**
  
  * MATLAB `kstest2 <https://www.mathworks.com/help/stats/kstest2.html>`_ function.
  
  *Inputs:*
    * Edge-level correlation coefficients for the network-pair of interest
    * Edge-level correlation coefficients across the full connectome
      
      * **Note**: This input is not used for single-sample tests

* **Wilcoxon rank-sum test**
  
  * MATLAB `ranksum <https://www.mathworks.com/help/stats/ranksum.html>`_ function.

  *Inputs:*
    * Edge-level correlation coefficients for the network-pair of interest
    * Edge-level correlation coefficients across the full connectome
      
  * **Note**: This test is only run as a two-sample test.
  
* **Wilcoxon signed-rank test**

  * MATLAB's `ranksum <https://www.mathworks.com/help/stats/ranksum.html>`_ function

  *Inputs:*
    * Edge-level correlation coefficients for the network-pair of interest
      
  * **Note**: This test is only run as a single-sample test.
  
* **Welch's** *t* **-test**
  
  * Implements an optimized Welch's *t*-test to compare the mean differences of two groups.

  *Inputs:*
    * Edge-level correlation coefficients for the network-pair of interest
    * Edge-level correlation coefficients across the full connectome
      
      * **Note**: This input is not used for single-sample tests

* **Student's** *t* **-test**
  
  * MATLAB `ttest2 <https://www.mathworks.com/help/stats/ttest2.html>`_ function.

  *Inputs:*
    * Edge-level correlation coefficients for the network-pair of interest
    * Edge-level correlation coefficients across the full connectome
      
      * **Note**: This input is not used for single-sample tests

Creating additional network-level tests
-----------------------------------------------------

To create a network-level test, a test class must be added to the codebase. Refer to the current tests in ``+nla/+net/+test``

* **Test objects**
  
  All test objects must inherit from ``nla.net.test.Base`` and be in the ``+nla/+net/+test`` directory. There are also properties and methods
  that must be included.

  * Constant properties required
    ::
    
      properties (Constant)
        name = "students_t"
        display_name = "Student's T-test"
        statistics = ["t_statistic", "single_sample_t_statistic"]
        ranking_statistic = "t_statistic"
      end

  
  :name: The name of the test with no special characters (spaces, &, etc)
  :display_name: A formal name that will be used for displaying in the GUI. Any string will work
  :statistics: All statistics that will be generated by the test. No special characters
  :ranking_statistic: The statistic used for ranking and calculating *p*-values. Note: if there is a single sample version of the statisticin addition to a two sample statistic, the GUI will automatically add "single_sample\_" during rankings for non-permuted and within network pair ranking.

  * A ``run`` method
  
    ::

      result = run(obj, test_options, edge_test_results, network_atlas, permutations)


  :test_options: Also called ``input_struct`` in edge-level tests. Parameters needed to run the test.
  :edge_test_results: The output from the edge-level test.
  :network_atlas: A network atlas of the form ``nla.NetworkAtlas``
  :permutations: Boolean to determine if the test is being run with permutations (``true``) or without (``false``)

  * ``requiredInputs`` See :ref:`Edge-level tests <requiredInputs>`
