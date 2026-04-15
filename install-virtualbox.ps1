# Example PowerShell script to install or uninstall VirtualBox

param(
    [string]$Action
)

# Function to display usage
function Show-Usage {
    Write-Host "Usage: .\install-virtualbox.ps [install|uninstall]"
    Write-Host "  install  - Install VirtualBox"
    Write-Host "  uninstall - Uninstall VirtualBox"
    exit
}

# Check if action is provided
if (-not $Action) {
    Show-Usage
}

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Not admin, elevate the script
    Start-Process powershell.exe -ArgumentList "-File `"$PSCommandPath`" -Action $Action" -Verb RunAs
    exit
}

# Define variables
$virtualBoxUrl = "https://download.virtualbox.org/virtualbox/7.0.14/VirtualBox-7.0.14-161095-Win.exe"
$installerPath = "$env:TEMP\VirtualBoxInstaller.exe"
$uninstallPath = "C:\Program Files\Oracle\VirtualBox\uninst.exe"

if ($Action -eq "install") {
    # Download the installer
    Write-Host "Downloading VirtualBox installer..."
    Invoke-WebRequest -Uri $virtualBoxUrl -OutFile $installerPath

    # Install VirtualBox silently
    Write-Host "Installing VirtualBox..."
    Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait

    # Clean up the installer file
    Remove-Item $installerPath

    Write-Host "VirtualBox installation completed."
} elseif ($Action -eq "uninstall") {
    # Check if uninstaller exists
    if (Test-Path $uninstallPath) {
        Write-Host "Uninstalling VirtualBox..."
        Start-Process -FilePath $uninstallPath -ArgumentList "/S" -Wait
        Write-Host "VirtualBox uninstallation completed."
    } else {
        Write-Host "VirtualBox uninstaller not found. Is VirtualBox installed?"
    }
} else {
    Show-Usage
}