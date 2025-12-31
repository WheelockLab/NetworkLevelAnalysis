Methodology
================================

The Network Level Analysis (NLA) Method
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

First, connectome-wide associations are calculated between :abbr:`ROI (Region of Interest)`-pair connectivity and behavioral data,
resulting in a set of standardized regression coefficients that specify the brain-behavior association at
each ROI-pair of the connectome matrix. Next, network level analysis, consisting of a transformation of the
edge-level test statistics and enrichment statistic calculation :cite:p:`AckermanM`, is done to determine which networks are
strongly associated with the behavior of interest.

At the edge-level both *p*-value and test-statistic binarization are offered in the current NLA pipeline :cite:p:`EggebrechtA,WheelockM:2018`. Prior research has
supported the incorporation of a proportional edge density threshold, given that uneven edge density
thresholds have been shown to unfairly bias results :cite:p:`vandenHeuvelM`.
For enrichment statistic calculation, NLA offers a number of statistical tests (detailed below). Prior research has relied on
:math:`\chi^2` and Fisher's Exact tests. As well as a Kolmogorov-Smirnov (KS) test and non-parametric tests
based on ranks, which compare the distribution of test values within a region to other regions :cite:p:`WheelockM:2018,RudolphM,MoothaV,ZahnJ`. In
addition, KS alternatives such as averaging or min-max have also shown promise in connectome
applications :cite:p:`ChenJ,NewtonM,YaariG,EfronB`.

Permutation testing
""""""""""""""""""""""""""""""""""""""""""""""""""

Permutation testing can be used to provide approximate control of false positive results and allow wide variety of test statistics.
This is done under the assumption that the data are exchangeable under the null hypothesis - the joint distribution of the
error terms don't change with the permutation. 

NLA performs the permutation testing by shuffling the behavior vector labels and computing the selected statistic(s) many
times to produce a null distribution for each network. Family-wise error rate (FWER) can be corrected via Bonferroni, Benjamini-Yekutieli,
Benjamini-Hochberg, Westfall and Young :cite:p:`WestfallP`, and Freedman-Lane :cite:p:`WinklerA`. 

.. NLA then conducts data-driven permutation testing to establish significance. In the NLA toolbox, network
.. level significance is determined by comparing each measured enrichment statistic to permuted
.. enrichment *p*-values which are calculated by randomly shuffling behavior vector labels and computing
.. the enrichment statistic many times to produce a null distribution for each network. The FPR is controlled
.. at the network level using Bonferroni correction. Therefore, NLA is able to retain edge-level correlations
.. within each network module, but network communities are used to reduce the number of comparisons
.. and control the FPR at the network level. After significance is determined, the pipeline allows users to
.. create publication quality images to visualize network level findings both in connectome format and on
.. the surface of the brain.

.. note::
    While the behavior vector labels are shuffled to conduct permutations in the enrichment pipeline,
    functional connectivity data are not shuffled in order to preserve the inherent covariant structure of the
    data across permutations

Brain Network Map Selection
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

NLA requires the user to specify the network map that will be used to depict the known architecture of the
human connectome, which is crucial given that the network map selection affects both statistical
significance testing and interpretation :cite:p:`BellecP`. The current pipeline uses network maps that are generated with
`Infomap <https://www.mapequation.org/infomap/#Infomap>`_, due to its greater congruence with networks derived from task-activation and seed-based
connectivity studies than alternative modularity algorithms :cite:p:`PowerJ,RosvallM`. Network maps can be generated using
one's preferred algorithm or one of several published ROI and corresponding network map options that
will be included in the NLA toolbox :cite:p:`GordonE,PowerJ,ThomasY,GlasserM,ShenX,CraddockR`. The use of standardized ROI and network maps creates a
common, reproducible framework for testing brain-behavior associations across connectome research

Connectivity Matrices
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Other software packages are used to create the connectivity matrices that are provided as input into the
NLA toolbox. One useful option for mapping functional connectivity matrices is `CONN <https://web.conn-toolbox.org/>`_ - a MATLAB-based
software with the ability to compute, display, and analyze functional connectivity in fMRI.

Edge-level Statistical Model Selection
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

NLA requires the user to specify the desired statistical model for testing associations between
behavioral data and edge-level or ROI-pair connectivity connectome data. The analysis pipeline within
the NLA toolbox offers both parametric and non-parametric correlation.

.. list-table:: Edge-level Statistical Tests
    :header-rows: 1

    * - Test Name/Statistic
      - NLA Test Name
    * - Kendall Rank Correlation Coefficient
      - Kendall's tau-b
    * - Pearson Correlation Coefficient
      - Pearson's *r*
    * - Spearman Rank Correlation Coefficient
      - Spearman's rho
    * - Welch's *t*-test
      - Welch's *t*
    * - Paired Difference Test
      - Paired *t*   

Network-level Statistical Model Selection
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

NLA also allows the user to select one or more statistical models for testing associations between
behavioral data and network-level data.

.. list-table:: Network-level Statistical Tests
    :header-rows: 1

    * - Test Name/Statistic
      - NLA Test Name
      - Has Single Sample Test
      - Has Two Sample Test
    * - :math:`\chi^2`
      - Chi-Squared Test
      - No
      - Yes
    * - Hypergeometric
      - Hypergeometric Test
      - No
      - Yes
    * - Kolmogorov-Smirnov Test
      - Kolmogorov-Smirnov Test
      - Yes
      - Yes
    * - Student's *t*-test
      - Student's *t*-test
      - Yes
      - Yes
    * - Welch's *t*-test
      - Welch's *t*-test
      - Yes
      - Yes
    * - Wilcoxon Rank-Sum Test
      - Wilcoxon
      - No
      - Yes
    * - Wilcoxon Signed-Rank Test
      - Wilcoxon
      - Yes
      - No

Three different methods are available for network level testing. The first is referred to as "Full Connectome" testing.
Each network is compared against the entire connectome. The second is "Within Network Pair".
This is where network pairs are compared against permuted versions of themselves using single sample tests.
The third is "No Permutation" where network level statistics are exclusively calculated using single sample tests on non-permuted data. 
Two of the network-level test results are the same regardless of method: :math:`\chi^2` and Hypergeometric. This is because there are no single sample versions of these tests.

How Should the Test Statistic Threshold Be Chosen?
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

A nominal threshold is used for the thresholding and binarization step of the edge-level tests. The
nominal threshold is uncorrected and is typically set at 0.05 or 0.01 in the edge-level prob_max field. In
contrast, a network-level corrected threshold using the Bonferroni method can be applied to the network-level
statistics, where the nominal network-level threshold is divided by the number of tests being done to correct for
multiple comparisons.

How Should the Networks Be Chosen?
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

There are many canonical ROI sets and there are many network definitions. Some of these network
definitions include ROI that are not consistently assigned to any network. These ROI are typically removed
prior to network level analysis, as is the case in the ``Seitzman_15nets_288ROI_on_TT`` and the
``Gordon_12nets_286parcels_on_MNI`` network atlases included in this version of the toolbox. Network
atlases that are not included in this package may also be used, but they must first be formatted into the 
correct structure. Information on how to format a network atlas for use in the toolbox can be found in the :ref:`Network Atlas <network_atlases>` section.