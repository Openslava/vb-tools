# !!! executed from the root of the repository

# Get the directory where this script is located and navigate to repository root
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Split-Path -Parent $scriptDir

# !! Prerequisites - Manual Download from Oracle  JDK1.8... and WebLogic 12... !!
# URL: https://www.oracle.com/qa/middleware/technologies/weblogic-server-downloads.html  
# URL: https://www.oracle.com/java/technologies/javase-jdk8-doc-downloads.html

# Full WebLogic setup from PowerShell into WSL 
$distroName = "OracleLinux_8_10"

# ensure WSL is setup  
& "$repoRoot\wsl\01_set_wsl.ps1" -distroName $distroName

# Prerequisites: Copy these files to WSL /opt/oracle/install_files/

#  join them with LF line endings
$commands = @(
    "set -e",
    # current directory
    "pwd",
    "mkdir -p /opt/oracle/install_files",
    # Copy files to WSL and install weblogic,
    "cp -v /mnt/c/Users/$env:USERNAME/Downloads/jdk-8u461-linux-x64.rpm /opt/oracle/install_files/",
    "cp -v /mnt/c/Users/$env:USERNAME/Downloads/fmw_12.2.1.4.0_infrastructure_Disk1_1of1.zip /opt/oracle/install_files/",
    "chmod 644 /opt/oracle/install_files/*",
    "ls -la /opt/oracle/install_files/",
    # Navigate to weblogic scripts directory and run as root, then switch to weblogic user
    "./weblogic/01_set_weblogic.sh",
    "./weblogic/02_set_domain.sh",
    "./weblogic/03_run_domain.sh"
)
$script = $commands -join "`n"
# run script in WSL
wsl -d $distroName -e sudo bash -c "$script"

