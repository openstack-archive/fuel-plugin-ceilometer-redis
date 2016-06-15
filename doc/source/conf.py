import sys
import os
extensions = []
templates_path = ['_templates']
source_suffix = '.rst'
master_doc = 'index'
project = u'The Redis Plugin for Ceilometer documentation'
copyright = u'2016, Mirantis Inc.'
version = '0.1'
release = '0.1.0'
exclude_patterns = [
]
pygments_style = 'sphinx'
html_theme = 'default'
htmlhelp_basename = 'RedisPlugindoc'
latex_elements = {
}
latex_documents = [
  ('index', 'RedisPlugindoc.tex', u'The Redis Plugin for Ceilometer documentation',
   u'Mirantis Inc.', 'manual'),
]
man_pages = [
    ('index', 'redisplugin', u'The Redis Plugin for Ceilometer documentation',
     [u'Mirantis Inc.'], 1)
]
texinfo_documents = [
  ('index', 'RedisPlugin', u'The Redis Plugin for Ceilometer documentation',
   u'Mirantis Inc.', 'RedisPlugin', 'One line description of project.',
   'Miscellaneous'),
]
latex_elements = {'classoptions': ',openany,oneside', 'babel':
                  '\\usepackage[english]{babel}'}
