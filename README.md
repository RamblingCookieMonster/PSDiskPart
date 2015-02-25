[![Build status](https://ci.appveyor.com/api/projects/status/u6gtkc7on8nm4kpi/branch/master?svg=true)](https://ci.appveyor.com/project/RamblingCookieMonster/psdiskpart)

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

#Notes

* Thanks to Adam Conkle for the [disk part parsing pieces](https://gallery.technet.microsoft.com/DiskPartexe-Powershell-0f7a1bab).
* This was written as a component to help simplify [migrating to the Paravirtual SCSI Controller](http://www.davidklee.net/2014/01/08/retrofit-a-vm-with-the-vmware-paravirtual-scsi-driver/).  I've seen disks come up offline more often than not.
* Accompanying [blog post](https://ramblingcookiemonster.wordpress.com/2015/02/24/remotely-brick-a-system/) (pretty much the stuff above, with more rambling)
* TODO: More Pester tests
* TODO: Refactor some of the DiskPart parsing.  For example, PowerShell users might expect 'Yes' to be true, 'no' to be false
* TODO: Add parameters to Get commands.  For example, one should be able to get a specific disk, or limit output to 'list disk', rather than force 'detail disk'.