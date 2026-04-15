# Example PowerShell script to install or uninstall VirtualBox

param(
    [string]$Action
)

# Function to get the latest VirtualBox installer URL
function Get-LatestVirtualBoxUrl {
    $baseUrl = "https://download.virtualbox.org/virtualbox/"
    try {
        $response = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing
        $content = $response.Content
        # Find version folders
        $versions = [regex]::Matches($content, '<a href="(\d+\.\d+\.\d+)/">') | ForEach-Object { $_.Groups[1].Value }
        if ($versions.Count -eq 0) { throw "No versions found" }
        # Sort and get latest
        $latestVersion = $versions | Sort-Object { [version]$_ } | Select-Object -Last 1
        $versionUrl = $baseUrl + $latestVersion + "/"
        $response2 = Invoke-WebRequest -Uri $versionUrl -UseBasicParsing
        $content2 = $response2.Content
        # Find the Windows exe
        $exeMatch = [regex]::Match($content2, '<a href="(VirtualBox-\d+\.\d+\.\d+-\d+-Win\.exe)">')
        if ($exeMatch.Success) {
            return $versionUrl + $exeMatch.Groups[1].Value
        } else {
            throw "Could not find VirtualBox installer exe"
        }
    } catch {
        Write-Host "Error fetching latest VirtualBox URL: $_"
        # Fallback to hardcoded URL
        return "https://download.virtualbox.org/virtualbox/7.0.14/VirtualBox-7.0.14-161095-Win.exe"
    }
}

# Function to get VirtualBox install path
function Get-VirtualBoxInstallPath {
    try {
        $key = Get-ItemProperty "HKLM:\SOFTWARE\Oracle\VirtualBox" -ErrorAction Stop
        return $key.InstallDir
    } catch {
        return $null
    }
}

# Function to get VirtualBox uninstall string
function Get-VirtualBoxUninstallString {
    try {
        $uninstallKeys = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction Stop
        foreach ($key in $uninstallKeys) {
            $props = Get-ItemProperty $key.PSPath -ErrorAction SilentlyContinue
            if ($props.DisplayName -like "*VirtualBox*") {
                return $props.UninstallString
            }
        }
    } catch {
        # Ignore errors
    }
    return $null
}

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
$virtualBoxUrl = Get-LatestVirtualBoxUrl
$installerPath = "$env:TEMP\VirtualBoxInstaller.exe"

if ($Action -eq "install") {
    # Check if already installed
    $installPath = Get-VirtualBoxInstallPath
    if ($installPath) {
        Write-Host "VirtualBox is already installed at: $installPath"
        exit
    }

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
    # Get uninstall string from registry
    $uninstallString = Get-VirtualBoxUninstallString
    if ($uninstallString) {
        Write-Host "Uninstalling VirtualBox..."
        Start-Process -FilePath $uninstallString -ArgumentList "/S" -Wait
        Write-Host "VirtualBox uninstallation completed."
    } else {
        Write-Host "VirtualBox is not installed or uninstaller not found."
    }
} else {
    Show-Usage
}