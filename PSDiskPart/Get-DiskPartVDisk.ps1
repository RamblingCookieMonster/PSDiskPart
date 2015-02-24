Function Get-DiskPartVDisk
{
    <#
    .SYNOPSIS
	    Run a LIST VDISK and parse the output into objects, from one or more remote systems

    .FUNCTIONALITY
        Computers

    .DESCRIPTION
	    Run a LIST VDISK and parse the output into objects, from one or more remote systems.

        Get-Help Invoke-DiskPartScript -Full for details on implementation of remote calls

    .PARAMETER ComputerName
        Computer(s) to run command on.

    .EXAMPLE
        Get-DiskPartVDisk -computername c-is-hyperv-1

        # Run 'list vdisk' on c-is-hyperv-1.

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
            $dpscript = "list vdisk`n"
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
        
            $VDisks = ForEach ($Line in $Output)
            {
	            If ($Line.StartsWith(" VDisk"))
	            {
		            $Line
	            }
            }

            $VDiskCount = $VDisks.Count

            For ($i=1; $i -le ($VDiskCount - 1); $i++)
            {
	            $currLine = $VDisks[$i]
	            $currLine -Match "  VDisk (?<vdisknum>...) +(?<phydisknum>........) +(?<state>....................) +(?<type>.........) +(?<file>.+)" | Out-Null
	            $VDiskObj = @{
                    "ComputerName" = $Computer
	                "VDiskNumber" = $Matches['vdisknum'].Trim()
	                "PhysicalDiskNumber" = $Matches['phydisknum'].Trim()
	                "State" = $Matches['state'].Trim()
	                "Type" = $Matches['type'].Trim()
	                "File" = $Matches['file'].Trim()
                }

	            $dpscript = "select vdisk file=$($VDiskObj.File)`ndetail vdisk`n"

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
                    If ($Line -cmatch "Device type ID" -and $Line -match ":")
		            {
			            $VDiskObj.Add( "DeviceTypeId", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Vendor ID") -and $Line -match ":")
		            {
			            $VDiskObj.Add( "VendorId", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("State") -and $Line -match ":")
		            {
			            $VDiskObj.Add("DetailState", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Virtual size") -and $Line -match ":")
		            {
			            $VDiskObj.Add("VirtualSize", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Physical size") -and $Line -match ":")
		            {
			            $VDiskObj.Add("PhysicalSize", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Is Child") -and $Line -match ":")
		            {
			            $VDiskObj.Add( "IsChild", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Parent Filename") -and $Line -match ":")
		            {
			            $VDiskObj.Add("ParentFileName", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Associated disk#") -and $Line -match ":")
		            {
			            $VDiskObj.Add("AssociatedDiskNum", $Line.Split(":")[1].Trim())
		            }
	            }
	
	            New-Object -TypeName PSObject -Property $VDiskObj |
                    Select-Object -Property ComputerName,
                  	    VDiskNumber,
	                    PhysicalDiskNumber,
	                    State,
	                    Type,
	                    File,
                        DeviceTypeId,
                        VendorId,
                        DetailState,
                        VirtualSize,
                        PhysicalSize,
                        IsChild,
                        ParentFileName,
                        AssociatedDiskNum
            }
        }
    }
}