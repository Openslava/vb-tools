# wlst.cmd myscript.py weblogic myhost 7001
$wlst = "C:\Oracle\Middleware\oracle_common\common\bin\wlst.cmd"
$script = "C:\scripts\listApps.py"

& $wlst $script "weblogic" "localhost" "7001"
