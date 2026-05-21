[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]  [string]$TargetPath,
    [Parameter(Mandatory = $true)]  [string]$Arguments,
    [Parameter(Mandatory = $true)]  [string]$IconPath,
    [Parameter(Mandatory = $true)]  [string]$OutputPath,
    [Parameter(Mandatory = $false)] [string]$WorkingDirectory = "",
    [Parameter(Mandatory = $false)] [switch]$Force
)

Set-StrictMode -Version Latest
# NOTE: ErrorActionPreference left at default ('Continue') so [Console]::Error.WriteLine
#       does not trigger early termination before our explicit exit codes.

# Pre-Flight Checks
if (-not (Test-Path $TargetPath)) {
    [Console]::Error.WriteLine("TargetPath not found: $TargetPath")
    exit 3
}
if (-not (Test-Path $IconPath)) {
    [Console]::Error.WriteLine("IconPath not found: $IconPath")
    exit 3
}
$parentDir = Split-Path $OutputPath -Parent
if (-not (Test-Path $parentDir)) {
    [Console]::Error.WriteLine("Output parent directory not found: $parentDir")
    exit 3
}
if ((Test-Path $OutputPath) -and -not $Force) {
    [Console]::Error.WriteLine("Shortcut already exists (use -Force to overwrite): $OutputPath")
    exit 2
}
if ((Test-Path $OutputPath) -and $Force) {
    Remove-Item $OutputPath -Force
}

# Create Shortcut (COM operations need Stop mode for proper try/catch)
try {
    $ErrorActionPreference = 'Stop'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($OutputPath)
    $shortcut.TargetPath = $TargetPath
    $shortcut.Arguments = $Arguments
    $shortcut.IconLocation = "$IconPath,0"
    if ($WorkingDirectory) { $shortcut.WorkingDirectory = $WorkingDirectory }
    $shortcut.Save()
    $ErrorActionPreference = 'Continue'
} catch {
    [Console]::Error.WriteLine("COM error during shortcut creation: $_")
    exit 1
}

# Verify
if (-not (Test-Path $OutputPath)) {
    [Console]::Error.WriteLine("Shortcut was not created at: $OutputPath")
    exit 1
}

# JSON Output
[PSCustomObject]@{
    status      = "ok"
    output_path = $OutputPath
    target      = $TargetPath
    arguments   = $Arguments
    icon        = $IconPath
} | ConvertTo-Json -Compress
