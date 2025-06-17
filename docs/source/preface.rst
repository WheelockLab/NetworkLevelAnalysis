Preface
==============

This is the reference manual for the Network Level Analysis (NLA) Toolbox. NLA is an extensible MATLAB-
based software package for the analysis of behavioral associations with brain connectivity data. NLA
utilizes a model-based statistical approach known variously as "pathway analysis", "over-representation
analysis", or "enrichment analysis", which was first used to describe behavioral or clinical associations in
genome-wide association studies :cite:p:`RivalsI,KhatriP,BackesC,SubramanianA`.

Enrichment is a model-based data reduction approach to elucidate statistically significant network-
features. The suite developed here includes data-driven permutation-based false-positive-rate
procedures that manage multiple comparisons corrections for one or two independent groups.

Hardware and Software Requirements
------------------------------------------
Matlab 2020b and later is recommended. Current release of the GUI is not supported for
Windows. The development team uses Ubuntu 20.04 with Matlab 2020b and has tested Matlab2024b with
Ubuntu 20.04 and MacOS

NLA requires the Parallel Processing and Statistics and Machine Learning Toolboxes. Best
performance will be achieved on a server setup with multiple cores to support parallel processing
(particularly for the permutation testing portion of the toolbox)