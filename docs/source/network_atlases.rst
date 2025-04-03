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

There are 41 network atlases included in NLA. These all follow a generic naming pattern:::

  <publisher>_<modifier (optional)>_<number of networks>_<ROIs/parcels>_on_<brain atlas>

  Brain Atlas is either Talairach (TT) or Montreal Neurological Institute (MNI)

.. list-table:: Provided Brain Atlases
  :header-rows: 1

  * - Name
    - Notes
  * - Glasser_12nets_360parcels_on_MNI
    - 
  * - Gordon_12nets_286parcels_LR_on_MNI
    -
  * - Gordon_12nets_286parcels_on_MNI
    -
  * - Gordon_13nets_333parcels_on_MNI
    - 
  * - GordonCort_SeitzmanSubcort_17nets_394ROI_on_MNI
    -
  * - Kardan_11nets_333parcels_on_MNI
    -
  * - Myers_24nets_283parcels_50pct_2023_on_MNI
    -
  * - Schaefer2018_7nets_100parcels_on_MNI
    -
  * - Schaefer2018_7nets_200parcels_on_MNI
    -
  * - Schaefer2018_7nets_300parcels_on_MNI 
    -
  * - Schaefer2018_7nets_400parcels_on_MNI 
    -
  * - Schaefer2018_7nets_500parcels_on_MNI
    -
  * - Schaefer2018_7nets_600parcels_on_MNI 
    -
  * - Schaefer2018_7nets_700parcels_on_MNI 
    -
  * - Schaefer2018_7nets_800parcels_on_MNI
    -
  * - Schaefer2018_7nets_900parcels_on_MNI 
    -
  * - Schaefer2018_7nets_1000parcels_on_MNI
    -
  * - Schaefer2018_17nets_100parcels_on_MNI
    -
  * - Schaefer2018_17nets_200parcels_on_MNI
    -
  * - Schaefer2018_17nets_300parcels_on_MNI 
    -
  * - Schaefer2018_17nets_400parcels_on_MNI 
    -
  * - Schaefer2018_17nets_500parcels_on_MNI
    -
  * - Schaefer2018_17nets_600parcels_on_MNI 
    -
  * - Schaefer2018_17nets_700parcels_on_MNI 
    -
  * - Schaefer2018_17nets_800parcels_on_MNI
    -
  * - Schaefer2018_17nets_900parcels_on_MNI 
    -
  * - Schaefer2018_17nets_1000parcels_on_MNI
    -
  * - Sietzman_2020_NeuroImage_17nets_300ROI_on_MNI
    -
  * - Sietzman_2020_NeuroImage_17nets_300ROI_on_TT
    -
  * - Wang_infant_group1_7nets_864parcels_on_MNI
    -
  * - Wang_infant_group2_9nets_864parcels_on_MNI
    -
  * - Wang_infant_group3_10nets_864parcels_on_MNI
    -
  * - Wang_infant_group4_10nets_864parcels_on_MNI
    -
  * - Wang_infant_group5_10nets_864parcels_on_MNI
    -
  * - Wang_infant_group6_10nets_864parcels_on_MNI 
    -
  * - Wheelock_2020_CerebralCortex_15nets_288ROI_on_MNI
    -
  * - Wheelock_2020_CerebralCortex_15nets_288ROI_on_TT
    -   
  * - Wheelock_2020_CerebralCortex_16nets_288ROI_on_MNI
    -
  * - Wheelock_2020_CerebralCortex_16nets_288ROI_on_TT
    -
  * - Wheelock_2020_CerebralCortex_17nets_288ROI_on_MNI
    -
  * - Wheelock_2020_CerebralCortex_17nets_288ROI_on_TT
    -    