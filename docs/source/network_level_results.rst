Network-level Results
===================================
.. mat:module:: net.result

Overview
--------------------------------------

All network level tests use ``nla.net.result.NetworkTestResult`` as the result object. This object uses the properties of the test
to name the results. 

.. mat:autoclass:: NetworkTestResult

    .. mat:autoattribute:: test_name

    .. mat:autoattribute:: test_display_name

    .. mat:autoattribute:: test_options

    .. mat:autoattribute:: ranking_statistic

    .. mat:autoattribute:: within_network_pair

    .. mat:autoattribute:: full_connectome

    .. mat:autoattribute:: no-permutations

    .. mat:autoattribute:: permutation_results

    .. mat:automethod:: merge

    .. mat:automethod:: concatenateResult

    .. mat:automethod:: output

    .. mat:automethod:: createResultsStorage

    .. mat:automethod:: editableOptions

    .. mat:automethod:: getPValueNames

Calculating *p*-value
----------------------------------------------

*p*-values are calculated by calculating the cumulative distribution function (CDF) of a statistic,
or by extrapolating or interpolating values from a table of pre-calculated data. In our case,
we used the permutation results of our data as the CDF and then calculated the *p*-value from counting the 
number of points above or below (depending on the test used) the non-permuted (observed) value.

In NLA this is referred to as "ranking" since it is simply counting values in a sorted list. This basic
ranking is referred to as the "uncorrected" *p*-value. There are two other options for ranking in NLA. These
account for :abbr:`FWER (family-wise error rate)`. The first method is based off the "randomise" method :cite:p:`FreedmanD,WinklerA`.
This is referred to as the "Winkler method". The second method is called "Westfall-Young" in NLA described by
an alogrithm :cite:p:`WestfallP` by Westfall and Young.

Result Rank
---------------------------------------------
.. mat:module:: net

.. mat:autoclass:: ResultRank

    .. mat:autoattribute:: nonpermuted_network_results

    .. mat:autoattribute:: permuted_network_results

    .. mat:autoattribute:: number_of_network_pairs

    .. mat:automethod:: uncorrectedRank

    .. mat:automethod:: winklerMethodRank

    .. mat:automethod:: westfallYoungMethodRank


*p*-value for Each Test Based on Test Method
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. list-table::
    :header-rows: 1

    * - 
      - No Permutations
      - Full Connectome
      - Within Network Pair
    * - :math:`\chi` :sup:`2`
      - Two Sample
      - Two Sample
      - Two Sample
    * - Hypergeometric
      - Two Sample
      - Two Sample
      - Two Sample
    * - Kolmogorov-Smirnov
      - Single Sample
      - Two Sample
      - Single Sample
    * - Student's *t*-test
      - Single Sample
      - Two Sample
      - Single Sample
    * - Welch's *t*-test
      - Single Sample
      - Two Sample
      - Single Sample
    * - Wilcoxon
      - | Single Sample
        | (Signed-Rank)
      - | Two Sample
        | (Rank-Sum)
      - | Single Sample
        | (Signed-Rank)