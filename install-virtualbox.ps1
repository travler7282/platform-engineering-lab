# Example PowerShell script to install or uninstall VirtualBox

param(
    [string]$Action,
    [switch]$Force
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

# Parse an uninstall command string into executable and arguments
function Parse-UninstallCommand {
    param(
        [string]$CommandLine
    )

    if (-not $CommandLine) { return $null }

    $tokens = [regex]::Matches($CommandLine, '("[^"]+"|[^"\s]+)') | ForEach-Object { $_.Value.Trim('"') }
    if ($tokens.Count -eq 0) { return $null }

    $exe = $tokens[0]
    $args = @()
    if ($tokens.Count -gt 1) {
        $args = $tokens[1..($tokens.Count - 1)]
    }

    if ($exe -match '(?i)^msiexec(?:\.exe)?$') {
        # Convert MSI maintenance install syntax to uninstall syntax if needed
        for ($i = 0; $i -lt $args.Count; $i++) {
            $args[$i] = $args[$i] -replace '^(?i)/I(\{[A-F0-9\-]+\})$', '/X$1'
        }
    }

    return @{ Exe = $exe; Args = $args }
}

# Function to confirm an operation
function Confirm-Operation {
    param(
        [string]$Message
    )

    if ($Force) {
        return $true
    }

    $response = Read-Host "$Message [Y/N]"
    return $response.Trim().ToUpper() -eq 'Y'
}

# Function to display usage
function Show-Usage {
    Write-Host "Usage: .\install-virtualbox.ps1 [install|uninstall] [-Force]"
    Write-Host "  install  - Install VirtualBox"
    Write-Host "  uninstall - Uninstall VirtualBox"
    Write-Host "  -Force   - Skip confirmation prompts for automation"
    exit
}

try {
    Write-Host "Script started. Action: $Action"
    Write-Host "Force confirmation disabled: $Force"

    # Check if action is provided
    if (-not $Action) {
        Show-Usage
    }

    Write-Host "Checking administrator privileges..."
    # Check if running as administrator
    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        # Not admin, prompt for elevation
        Write-Host "Not running as administrator. Prompting for elevation..."
        $args = @("-ExecutionPolicy", "Bypass", "-NoExit", "-File", "`"$PSCommandPath`"", "-Action", $Action)
        if ($Force) { $args += "-Force" }
        Start-Process powershell.exe -ArgumentList $args -Verb RunAs
        exit
    }

    Write-Host "Administrator privileges confirmed."

    Write-Host "Getting latest VirtualBox URL..."
    # Define variables
    $virtualBoxUrl = Get-LatestVirtualBoxUrl
    $installerPath = "$env:TEMP\VirtualBoxInstaller.exe"
    Write-Host "Latest URL: $virtualBoxUrl"

    if ($Action -ieq "install") {
        Write-Host "Checking if VirtualBox is already installed..."
        # Check if already installed
        $installPath = Get-VirtualBoxInstallPath
        if ($installPath) {
            Write-Host "VirtualBox is already installed at: $installPath"
            exit
        }

        $confirmMessage = "VirtualBox is not installed. Ready to install from $virtualBoxUrl. Continue?"
        if (-not (Confirm-Operation $confirmMessage)) {
            Write-Host "Install cancelled."
            exit
        }

        Write-Host "Downloading VirtualBox installer..."
        Invoke-WebRequest -Uri $virtualBoxUrl -OutFile $installerPath

        Write-Host "Installing VirtualBox..."
        Start-Process -FilePath $installerPath -Wait

        Write-Host "Cleaning up installer file..."
        Remove-Item $installerPath

        Write-Host "VirtualBox installation completed."
    } elseif ($Action -ieq "uninstall") {
        Write-Host "Checking if VirtualBox is installed..."
        # Get uninstall string from registry
        $uninstallString = Get-VirtualBoxUninstallString
        if (-not $uninstallString) {
            Write-Host "VirtualBox is not installed or uninstaller not found."
            exit
        }

        Write-Host "Uninstaller found: $uninstallString"
        $uninstallCmd = Parse-UninstallCommand $uninstallString
        if (-not $uninstallCmd) {
            Write-Host "Unable to parse uninstall command."
            exit
        }

        $confirmMessage = "VirtualBox is installed and will be uninstalled. Continue?"
        if (-not (Confirm-Operation $confirmMessage)) {
            Write-Host "Uninstall cancelled."
            exit
        }

        Write-Host "Executing: $($uninstallCmd.Exe) $($uninstallCmd.Args -join ' ')"
        Start-Process -FilePath $uninstallCmd.Exe -ArgumentList $uninstallCmd.Args -Wait
        Write-Host "VirtualBox uninstallation completed."
    } else {
        Show-Usage
    }

    Write-Host "Script completed successfully."
} catch {
    Write-Host "Error occurred: $_"
    Write-Host "Stack trace: $($_.ScriptStackTrace)"
    Read-Host "Press Enter to exit"
}