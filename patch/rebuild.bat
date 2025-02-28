@echo off
rem ='''
set pypath="%~dp0python\python.exe"
if not exist %pypath% set pypath="E:\tools\dev\python-2.7.3\python.exe"
if not exist %pypath% ( echo I can't find "%~dp0python\python.exe" !
pause
goto :EOF
)
%pypath% -x "%~f0" %*
pause
goto :EOF
rem '''

import sys,os,json,time

def checkpath(path):
    result = {}
    filelist = []
    titlelist = []
    newest = 0
    readme = ''
    subdir = path.replace(rootpath + '/', '')
    for name in os.listdir(path):
        fullname = path + '/' + name
        if os.path.isdir(fullname):
            continue
        if name == 'external.txt':
            for external in open(fullname).read().decode('utf8').split('\n'):
                if not external: continue
                if external.startswith("https://") or external.startswith("http://"):
                    filelist.append(external)
                else:
                    mtime = os.path.getmtime('../' + external)
                    if mtime > newest: newest = mtime
                    filelist.append('../' + external)
            continue
        if name == 'titles.csv':
            csv = open(fullname).read()
            try: csv = csv.decode('utf8')
            except:
                print fullname
                sys.exit()
            for title in csv.split('\n'):
                if not title: continue
                titlelist.append(title.split(u',', 1))
            continue
        if name == 'readme.txt':
            # set this to be readable
            readme = open(fullname).read().decode('utf8')
        mtime = os.path.getmtime(fullname)
        if mtime > newest:
            newest = mtime
        filelist.append(subdir + '/' + name)
    # if readme: filelist = []
    result['files'] = filelist
    result['title'] = titlelist
    result['time'] = int(newest)
    return result

rootpath = sys.path[0].decode()

data = []

def addpath(name, defbrand, path):
    result = checkpath(path)
    filelist = result['files']
    mtime = result['time']
    if not mtime:
        return
    titlelist = result['title']
    if not titlelist:
        titlelist.append([defbrand, name])
    for line in titlelist:
        if len(line) != 2:
            print path
        brand = line[0]
        title = line[1]
        data.append([mtime, brand, name, title, filelist])

for name in os.listdir(rootpath):
    path = rootpath + "/" + name
    if os.path.isdir(path):
#        print name.encode(sys.getfilesystemencoding())
        for subname in os.listdir(path):
            fullname = path + '/' + subname
            if os.path.isdir(fullname):
#                print subname.encode(sys.getfilesystemencoding())
                addpath(subname, name, fullname)
        addpath(name, '', path)
print '%d Titles' % len(data)

#sort by time
def cmp(a, b):
    if a[0] == b[0]: return 0
    if a[0] > b[0]: return -1
    if a[0] < b[0]: return 1
data.sort(cmp)

data = u'var all_data = [\n' + u',\n'.join([json.dumps(n, ensure_ascii=False, encoding="utf-8") for n in data]) + u'\n];';

open('alldata.js','w').write(data.encode('utf8'))