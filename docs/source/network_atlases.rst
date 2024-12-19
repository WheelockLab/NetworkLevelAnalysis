Network Atlases
==================================
.. mat:module:: .

Overview
------------------------------------

A network atlas is a data file describing networks of the brain, each containing a number of related
regions of interest. It also contains metadata such as network colors and names, ROI spatial coordinates
(with associtated mesh/space), and optionally, a surface parcellation.

.. mat:autoclass:: NetworkAtlas
    
    .. mat:automethod:: numNets

    .. mat:automethod:: numNetPairs

    .. mat:automethod:: numROIs

    .. mat:automethod:: numROIPairs

Provided Network Atlases
--------------------------------

A number of network atlases are provided with the NLA software package in the ``support_files`` directory.
Only NLA-specific details will be provided about them, if you wish to go into more depth on a particular atlas
you should follow the link provided in its ``source`` field.

* ``Gordon_13nets_333parcels_on_MNI``
  * Surface space.
  * Consists of 333 parcels and corresponding 13 networks :cite:p:`GordonE`. Contains both the MNI centrois and surface parcels on a ``MNI_32k`` mesh.
* ``Gordon_12nets_286parcels_on_MNI``
  * Surface space
  * Same as ``Gordon_13nets_333parcels_on_MNI`` with 'None' network and its ROIs removed :cite:p:`GordonE`.
* ``Seitzman_17nets_300ROI_on_TT``
  * Volume space
  * 300 ROIs in 17 networks :cite:p:`SeitzmanB`. Contains TT centroids
* ``Seitzman_15nets_288ROI_on_TT``
  * Volume space
  * Same as ``Seitzman_17nets_300ROI_on_TT`` with 12 ROI and 2 networks removed due inconsistent placement in a network :cite:p:`SeitzmanB`.
