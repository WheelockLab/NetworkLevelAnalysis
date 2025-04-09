Getting Started
================================================

Running with example data
--------------------------------------------------

1. First, open the NLA software (as described in :doc:`setup`). Select ``Pearson's r`` as the edge-level
   test from the edge-level test dropdown.

2. Click :guilabel:`Select` to choose a network atlas, navigating to the ``support_files`` folder withing your
   NetworkLevelAnalysis installation and selecting ``Wheelock_2020_CerebralCortex_15nets_288ROI_on_MNI.mat``.
   This file is used to parcellate the data. 

   :menuselection:`Network Atlas Select Button --> support files --> Wheelock_2020_CerebralCortex_15nets_288ROI_on_MNI.mat`

3. Then, select the functional connectivity, located in the ``examples/fc_and_behavior`` folder under the name
   ``sample_func_conn.mat``. Click 'Yes' to Fisher z-transform the data. Take a moment to visualize the functional
   connectivity (FC) average by clicking :guilabel:`View`. Note that the FC appears to match the parcellation, (effects
   generally line up with network boundaries) - this can be a useful diagnostic tool if you are having issues
   with parcellations not matching data. 

   :menuselection:`Functional Connectivity Select Button --> examples --> fc_and_behavior --> sample_func_conn.mat`

4. Finally, load the behavior ``sample_behavior.mat`` from the ``examples/fc_and_behavior`` folder (The 'file type' drop-down
   will need to be changed from ``Text`` to ``MATLAB table`` in the file browser). Set the behavioral variable to 'Flanker_AgeAdj' by
   clicking on that column in the table and then the :guilabel:`Set Behavior` button.

   :menuselection:`Behavior Select Button --> examples --> fc_and_behavior --> sample_behavior.mat`

5. Having finished our edge-level inputs, we now move over to the network-level panel on the right side. Select all the tests by left clicking
   the top one, and then :kbd:`shift + clicking` the bottom one.

.. _running_network_tests:

Run the tests using the :guilabel:`Run` button on the bottom-right. The number of permutations can be changed with the input field
to the left of the :guilabel:`Run` button. After pushing the :guilabel:`Run` button, a result window will open. The edge-level test will run 
and the results can be visualized by pressing :guilabel:`View` in the upper-left of the result window. To run the network-level tests, 
push the :guilabel:`Run` button in the results window. This will take longer and a progress window will show up displaying the progress.
To visualize the results, expand the lists in the reloaded (automatically) panel, and highlight a test. Multiple tests can be selected by :kbd:`left-clicking` the first and then :kbd:`left-click + Shift` the last.
Press the :guilabel:`View figures` button. Other visualization options, such as chord plots and convergence maps, can also be shown by selecting those options from the figure GUI. 
The results can be saved using the :guilabel:`File` menu in the top-left of the figure GUI. These results can be loaded into MATLAB as a variable, or opened in the NLA GUI using the :guilabel:`File` menu on the mainwindow. 

Running with example pre-calculated data
----------------------------------------------------------

Similarly to the previous example, open the NLA window and load the ``Wheelock_2020_CerebralCortex_15nets_288ROI_on_MNI.mat`` parcellation. This
time, select the :guilabel:`Precalculated data` edge-level test. Load the four input matrices in the ``examples/precalculated`` folder.

* Observed coefficients: ``SIM_obs_coeff.mat``
* Observed, thresholded p-values: ``SIM_obs_p.mat``
* Permuted coefficients: ``SIM_perm_coeff.mat``
* Permuted, thresholded p-values: ``SIM_perm_p.mat``

Set the lower and upper coefficient bounds to the range of the coefficients. For this case, the range is [-2, 2]. These bounds can be checked
with the :guilabel:`View` button for the edge-level results button. In the bottom right corner, set the ``perm_count`` to the desired number of 
permutations. The example data provided has a maximum of 600 permutations. Run the tests using the procedure described in the 
:ref:`previous section <running_network_tests>`. 