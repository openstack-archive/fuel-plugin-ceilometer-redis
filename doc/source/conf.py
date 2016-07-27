import sys
import os
extensions = []
templates_path = ['_templates']
source_suffix = '.rst'
master_doc = 'index'
project = u'The Ceilometer Redis Plugin'
copyright = u'2016, Mirantis Inc.'
version = '0.1'
release = '1.0.3'
exclude_patterns = [
]
pygments_style = 'sphinx'
html_theme = 'default'
htmlhelp_basename = 'RedisPlugindoc'
latex_elements = {
}
latex_documents = [
  ('index', 'RedisPlugindoc.tex', u'The Ceilometer Redis Plugin',
   u'Mirantis Inc.', 'manual'),
]
man_pages = [
    ('index', 'redisplugin', u'The Ceilometer Redis Plugin',
     [u'Mirantis Inc.'], 1)
]
texinfo_documents = [
  ('index', 'RedisPlugin', u'The Ceilometer Redis Plugin',
   u'Mirantis Inc.', 'RedisPlugin', 'One line description of project.',
   'Miscellaneous'),
]
latex_elements = {'classoptions': ',openany,oneside', 'babel':
                  '\\usepackage[english]{babel}'}
