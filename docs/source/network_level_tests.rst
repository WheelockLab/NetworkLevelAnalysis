Network-level Statistical Tests
======================================

Methods
--------------------------

The non-permuted method measures how significant each network is compared to the entire connectome using
the given statistical test.

The full connectome method ranks the non-permuted (observed) significance of each network against the
significance of the same network calculated over many permutations using the same test.
I DON"T KNOW HOW TO EXPLAIN THE PROBABILITY BEING CALCULATED - Jim

The within network-pair method measures how significant each network is compared to all permutations of
only the selected network.

Common Inputs
------------------------

:P: Network level p-value threshold
:Behavior Count: Number of different behavior vectors intended to test.

Provided Tests
---------------------------

* **Hypergeomtric**

  * MATLAB's `hypercdf <https://www.mathworks.com/help/stats/hygecdf.html>` used to find the probablity
* **Chi-squred**

  * Runs a :math:`\chi`\ :sup:`2` test. 

.. math::

    \chi^2 = \sum_{n=1}^n \frac{O_i - E_i)^2}{E_i}

* **Kolmogorov-Smirnov**
  
  * MATLAB's `kstest2 <https://www.mathworks.com/help/stats/kstest2.html>`
* **Wilcoxon**

  * MATLAB's `ranksum <https://www.mathworks.com/help/stats/ranksum.html>`
* **Welch's t-test**

  * Uses a modified version of MATLAB's t-test found in `+nla/WelchT`

.. math::

    t = \frac{\overline{X_1} - \overline{X_2}}{\sqrt{s_{\overline{X_1}}^2 - s_{\overline{X_2}}^2}}
    where
    s_{\overline{X_i}} = \frac{s_i}{\sqrt{N_i}}

* 