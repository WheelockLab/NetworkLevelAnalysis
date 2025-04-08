Setup
====================

Download
--------------------------------

Download the NLA files from github to your computer. Note where it is located, this folder will be added to 
MATLAB's path in the next step.

Add NLA Folders to MATLAB Path
-------------------------------------

In order to for any NLA functions to work, MATLAB must be able to find them on the path. To do this, in
the MATLAB file explorer, navigate to where you have downloaded or cloned the NetworkLevelAnalysis
folder to. Right click the folder, hover over ``Add to Path`` in the context menu, and click the ``Selected
Folders and Subfolders`` option. 

:kbd:`Right click` then :menuselection:`Add to Path --> Selected Folders and Subfolders`

**NOTE**: If you only add the base 'NetworkLevelAnalysis' folder to the path the code will not work, you must
pick the ``Selected Folders and Subfolders`` option

Running the GUI
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To open the GUI, navigate to the root directory of the NetworkLevelAnalysis package in MATLAB and run
the command :command:`NLA_GUI` via the MATLAB command line.

**Note**: Running the GUI through an X11-based remote connection (eg: MobaXTerm or similar) can be very
laggy in some cases. It is strongly recommended to use the GUI through a more modern remote protocol
such as VNC instead.

Running as a Pipeline Script
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To run NLA via a script instead, open the file ``main_pipeline.m`` (located in the root directory of the
NetworkLevelAnalysis package) in MATLAB, and proceed through the stages of the pipeline. There is also
a pipeline for precalculated data located in ``precalculated_pipeline.m``

**Note**: The pipeline scripts are more complex and easy-to-mess-up than the GUI, and should only be used
if you have a good reason to do so.

Using Individual NLA Functions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To use NLA functions within your own code or scripts, add the ``NetworkLevelAnalysis`` folder to your
path. Most NLA functions are contained within the ``+nla`` namespace and its sub-namespaces. 
Functions and packages can also be imported. ``import nla.TestPool`` imports the ``TestPool`` allowing
the user to just type ``TestPool()`` to initialize it.