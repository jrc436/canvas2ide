#This is a very simple script that is designed to change package declarations within java files to their actual folder structure. 
#It was designed for use with canvas2ide, but it should be easily applied to other auto-repackaging code

#Author: Jeremy Cole

import sys
import os

srcdir = sys.argv[1]

if not os.path.isdir(srcdir):
	raise Exception('input not a src dir')


allnames = []
for (dirpath, dirnames, filenames) in os.walk(srcdir):
	allnames.extend(dirnames)
for name in allnames:
	for (dirpath, dirnames, filenames) in os.walk(srcdir+"/"+name):
		for f in filenames:
			fi = file(dirpath+"/"+f, 'r')
			lines = fi.readlines()
			wlines = []
			pkg = "package "
			for line in lines:
				if pkg in line:
					startind=line.index(pkg)+len(pkg)
					newstart = pkg+name+"."
					oldend = line[startind:]
					writeline = newstart + oldend
				else:
					writeline = line
				wlines.append(writeline)
			fi.close()
			fi = file(dirpath+"/"+f, 'w')
			fi.writelines(wlines)
			fi.close()
