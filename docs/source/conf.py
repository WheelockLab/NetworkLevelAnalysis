import os
# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

html_baseurl = os.environ.get("READTHEDOCS_CANONICAL_URL", "/")

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'Network Level Analysis Toolbox'
copyright = '2024, Muriah Wheelock'
author = 'Muriah Wheelock'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx.ext.intersphinx', 
    'sphinxcontrib.matlab', 
    'sphinx_rtd_theme',
    'sphinxcontrib.bibtex',
    'sphinx.ext.autodoc'
]
this_dir = os.path.dirname(os.path.abspath(__file__))
matlab_src_dir = os.path.abspath(os.path.join(this_dir, '../../+nla'))

templates_path = ['_templates']
exclude_patterns = []



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']


# -- Options for Intersphinx ------------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/extensions/intersphinx.html#module-sphinx.ext.intersphinx

intersphinx_mapping = {}

# -- Options for bibtex ----------------------------
# https://sphinxcontrib-bibtex.readthedocs.io/en/latest/quickstart.html#installation

bibtex_bibfiles = ['refs.bib']
bibtex_default_style = 'plain'
bibtex_reference_style = 'super'