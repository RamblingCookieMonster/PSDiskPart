DiskPart PowerShell Module
=============

This is a PowerShell module for working with DiskPart.  Newer Operating Systems include many commands to replace DiskPart; unfortunately, these have not been extended to down-level operating systems.

Please be wary and read through this before using it.  While it works in my environment, you know the risks of working with diskpart.

Contributions to improve this would be more than welcome!

Caveats:
* Minimal testing.  Not something you want to hear with DiskPart.

#Functionality

Get DISK information:
  * ![Get DISK information](/Media/Get-DiskPartDisk.png)

Get VOLUME information:
  * ![Get VOLUME information](/Media/Get-DiskPartVolume.png)

Offline a disk
  * ![Offline a disk](/Media/Invoke-DiskPartScript-Offline.png)

Online a disk
  * ![Online a disk](/Media/Invoke-DiskPartScript-Online.png)

#Instructions

```powershell
# One time setup
    # Download the repository
    # Unblock the zip
    # Extract the PSDiskPart folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)

# Import the module.
    Import-Module PSDiskPart    #Alternatively, Import-Module \\Path\To\PSDiskPart

# Get commands in the module
    Get-Command -Module PSDiskPart

# Get help for a command
    Get-Help Get-DiskPartDisk -Full

# Get details about disks on the local computer and c-is-hyperv-1
    Get-DiskPartDisk -computername $ENV:COMPUTERNAME, c-is-hyperv-1

# Run a DiskPart script on SERVER1145, set disk 2 to online, clear the readonly attribute if it exists
# Mind the here string.  Ugly formatting necessary!
    
Invoke-DiskPartScript -ComputerName SERVER1145 -DiskPartText @"
select disk 2
online disk
attributes disk clear readonly
"@
```
