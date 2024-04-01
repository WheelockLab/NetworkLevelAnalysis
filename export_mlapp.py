import os, zipfile

for filename in [('./NLA_GUI.mlapp', './NLA_GUI_exported.m'), ('./NLAResult.mlapp', './NLAResult_exported.m')]:
    with zipfile.ZipFile(filename[0]) as zip_object:
        zip_object.extract('matlab/document.xml')
    with open('matlab/document.xml') as filedata:
        data = filedata.read().splitlines(True)

    classdef_index = data[0].find('classdef')
    open(filename[1], 'w').close()
    with open(filename[1], 'w') as newfile:
        newfile.write(data[0][classdef_index:])
        newfile.writelines(data[1:-1])
        newfile.write('end')