Edge-level Statistical Tests
==========================================

Methods
-------------------------

The non-permuted method calculates the correlation of each Region Of Interest (ROI) to all other
ROIs via the given test. These results are stored as a correlation coefficient, ``coeff``, a p-value, ``prob``,
and a thresholded p-value, ``prob_sig``. The permuted method is identical except the variables have a ``_perm`` suffix.

Common Inputs
--------------------------

:P: Edge-level p-value threshold
:Network Atlas: :doc:`/network_atlases`
:Functional Connectivity: Initial coorelation matrix if size N\ :sub:`ROIs`\ x N\ :sub:`ROIs`\ x N\ :sub:`scans`\. 
  r-values or Fisher z-transformed r-values.
:Behavior: MATLAB table (``.mat``) or tab seperated text file (``.txt``)
  
  ============== =================== ================
  Variable Name  Next Variable Name  More Variable...
  ============== =================== ================
  1              5                   1.5
  0              1                   3
  1              7                   2.6
  ...            ...                 ...
  ============== =================== ================

  Each column header is a name of a variable.
  Each column contains N\ :sub:`scans`\ entries.
  After loading this file, the table should display in the GUI.
  The user may mark one column as 'Behavior' for the score of interest.
  Other columns may be marked as 'Covariates' which are partialed prior to running statistics.
  (Note: Network Level Analysis cannot handle missing values for behavior or covariates. If there are ``NaNs`` or missing values, do not select this columns)

Provided Tests
--------------------------------

* **Pearson's r**
  
  * MATLAB `corr <https://www.mathworks.com/help/stats/corr.html>` function with ``type``, ``Pearson``
* **Spearman's** :math:`\rho`\
  
  * MATLAB `corr <https://www.mathworks.com/help/stats/corr.html>` function with ``type``, ``Spearman``
* **Spearman's** :math:`\rho`\ **estimator**
  
  * Faster approximation of the Spearman's rho function at the cost of slightly less accurate result.
  * Based on developer testing, rho values may differ by :math:`10^{-4}` and p-values by :math:`10^{-5}`.
  * This error is passed on to the network-level tests, and can cause p-value difference by :math:`10^{-4}` 
  * These differences were found with 10,000 permutations. Less permutations results in higher error in a less evenly distributed fashion. 
  * This is recommended for exploratory research with the Spearman's rho function for publications
* **Kendall's** :math:`\tau`\ **-b**

  * Implements Kendall's :math:`\tau`\ -b using C code in a MATLAB MEX file (``+mex/+src/kendallTauB.c``)
  * Faster implementation that stardard MATLAB code providing identical :math:`\tau`\ and p-values.
  * Run-time difference from *O*\ (*n*\ :sup:`2`) to *O*\ (*n* log *n*)
  * This is done with a red-black tree.
* **Welch's t-test``

  * Implements an optomized Welch's t-test comparing the functional connectivity of two groups.
  * Extra imports compared to other edge level tests
  :Group name(s): Names associated with each group. (For example, 'Male' and 'Female')
  :Group val(s): Behavioral value associated with each group. If 'Female' is donated as '0', and 'Male' as '1', set the vals to the numerical values.

* **Pre-calculated data loader**

  * Allows loading of observed and permuted edge-level data the user has pre-calculated outside the NLA.
  * Four ``.mat`` files needed as inputs
  * p-values should be thresholded
  :Observed p: ``.mat`` file containing N\ :sub:`ROI_pairs`\ x 1 matrix of logical values, the observed, thresholded edge-level p-values.
    N\ :sub:`ROI_pairs`\ are the lower triangle values of a N\ :sub:`ROIs`\ x N\ :sub:`ROIs`\ matrix.
  :Observed coeff: ``.mat`` file containing N\ :sub:`ROI_pairs`\ x 1 matrix of observed edge-level coefficients.
  :Permuted p: ``.mat`` file containing N\ :sub:`ROI_pairs`\ x N\ :sub:`permutations`\ of logical values. Observed, thresholded, permuted p-values.
  :Permuted coeff: ``.mat`` file containing N\ :sub:`ROI_pairs`\ x N\ :sub:`permutations`\ of permuted edge-level coefficients.

Creating additional edge-level tests
-----------------------------------------------

Creating an edge-level test
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

1. All test objects must inherit from the ``nla.edge.test.Base`` class.
2. All test objects must be saved into the ``+nla/+edge/+test`` directory
3. There are a few required properties and methods that are required:
   
  * **name**
    * All tests must be given a name. Example::
  
      properties (Constant)
        name = "Kendall's tau"
      end

  * **result**
    * This is a method. The function handle is::

      function result = run(obj, test_options)

  * **test_options**
    * This is a structure with options that are used either in the test or visualizing results

  * **requiredInputs**
    * This is a static function to define the inputs for the test::
      
      methods (Static)
        function inputs = requiredInputs()
          inputs = {nla.inputField.Number('prob_max', 'P <', 0, 0.05, 1), nla.inputField.NetworkAtlas(), nla.inputField.Behavior()};
        end
      end

    * This defines a number field ``prob_max`` from [0, 1] with a default of 0.05. It also specifies a network atlas (:ref:`NetworkAtlas() <network_atlases>` input field, and a behavior input field.
    * These are all required. If the user does not supply them, the test not run in the GUI.
  
4. If the test is located in the correct folder, after a GUI restart (not MATLAB GUI) the test will populate in the Edge Level test list.

In addition to creating the test, a result object will also need to be created.

Creating a result
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

1. ``nla.edge.BaseResult`` will work if custom data fields are not required.
2. The result must inherit from ``nla.edge.BaseResult``
3. This result must be placed in ``+nla/+edge/+result/``
4. Methods and properties

  * **output**
    * This is the data that will be passed to create a figure of the data::

      function output(obj, network_atlas, flags)

    * Network atlas :ref:`NetworkAtas() <network_atlases>`
    * flags - a MATLAB structure that currently only has a field ``display_sig`` which is a boolean to determine if displayed p-values are thresholded
  
  * **merge**
    * This is an optional method
    * It is used to merge blocks of results together (like in a parallel processing environment)::

      function merge(obj, results)

    * The ``results`` argument is a result to merge the object with. Afterwards, the current object will be the two merged blocks