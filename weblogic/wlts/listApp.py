# List WebLogic applications
import sys
from getpass import getpass

if len(sys.argv) < 4:
    print("Usage: wlst.cmd script.py <username> <host> <port>")
    exit()

username, host, port = sys.argv[1:4]
password = getpass('WebLogic password: ')

print(f"🔗 Connecting to {host}:{port}...")
connect(username, password, f't3://{host}:{port}')

domainRuntime()
apps = cmo.getAppDeployments()

print("📱 Application Status:")
for app in apps:
    name = app.getName()
    for target in app.getTargets():
        runtime = getMBean('/AppRuntimeStateRuntime/AppRuntimeStateRuntime')
        status = runtime.getCurrentState(name, target.getName())
        print(f"  {name} on {target.getName()}: {status}")

disconnect()
exit()
