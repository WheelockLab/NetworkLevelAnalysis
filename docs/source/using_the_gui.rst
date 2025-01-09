Using the GUI
==============================

Main Window
---------------------------

To start the GUI, navigate to the folder that contains the files and type ``NLA_GUI`` in the command section of the MATLAB window. 
Or, in the file browser section of the MATLAB window, right click on ``NLA_GUI.mlapp`` and select ``Run``.


1. Edge-level test dropdown selector
   See :doc:`Edge-level tests`
2. Edge-level test pane
    This pane will list all of the options and inputs needed for each test that's currently selected. 
    Usually there are selectors for functional connectivity, network atlas, and behavior files. There may also be other options depending on the test.
    If "Precalculated data" is selected, there will be selectors for data instead. (See: :ref:`Precalculated data loader <precalculated>`)
3. Behavior table
    This will display the table when the behavior file is loaded. The table is used to select the behvaior to test, co-variates used (optional), and 
    permutation groupings (optional).
4. Network-level test pane
    Selection of network-level test(s). One can be selected, or multiple with Ctrl/Shift + left click. 
    See :doc:`Network-level tests`
5. Run options
    Checkboxes to select test method(s). If within network pair is selected, full connectome will also be selected. 
    Permutation count is how many permutations to run. More permutations will take more time, but will produce more precise results.
    Run will run the edge level test and open the results window.

.. _loading_results
Loading Results
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
If previous data was saved (See :ref:`saving results <saving_results>`) there is an option to load it here. Click the ``File`` menu in the upper left-hand corner and select "Load Previous Results."
Depending on the size of the saved data, this could take a bit of time.

Results Window
----------------------------------

After ``Run`` is pressed in the main window, the results window will open. Initially, most of it bill be bank except for a ``View`` button to view the result
of the (non-permuted) edge-level test along with another ``Run`` button. Pressing this run button will begin running all the permutations of the edge-level and network-level test(s).

After all the permutations of the tests are run, the window will change and add options to view the network-level statistics. The statistics are in drop-down lists seperated by test
method. The list can be changed to group by test by pushing the ``Flip Nesting`` button.
On the right-hand side are a few options for displaying the statistics such as the p-value threshold, the Cohen's D threshold, and other options. There are two buttons to display the 
resultss.

1. Open TriMatrix Plot.
   This opens an interactive plot of the statistics. (See :ref:`TriMatrix Plot <trimatrix_plot>`)
2. Open Diagnostic Plots. 
   These three plots 

.. _saving_results
Saving Results
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To save results for use later (See :ref:`loading results <loading_results>`), click the ``File`` menu in the upper left-hand corner and select save. This may take a bit of time depending on how large the dataset is and how many permutations were run.
The results will be saved as 
    #. a ResultPool object using models and classes from the NLA codebase. This can only be used if the NLA is in MATLAB's current path.
    #. a nested structure of data that can be used without the NLA code. The structures are in the same ordering as the ResultPool, but there are no built-in classes and orderings.

.. _trimatrix_plot
TriMatrix Plot
---------------------------------

1. TriMatrix plot of p-values for selected test.
2. Options. After changing options, the ``Apply`` button must be pushed to take effect.
   There are also two buttons to display chord plots. One displays the network-level results, one displays the edge-level results. The options for these must be selected before the 
   chord plots are opened. The chord plots will not update after they are opened.