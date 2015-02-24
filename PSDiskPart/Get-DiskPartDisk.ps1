Function Get-DiskPartDisk
{
    <#
    .SYNOPSIS
	    Run a LIST DISK and parse the output into objects, from one or more remote systems

    .FUNCTIONALITY
        Computers

    .DESCRIPTION
	    Run a LIST DISK and parse the output into objects, from one or more remote systems.

        Get-Help Invoke-DiskPartScript -Full for details on implementation of remote calls

    .PARAMETER ComputerName
        Computer(s) to run command on.

    .EXAMPLE
        Get-DiskPartDisk -computername c-is-hyperv-1

        # Run 'list disk' on c-is-hyperv-1.

    .LINK
        https://github.com/RamblingCookieMonster/PSDiskPart
    
    .LINK
        Invoke-DiskPartScript

    .LINK
        Get-DiskPartDisk

    .LINK
        Get-DiskPartVolume

    .LINK
        Get-DiskPartVDisk

    .NOTES
        Thanks to Adam Conkle https://gallery.technet.microsoft.com/DiskPartexe-Powershell-0f7a1bab

    #>
    [OutputType('System.Management.Automation.PSObject')]
	[CmdletBinding()]
    param (
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName = $env:COMPUTERNAME
    )

    Process
    {

        
        foreach($Computer in $ComputerName)
        {
            $dpscript = "list disk`n"

            Try
            {
                $Output = $Null
                if($Computer -eq $env:COMPUTERNAME)
                {
                    $Output = $dpscript | diskpart
                }
                else
                {
                    $Output = ( Invoke-DiskPartScript -ComputerName $Computer -DiskPartText $dpscript -Raw -ErrorAction stop ) -split "`n"
                }
            }
            Catch
            {
                Write-Error $_
                Continue
            }
        
            $Disks = ForEach ($Line in $Output)
            {
	            If ($Line.StartsWith("  Disk"))
	            {
		            $Line
	            }
            }

            $DiskCount = $Disks.Count

            For ($i=1;$i -le ($DiskCount - 1);$i++)
            {
	            $currLine = $Disks[$i]
	            $currLine -Match "  Disk (?<disknum>...) +(?<sts>.............) +(?<sz>.......) +(?<fr>.......) +(?<dyn>...) +(?<gpt>...)" | Out-Null
	            $DiskObj = @{
                    "ComputerName" = $Computer
	                "DiskNumber" = $Matches['disknum'].Trim()
	                "Status" = $Matches['sts'].Trim()
	                "Size" = $Matches['sz'].Trim()
	                "Free" = $Matches['fr'].Trim()
	                "Dyn" = $Matches['dyn'].Trim()
	                "Gpt" = $Matches['gpt'].Trim()
                }

	            $dpscript = "select disk $($DiskObj.DiskNumber)`ndetail disk`n"

                Try
                {
                    $Output = $Null
                    if($Computer -eq $env:COMPUTERNAME)
                    {
                        $Output = $dpscript | diskpart
                    }
                    else
                    {
                        $Output = ( Invoke-DiskPartScript -ComputerName $Computer -DiskPartText $dpscript -Raw -ErrorAction stop ) -split "`n"
                    }
                }
                Catch
                {
                    Write-Error $_
                    Continue
                }
	
	            ForEach ($Line in $Output)
	            {
		            If ($Line -cmatch "Disk ID" -and $Line -match ":")
		            {
			             $DiskObj.Add( "DiskID", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Type") -and $Line -match ":")
		            {
			            $DiskObj.Add( "DetailType", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Status") -and $Line -match ":")
		            {
			            $DiskObj.Add( "DetailStatus", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Path") -and $Line -match ":")
		            {
			            $DiskObj.Add( "Path", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Target") -and $Line -match ":")
		            {
			           $DiskObj.Add( "Target", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("LUN ID") -and $Line -match ":")
		            {
			            $DiskObj.Add( "LUNID", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Location Path") -and $Line -match ":")
		            {
			            $DiskObj.Add( "LocationPath", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Current Read-only State") -and $Line -match ":")
		            {
			            $DiskObj.Add( "CurrentReadOnlyState", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Read-only") -and $Line -match ":")
		            {
			            $DiskObj.Add( "ReadOnly", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Boot Disk") -and $Line -match ":")
		            {
			            $DiskObj.Add( "BootDisk", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Pagefile Disk") -and $Line -match ":")
		            {
			            $DiskObj.Add( "PagefileDisk", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Hibernation File Disk") -and $Line -match ":")
		            {
			            $DiskObj.Add(  "HibernationFileDisk", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Crashdump Disk") -and $Line -match ":")
		            {
			            $DiskObj.Add( "CrashdumpDisk", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Clustered Disk") -and $Line -match ":")
		            {
			            $DiskObj.Add( "ClusteredDisk", $Line.Split(":")[1].Trim())
		            }
	            }
	
	            New-Object -TypeName PSObject -Property $DiskObj |
                    Select-Object -Property ComputerName,
	                DiskNumber,
	                Status,
	                Size,
	                Free,
	                Dyn,
	                Gpt,
                    DiskID,
                    DetailType,
                    DetailStatus,
                    Path,
                    Target,
                    LUNID,
                    LocationPath,
                    CurrentReadOnlyState,
                    ReadOnly,
                    BootDisk,
                    PagefileDisk,
                    HibernationFileDisk,
                    CrashdumpDisk,
                    ClusteredDisk
            }
        }
    }
}