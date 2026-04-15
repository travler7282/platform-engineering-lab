# platform-engineering-lab

This is a repository that contains the platform engineering lab Ansible playbooks, scripts, and other files to deploy a simple lab using VirtualBox, Vagrant, Ansible, K3s.

## Windows Installation

The following instructions are for Windows based systems, these instructions should work on Windows 10 or 11 systems, but is currently tested for Windows 10, previous versions of Windows are untested.

### PowerShell Execution Policy

To run PowerShell scripts on your system, you may need to adjust the execution policy. PowerShell scripts are disabled by default for security reasons.

1. Open PowerShell as an administrator.
2. Run the following command to allow signed scripts:

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
   ```

   - `RemoteSigned`: Allows local scripts and remote signed scripts.
   - `LocalMachine`: Applies to all users on the machine.

   If you prefer to allow all scripts (less secure), use:

   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope LocalMachine
   ```

3. Confirm by typing `Y` when prompted.

Note: You can also run scripts with `-ExecutionPolicy Bypass` for one-time execution without changing the policy.

### Installing VirtualBox

A PowerShell script `install-virtualbox.ps1` is provided to install or uninstall VirtualBox.

### Prerequisites

- Windows operating system
- Internet connection (for downloading the installer)
- Administrator privileges (the script will prompt for elevation if needed)

### Usage

Open PowerShell and navigate to the repository directory.

```powershell
# To install VirtualBox
.\install-virtualbox.ps1 install

# To uninstall VirtualBox
.\install-virtualbox.ps1 uninstall

# To display usage information
.\install-virtualbox.ps1
```

The script will:
- Check for administrator privileges and prompt for elevation if necessary.
- Download the VirtualBox installer from the official website.
- Install/uninstall VirtualBox silently.
- Clean up temporary files.

### Notes

- The script uses the latest available version URL; update it if needed.
- For uninstall, it assumes the default installation path.
