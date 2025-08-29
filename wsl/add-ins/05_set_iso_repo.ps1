<#
.SYNOPSIS
    Sets up ISO as local repository in WSL
.PARAMETER distroName
    WSL distribution name (default: "OracleLinux_8_10")  
.PARAMETER isoPath
    Path to Oracle Linux ISO file (required)
.PARAMETER mountPoint
    Mount point (default: "/mnt/iso-repo")
.PARAMETER permanent
    Add to /etc/fstab for permanent mounting
#>
[CmdletBinding()]
param(
    [string]$distroName = "OracleLinux_8_10",
    [Parameter(Mandatory=$true)]
    [string]$isoPath,
    [string]$mountPoint = "/mnt/iso-repo",
    [switch]$permanent
)

Write-Host "� Setting up ISO repository for $distroName" -ForegroundColor Cyan

# Validate ISO
if (-not (Test-Path $isoPath)) {
    Write-Error "❌ ISO not found: $isoPath"
    exit 1
}

# Convert to WSL path
$wslIsoPath = $isoPath -replace '^([A-Z]):', '/mnt/$1' -replace '\\', '/' -replace ' ', '\ '

$script = @"
set -e
echo "📁 Mounting ISO..."
mkdir -p $mountPoint
mountpoint -q $mountPoint && umount $mountPoint || true
mount -o loop,ro '$wslIsoPath' $mountPoint

echo "📝 Creating repository config..."
cat > /etc/yum.repos.d/local-iso.repo << 'EOF'
[local-baseos]
name=Local ISO - BaseOS
baseurl=file://$mountPoint/BaseOS
enabled=1
gpgcheck=0

[local-appstream]
name=Local ISO - AppStream
baseurl=file://$mountPoint/AppStream
enabled=1
gpgcheck=0
EOF
"@

if ($permanent) {
    $script += @"

echo "🔧 Adding to /etc/fstab..."
grep -v '$mountPoint' /etc/fstab > /tmp/fstab.new || true
echo '$wslIsoPath $mountPoint iso9660 loop,ro,auto 0 0' >> /tmp/fstab.new
mv /tmp/fstab.new /etc/fstab
"@
}

$script += @"

echo "🧹 Testing repository..."
yum clean all
yum repolist
echo "✅ ISO repository ready!"
"@

try {
    wsl -d $distroName -u root -- bash -c "$script"
    Write-Host "✅ Setup completed!" -ForegroundColor Green
    Write-Host "- Test: wsl -d $distroName -- yum search kernel" -ForegroundColor Yellow
} catch {
    Write-Error "❌ Setup failed: $_"
    exit 1
}
