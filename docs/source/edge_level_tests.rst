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
:Functional Connectivity: Initial coorelation matrix (r-values or Fisher z-transformed r-values) of size N\ :sub:`ROIs`\  x  N\ :sub:`ROIs`\  x  N\ :sub:`scans`\
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
  Each column contains N\ :sub:`scans`\  entries.
  After loading this file, the table should display in the GUI.
  The user may mark one column as 'Behavior' for the score of interest.
  Other columns may be marked as 'Covariates' which are partialed prior to running statistics.

  **Note**: Network Level Analysis cannot handle missing values for behavior or covariates. If there are ``NaNs`` or missing values in a column, using this column will result in errors

Provided Tests
--------------------------------

* **Pearson's r**
  
  * MATLAB `corr <https://www.mathworks.com/help/stats/corr.html>_` function with ``type``, ``Pearson``
* **Spearman's** :math:`\rho`
  
  * MATLAB `corr <https://www.mathworks.com/help/stats/corr.html>_` function with ``type``, ``Spearman``
* **Spearman's** :math:`\rho` **estimator**
  
  * Faster approximation of the Spearman's rho function at the cost of slightly less accurate result.
  * Based on developer testing, rho values may differ by :math:`10^{-4}` and *p*-values by :math:`10^{-5}`.
  * This error is passed on to the network-level tests, and can cause *p*-value difference by :math:`10^{-4}` 
  * These differences were found with 10,000 permutations. Less permutations results in higher error in a less evenly distributed fashion. 
  * This is recommended for exploratory research with the Spearman's rho function for publications
* **Kendall's** :math:`\tau` **-b**

  * Implements Kendall's :math:`\tau` -b using C code in a MATLAB MEX file (``+mex/+src/kendallTauB.c``)
  * Faster implementation that stardard MATLAB code providing identical :math:`\tau` and *p*-values.
  * Run-time difference from *O*\ (*n*\ :sup:`2`) to *O*\ (*n* log *n*)
  * This is done with a red-black tree.
* **Welch's t-test**

  * Implements an optomized Welch's t-test comparing the functional connectivity of two groups.
  * Extra imports compared to other edge level tests

  :Group name(s): Names associated with each group. (For example, 'Male' and 'Female')
  :Group val(s): Behavioral value associated with each group. If 'Female' is donated as '0', and 'Male' as '1', set the vals to the numerical values.

.. _precalculated:

* **Pre-calculated data loader**

  * Allows loading of observed and permuted edge-level data the user has pre-calculated outside the NLA.
  * Four ``.mat`` files needed as inputs
  * *p*-values should be thresholded

  :Observed p: ``.mat`` file containing N\ :sub:`ROI_pairs`\ x 1 matrix of logical values, the observed, thresholded edge-level *p*-values.
    N\ :sub:`ROI_pairs`\ are the lower triangle values of a N\ :sub:`ROIs`\ x N\ :sub:`ROIs`\ matrix.
  :Observed coeff: ``.mat`` file containing N\ :sub:`ROI_pairs`\ x 1 matrix of observed edge-level coefficients.
  :Permuted p: ``.mat`` file containing N\ :sub:`ROI_pairs`\ x N\ :sub:`permutations`\ of logical values. Observed, thresholded, permuted *p*-values.
  :Permuted coeff: ``.mat`` file containing N\ :sub:`ROI_pairs`\ x N\ :sub:`permutations`\ of permuted edge-level coefficients.

Creating additional edge-level tests
-----------------------------------------------

To create an edge-level test, a test class must be added to the codebase. Refer to current tests in ``+nla/+edge/+test`` for examples. Guidelines are listed below

* **Test objects**
  
  All test objects must inherit from ``nla.edge.test.Base`` and be in the ``+nla/+edge/+test`` directory. There are also a few methods and
  properties that must be included

  * A constant property ``name`` is required.

  ::
    
    properties (Constant)
      name = "Pearson's r"
    end

  * A ``run`` method is also required.
  
  ::

    result = run(obj, input_struct)

  :input_struct: Also called ``test_options`` in the codebase. Parameters needed for a test. The functional connectivity, network atlas, and other properties are stored here.
  
.. _requiredInputs:
  
  * A ``requiredInputs`` method.
  
  ::

    methods (Static)
      function inputs = requiredInputs()
        inputs = {
          nla.inputField.Number('prob_max', 'P <', 0, 0.05, 1),
          nla.inputField.NetworkAtlas(),
          nla.inputField.Behavior()
        }
      end
    end
  
  This function creates 3 input fields in the GUI. A number ``prob_max`` with range [0, 1] and a default value of 0.05. 
  A network atlas file, and a behavior file. These are required, meaning that the GUI will not run without these inputs being
  fulfilled. These values are all stored in the ``input_struct`` object.

* **Result object**
  
  A result object must be defined for the test edge-level results. If no custom data fields are needed, then the object in ``+nla/+edge/+test/Base.m``
  may be used and this step can be skipped.

  * A ``output`` method must be included.
  
  ::

      function output(obj, network_atlas, flags)

  :network_atlas: An atlas of the form defined in ``nla.NetworkAtlas``
  :flags: Contains flags for the various types of figures to output. 
  
  * (Optional) A ``merge`` method to merge blocks of permutation results together. An example can be found in
    ``+nla/+edge/+result/PermBase.m`` file.
  
  ::

    merge(obj, results)

  :results: Cell array of result objects to merge. The object that calls the method will have the ``result`` merged with it.