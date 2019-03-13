#========================================================================#
#      REPLACE module_name WITH THE NAME OF YOUR CYTHON MODULE           #
#========================================================================#
module_name = "tictactoe" #  should not include .pyx'         #
#========================================================================#


import sys
cy_name = module_name + ".pyx"


# displays bar across console
from os import popen
_, console_width = popen('stty size', 'r').read().split()
console_width = int(console_width)
print('=' * console_width)


print("Setup script for", module_name)


## Default compile options ##
 # This block checks for Cython setup arguments
 # you can provide your own if you want to test out different
 # options and this block will be mainly ignored
if len(sys.argv) == 1: # no command line args
    print(cy_name + " compiling with default args")
    print("\tadding \"build_ext\" and \"--inplace\" to sys.argv\n")
    sys.argv.extend( ["build_ext", "--inplace"] )


# This block compiles/sets up the hw10 module
# from the  hw10.pyx cython file
from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize
from numpy import get_include
print("   Cython may give a depricated NumPy API warning. This warning is safe to ignore.\n")
setup(
    ext_modules = cythonize(
        Extension(
            module_name,
            [cy_name],
            define_macros=[("NPY_NO_DEPRECATED_API",None)],
            include_dirs=[get_include()]
        )
    )
)


print(module_name + " setup complete!")

# displays bar across console
print('=' * console_width)
