Methodology
================================

Brain Network Map Selection
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

NLA requires the user to specify the network map that will be used to depict the known architecture of the
human connectome, which is crucial given that the network map selection affects both statistical
significance testing and interpretation :cite:p:`BellecP`. The current pipeline uses network maps that are generated with
Infomap, due to its greater congruence with networks derived from task-activation and seed-based
connectivity studies than alternative modularity algorithms :cite:p:`PowerJ,RosvallM`. Network maps can be generated using
one's preferred algorithm or one of several published ROI and corresponding network map options that
will be included in the NLA toolbox :cite:p:`GordonE,PowerJ,ThomasY,GlasserM,ShenX,CraddockR`. The use of standardized ROI and network maps creates a
common, reproducible framework for testing brain-behavior associations across connectome research

General Linear Model / Edge-wise Statistical Model Selection
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

NLA also requires the user to specify the desired statistical model for testing associations between
behavioral data and edge-wise�or ROI-pair connectivity�connectome data. The analysis pipeline within
the NLA toolbox offers both parametric and non-parametric correlation.

Connectivity Matrices
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Other software packages are used to create the connectivity matrices that are provided as input into the
NLA toolbox. One useful option for mapping functional connectivity matrices is CONN - MATLAB-based
software with the ability to compute, display, and analyze functional connectivity in fMRI.

The NLA Method
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

First, connectome-wide associations are calculated between ROI-pair connectivity and behavioral data,
resulting in a set of standardized regression coefficients that specify the brain-behavior association at
each ROI-pair of the connectome matrix. Next, network level analysis-consisting of transformation of the
edge-wise test statistics and enrichment statistic calculation :cite:p:`AckermanM` - is done to determine which networks are
strongly associated with the behavior of interest.

Both p-value and test-statistic binarization are offered in the current NLA pipeline :cite:p:`EggebrechtA,WheelockM:2018`. Prior research has
supported the incorporation of a proportional edge density threshold, given that uneven edge density
thresholds have been shown to unfairly bias results :cite:p:`vandenHeuvelM`.
For enrichment statistic calculation, NLA offers a number of statistical tests. Prior research has relied on
chi-square and Fisher's Exact test, as well as a Kolmogorov-Smirnov (KS) test and non-parametric tests
based on ranks, which compare the distribution of test values within a region to other regions :cite:p:`WheelockM:2018,RudolphM,MoothaV,ZahnJ`. In
addition, KS alternatives such as averaging or minmax have also shown promise in connectome
applications :cite:p:`ChenJ,NewtonM,YaariG,EfronB`.

NLA then conducts data-driven permutation testing to establish significance. In the NLA toolbox, network
level significance is determined by comparing each measured enrichment statistic to permuted
enrichment p-values which are calculated by randomly shuffling behavior vector labels and computing
the enrichment statistic many times to produce a null distribution for each network. The FPR is controlled
at the network level using Bonferroni correction. Therefore, NLA is able to retain edge-wise correlations
within each network module, but network communities are used to reduce the number of comparisons
and control the FPR at the network level. After significance is determined, the pipeline allows users to
create publication quality images to visualize network level findings both in connectome format and on
the surface of the brain.

**Note**: While the behavior vector labels are shuffled to conduct permutations in the enrichment pipeline,
functional connectivity data are not shuffled in order to preserve the inherent covariant structure of the
data across permutations

How Should the Test Statistic Threshold Be Chosen?
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

A nominal threshold is used for the thresholding and binarization step of the edge-level tests. The
nominal threshold is uncorrected and is typically set at 0.05 or 0.01 in the edge-level prob_max field. In
contrast, a network-level corrected threshold using the Bonferroni method is used in the net-level
statistics, where the nominal threshold is divided by the number of tests being done to correct for
multiple comparisons.

How Should the Networks Be Chosen?
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

There are many canonical ROI sets and there are many network definitions. Some of these network
definitions include ROI that are not consistently assigned to any network. These ROI are typically removed
prior to network level analysis, as is the case in the ``Seitzman_15nets_288ROI_on_TT`` and the
``Gordon_12nets_286parcels_on_MNI`` network atlases included in this version of the toolbox. Network
atlases that are not included in this package may also be used, but they must first be formatted into the 
correct structure