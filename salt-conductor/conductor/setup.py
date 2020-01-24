from setuptools import setup
import os, sys
from shutil import copyfile

# #################################################################################################
#
# dist: conductor-1.0-py2.7.egg (RECOMMENDED METHOD)
# build: python setup.py bdist_egg
# install: easy_install -s /srv/runners conductor-1.0-py2.7.egg 
# comments: This install method will place all modules in the default site-packages for python.
#           Should be the recommended way to install on non-development systems.
#           And all required files and scripts will be installed to /srv/runners. 
#           This is the execution directory of the conductor
#
# dist: conductor-1.0.tar.gz
# build: python setup.py sdist
# install on salt master: tar xf conductor-1.0.tar.gz -C /srv/runners --strip=2
# comments: This install method puts all modules and files in /srv/runners, so the modules are
#           loaded from there. This is the execution directory of the conductor.
#           Consider this the source distribution to be used on development systems where you 
#           current directory access to all libs. I.E. the libs will not be installed to system
#           site-packages location.
#
# NOTE: In addition to the python packages shown below, awscli >=1.2.9 apt package is also required
#
# #################################################################################################
def get_ext_modules(src):
  startdir = os.getcwd()
  os.chdir(src)
  dirs = src.split(',')
  files = []
  for d in dirs:
    for f in os.listdir(d):
      if not '.pyc' in f:
        copyfile(os.path.abspath(f), '{0}/{1}'.format(startdir, f))
        files.append(f)

  os.chdir(startdir)
  return files

def get_modules(src):
  files = []
  for f in os.listdir(src):
    if not '.pyc' in f:
      files.append('{0}.{1}'.format(src.split('/')[len(src.split('/')) - 1], f.split('.')[0]))

  return files


def get_files(src):
  dirs = src.split(',')
  files = []
  for d in dirs:
    for f in os.listdir(d):
      files.append('{0}/{1}'.format(d, f))

  return files

common_modules = get_ext_modules('../common')
modules = get_modules('{0}/modules'.format(os.getcwd()))

setup(name='conductor',
      version='1.0',
      description='Orchestration runner extension for saltstack',
      author='Paul Bruno',
      author_email='paul@acidhousetracks.com',
      data_files=[('common', list(common_modules))], 
      py_modules=['conductor','groups'] + list(modules),
      scripts=['__init__.py','scripts/conduct.py'] + list(get_files('doc')),
      url='wiki.somepage.com',
      long_description="""Custom orchestration provisioning runner module for Saltstack system """,
      classifiers=[
        "Programming Language :: Python 2.7",
      ],  
      install_requires=['boto>=2.39.0'],
      )  

for f in common_modules:
  os.remove(f)

 
