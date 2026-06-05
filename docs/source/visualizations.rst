Visualizations
==============================

.. _Edge_results:

Edge-level Results
---------------------------

Edge-level Results are visualized in color as correlation coefficients and nominally thresholded and binarized p-values in black and white.

.. figure:: _static/edge_results_plot.png

.. _Net_results: 

Network-level Results
---------------------------

Net-level results are visualized in a lower triangle matrix. (See :ref:`Lower Triangle Network-Level Results Window <net_level_results_window>`). Significant network pairs are marked with a black X.

.. figure:: _static/net_results_plot.png

.. _edge_chord: 

Edge-level Chord Plots
---------------------------

Edge-level chord plots show all edge-level results for significant network pairs after analysis. (See :ref:`Lower Triangle Network-Level Results Window <net_level_results_window>` for all plotting options).

.. figure:: _static/edge_chord_pval.png
    
    Type: p-value

.. figure:: _static/edge_chord_coeff.png
    
    Type: coefficient

.. figure:: _static/edge_chord_coeff_split.png
    
    Type: coefficient, split

.. figure:: _static/edge_chord_coeff_basic.png
    
    Type: coefficient, basic

.. figure:: _static/edge_chord_coeff_split_basic.png
    
    Type: coefficient, split + basic

.. _net_chord: 

Net-level Chord Plots
---------------------------

Net-level chord plots show all net-level results for significant network pairs after analysis.

.. figure:: _static/net_chord_plot.png

Convergence Map
---------------------------

Convergence maps show network pairs that are significant across multiple tests and/or methods. Select multiple tests in the results window (See :ref:`Results Window <results_window>`)" and then click the :guilabel:`View Convergence Map` button. 

.. figure:: _static/net_chord_plot.png

Network Pair Size Diagnostic Plots
---------------------------

Network pair size dianostic plots detail the effects of network pair size on results. The leftmost plot has non-permuted p-values on the x axis and permutation-based p-vaues on the y axis. The middle plot shows non-permuted p-values for all network pairs against network pair size, and the rightmost plot shows permuted p-values for all network pairs against network pair size.

.. figure:: _static/net_pair_size_diagnostic_plot.png