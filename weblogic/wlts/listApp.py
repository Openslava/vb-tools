# WebLogic Scripting Tool (WLST) script to list application states 
# in a WebLogic domain.
import sys
from getpass import getpass

if len(sys.argv) < 4:
    print("Usage: wlst.cmd script.py <username> <host> <port>")
    exit()

username = sys.argv[1]
host = sys.argv[2]
port = sys.argv[3]
password = getpass('Enter WebLogic password: ')

url = f't3://{host}:{port}'  # example 't3://localhost:7001'
connect(username, password, url)
# ...rest of your WLST script...
domainRuntime()

apps = cmo.getAppDeployments()
for app in apps:
    moduleName = app.getName()
    targets = app.getTargets()
    for t in targets:
        appRuntime = getMBean('/AppRuntimeStateRuntime/AppRuntimeStateRuntime')
        status = appRuntime.getCurrentState(moduleName, t.getName())
        print(moduleName + " on " + t.getName() + ": " + status)

disconnect()
exit()
