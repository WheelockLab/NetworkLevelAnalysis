.. Network Level Analysis Overview
.. ====================================

.. The connectome and network structure
.. -------------------------------------------

.. The term connectome essentially describes any network description of whole brain connectivity, from the
.. microscale of single neurons and synapses up to the macroscale of entire brain regions and pathways 
.. :cite:p:`SpornsO`. Connectomics is an ever-advancing field, and large-scale scientific endeavors such as the NIH's Human
.. Connectome Project have made significant progress in mapping, analyzing, and understanding the
.. human connectome. Contemporary connectome research views the brain as an extensive, complex
.. network of non-adjacent, yet functionally and structurally connected brain regions :cite:p:`GordonE,PowerJ`. The connectome
.. can be utilized to assess whole-brain associations between behavior and spatially distinct neural
.. networks.

.. MRI has traditionally been viewed as the gold standard for mapping the connectome and has been used
.. to demonstrate consistencies between the spatial topology of task-based activation studies and the brain
.. networks derived from task-free functional connectivity :cite:p:`PowerJ,GrattonC`. Contemporary cluster correction approaches
.. do not utilize the spatial topology of brain networks when estimating cluster size significance :cite:p:`FormanS,FristonK,VieiraS`.
.. Therefore, there is an urgent need for standardized tools that address the robust hierarchical network
.. structure of the brain and the limitations of contemporary neuroimaging analysis approaches by utilizing
.. this biologically informed network structure to increase reproducibility and biological interpretation of
.. neuroscience results

.. Why use this toolbox?
.. ----------------------------------------

.. The NLA toolbox is designed to address the multiple comparisons problem that occurs within
.. connectome research, wherein studies use hundreds of regions of interest (ROI) to create connectomes
.. with thousands of potential connections, yet they lack the tools to establish statistical significance when
.. analyzing associations between connectome and behavior. For example, previous research failed to find
.. any significant differences in brain connectivity that passed a connectome-wise false discovery rate (FDR)
.. correction between individuals with a neurological disorder and healthy controls - a finding which
.. contradicts the recognized role of the brain in neurological functioning :cite:p:`GreeneD`. Other studies have found
.. connectome-behavior associations that pass the FDR correction, but lack the statistical tools necessary to
.. definitively establish these observations :cite:p:`ShirerW`. NLA, therefore, serves as a valuable tool for the statistical
.. quantification of network-level associations with behavior. The toolbox relies on cross-disciplinary
.. biostatistical approaches to evaluate brain-behavior relationships within the connectome and allows for
.. control of FDR at the network level. In this way, NLA diverges from most contemporary tools with a focus
.. on single connection associations, in that it is not dependent on edgewise false positive rate (FPR) or
.. spatially contiguous brain regions. By organizing connectivity-behavior associations according to an a-
.. priori model of underlying neurobiology (i.e., networks), NLA leverages the structure of the human
.. connectome and provides a framework for rational interpretation and replication of findings across
.. research methodologies. Finally, the integration of connectome analysis and visualization techniques
.. within a single, extensible MATLAB-based pipeline makes NLA an expedient tool for statistical testing and
.. production of publication quality images all in one package.

.. Introduction to NLA and enrichment
.. ---------------------------------------------

.. Network Level Analysis uses enrichment to evaluate whether pairs of networks demonstrate significant
.. clustering of strong brain-behavior correlations. Enrichment applies common statistical tests to measure
.. the clustering of associations within a given network pair and reduces the number of comparisons to
.. those performed at the network level :cite:p:`SubramanianA`. Network level statistics such as the Chi-Square test,
.. Hypergeometric test, and Kolmogorov-Smirnov test have been used in numerous network-level
.. investigations including joint attention and motor function in infants and toddlers, maternal
.. inflammation during gestation, motor and attention development in very preterm children, sex
.. differences during fetal brain development, and autism in adults :cite:p:`EggebrechtA,WheelockM:2018,WheelockM:2019,RudolphM,WheelockM:2021,MaronKatz,MarrusN,FeczkoE`.

.. Edge-level Statistic
.. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. First, correlations are calculated between behavioral scores and Fisher Z-transformed functional
.. connectivity correlation measures for each pair of ROI. For behavioral scores that are normally
.. distributed, Pearson correlations are used to calculate the associations. Non-parametric Spearman rank
.. correlations are used to assess the relationship between functional connectivity and behavioral scores
.. that are not normally distributed. Other tests of correlation such as Kendall's Tau and 2-sample Welch's *t*
.. can also be used. Network pairs are then tested for enrichment of strong correlation values, defined as
.. only those values that remain after being nominally thresholded. An uncorrected *p*-threshold (e.g. 0.05 or
.. 0.01) is applied and the remaining correlations are binarized.

.. Network Level Statistics
.. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. After the edge-level statistic matrix has been calculated, it is given as input to a variety of network-level
.. tests. First, it is input directly to the tests, and the resulting statistic is called the "non-permuted network
.. level statistic" (for every given network-level test). Then, permuted edge-level statistics are calculated via
.. the same method as described in the previous section, but with the behavioral scores permuted across subjects. The
.. network-level test is performed with the permuted behavioral scores, also. The significance of permuted network-level statistics
.. ranked against the non-permuted, to calculate the permuted experiment-wide *p*-value (an empirical *p*-
.. value produced from this ranking). Additionally, "single-sample within-net-pair" statistics are calculated
.. for each test, which, rather than comparing a given network to the connectome over a number of
.. permutations (as in the permuted network-level test), performs a single-sample test on the network
.. alone, which is then ranked against permutations of said network similarly to the permuted network-level
.. test.
.. A number of statistic tests are utilized at the network level. 
..   #. The 1-degree-of-freedom :math:`\chi^{2}` test is used to
..     compare the observed number of strong (thresholded and binarized) brain-behavior correlations within
..     one pair of functional networks to the number of strong brain-behavior correlations that would be
..     expected if strong correlations were uniformly distributed across all possible network pairs. A large
..     resulting test statistic can indicate that the number of strong correlations within a specific network pair is
..     enriched. 
..   #. The hypergeometric test aims to assess the likelihood of observing a given number of strong
..     correlations within a pair of networks, given: 
..       #. The total number of strong correlations observed over the
..       entire connectome
..       #. The total number of possible hits for that network pair (i.e., the total number or
..       ROI-pairs within a given network pair). 
..   #. Other tests such as Kolmogorov-Smirnov, Wilcoxon rank-sum,
..     Welch's *t* can be used, as well as Cohen's *d* to measure effect sizes.
.. As described, significance for all statistical tests is determined using permutation testing. Behavioral
.. labels are randomly permuted and correlated with the connectome data (typically 10k times) to create
.. null brain-behavior correlation matrices. Tests are calculated on these permuted brain-behavior
.. correlation matrices generating a null distribution of network level statistics. The measured (real) test
.. statistics are compared to this null distribution to establish network-level significance.

.. NLA Alternatives / Comparison to other analysis methods
.. ----------------------------------------------------------------------

.. The NLA toolbox's use of a novel enrichment approach makes it a transformative tool in connectome-
.. wide association studies, given that all current enrichment analysis methods are built for use with
.. genome data and NLA is the first enrichment tool designed to analyze the connectome. Many alternative
.. methods for connectome analysis rely on spatial extent cluster correction in order to control voxel-wise
.. whole brain connectome FPR :cite:p:`ShehzadZ,SharmaA`. Despite mounting evidence that spatially non-contiguous brain regions
.. are strongly correlated and often co-activate to the same stimuli, cluster extent correction is often
.. regarded as the ideal thresholding approach in human connectome literature. By basing statistical
.. significance on contiguous voxels, however, cluster extent correction methods fail to account for this
.. covariance structure. Therefore, brain regions that are known to be highly correlated and part of the same
.. network - such as the anterior cingulate and posterior cingulate - may be thresholded separately,
.. resulting in one or both separate regions not meeting statistical thresholds :cite:p:`RaichleM`. NLA is distinguished from
.. the cluster extent correction methodology in that it groups highly correlated, non-contiguous brain
.. regions based on pre-defined network modules prior to estimating network-level significance.

.. Network Based Statistic (NBS)
.. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. Given this deviation from the popular extent cluster correction thresholding method, the most
.. conceptually similar existing connectome analysis approach to NLA is the Network Based Statistic (NBS)
.. toolbox :cite:p:`ZaleskyA`. NBS was the first tool control the edgewise FPR by leveraging graph-based estimates of
.. modularity. Still, several crucial differences exist between NLA and NBS: (a) the results from NBS focus on
.. edgewise significance as opposed to network-level significance, (b) NBS does not have a built-in
.. visualization functionality, and (c) NBS allows for different module sizes, number of network modules,
.. and configurations of edges assigned to network modules across various clinical populations, but draws
.. no conclusions regarding the biological relevance of identified networks. The NLA pipeline addresses this
.. issue by presenting a vast array of analysis and visualization options that utilize biologically informed
.. hierarchical organization models of the brain.

.. Graph Theoretical Toolboxes
.. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. Graph Theoretical Toolboxes are another comparable approach to NLA, offering an analysis methodology
.. to quantify network characteristics such as integration, segregation, resilience, and relative contribution
.. of individual network nodes to overall information flow within the network :cite:p:`RubinovM`. Various other toolboxes
.. have been created to address network thresholding, graph metric calculation, and graph visualization -
.. such as GRETNA, GEPHI, and BrainNet Viewer. Additional methodologies aim to determine network
.. topology differences by leveraging generalized estimating equations and generalized linear and nonlinear
.. mixed models :cite:p:`BahramiM,GinestetC,SimpsonS`. Each of these tools has helped to advance the application of graph theory approaches
.. to connectome analysis. The NLA toolbox estimates statistical associations edgewise, rather than on
.. network topology features, thereby providing a crucial and complementary approach to the existing
.. collection of brain network analysis tools

.. Statistical Inference and the use of liberal primary thresholds
.. ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. NLA establishes statistical significance in the weak sense similar to traditional voxelwise cluster-level
.. inference :cite:p:`NicholsT`. In voxelwise cluster correction, a liberal primary threshold is employed in addition to a
.. cluster-extent threshold (determined by e.g., random field theory or Monte Carlo simulations). The
.. resulting clusters are significant but inferences cannot be made about any particular sub-regions or
.. voxels within a cluster. Similarly, NLA employs a liberal primary threshold in order to calculate the
.. network-level statistic and significance is established with permutation testing, but claims cannot be
.. made about the significance of any given ROI-pair within the network. One could apply an FDR correction
.. within each network pair similar to the statistics outlined in the Network Based Statistics toolbox though
.. this would still only control the false positive rate in the weak sense. The motivation of all of these
.. approaches (cluster-level inference, network-level enrichment, network-based statistic) is to control the
.. false positive rate when a massive number of tests are performed. Controlling the false positive rate in the
.. strong sense with several thousand functional connections (e.g., 30k) will often result in no single ROI-pair
.. surviving OR a few scattered ROI-pairs surviving with no clear biological pattern :cite:p:`GreeneD`.