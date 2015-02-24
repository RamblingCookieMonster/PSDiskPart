Function Get-DiskPartVolume
{
    <#
    .SYNOPSIS
	    Run a LIST VOLUME and parse the output into objects, from one or more remote systems

    .FUNCTIONALITY
        Computers

    .DESCRIPTION
	    Run a LIST VOLUME and parse the output into objects, from one or more remote systems.

        Get-Help Invoke-DiskPartScript -Full for details on implementation of remote calls

    .PARAMETER ComputerName
        Computer(s) to run command on.

    .EXAMPLE
        Get-DiskPartVolume -computername c-is-hyperv-1

        # Run 'list volume' on c-is-hyperv-1.
    
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

            $dpscript = "list volume`n"
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
        

            $Vols = ForEach ($Line in $Output)
            {
	            If ($Line.StartsWith("  Volume"))
	            {
		            $Line
	            }
            }

            $VolCount = $Vols.Count

            For ($i=1;$i -le ($Vols.count-1);$i++)
            {
	            $currLine = $Vols[$i]
	            $currLine -Match "  Volume (?<volnum>...) +(?<drltr>...) +(?<lbl>...........) +(?<fs>.....) +(?<typ>..........) +(?<sz>.......) +(?<sts>.........) +(?<nfo>........)" | Out-Null
	            $VolObj = @{
                    "ComputerName" = $Computer
	                "VolumeNumber" = $Matches['volnum'].Trim()
	                "Letter" = $Matches['drltr'].Trim()
	                "Label" = $Matches['lbl'].Trim()
	                "FileSystem" = $Matches['fs'].Trim()
	                "Type" = $Matches['typ'].Trim()
	                "Size" = $Matches['sz'].Trim()
	                "Status" = $Matches['sts'].Trim()
	                "Info" = $Matches['nfo'].Trim()
                }

	            $dpscript = "select volume $($VolObj.VolumeNumber)`ndetail volume`n"

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
		            If ($Line.StartsWith("Read-only") -and $Line -match ":")
		            {
			            $VolObj.Add( "ReadOnly", $Line.Split(":")[1].Trim() )
		            }
		            ElseIf ($Line.StartsWith("Hidden") -and $Line -match ":")
		            {
			            $VolObj.Add( "Hidden", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("No Default Drive Letter") -and $Line -match ":")
		            {
			            $VolObj.Add( "NoDefaultDriveLetter", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Shadow Copy") -and $Line -match ":")
		            {
			            $VolObj.Add( "ShadowCopy", $Line.Split(":")[1].Trim() )
		            }
		            ElseIf ($Line.StartsWith("Offline") -and $Line -match ":")
		            {
			            $VolObj.Add( "Offline", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("BitLocker Encrypted") -and $Line -match ":")
		            {
			            $VolObj.Add( "BitLockerEncrypted", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Installable") -and $Line -match ":")
		            {
			            $VolObj.Add( "Installable", $Line.Split(":")[1].Trim() )
		            }
		            ElseIf ($Line.StartsWith("Volume Capacity") -and $Line -match ":")
		            {
			            $VolObj.Add( "VolumeCapacity", $Line.Split(":")[1].Trim())
		            }
		            ElseIf ($Line.StartsWith("Volume Free Space") -and $Line -match ":")
		            {
			            $VolObj.Add( "VolumeFreeSpace", $Line.Split(":")[1].Trim())
		            }
	            }
	
	            New-Object -TypeName PSObject -Property $VolObj |
                    Select-Object -Property ComputerName,
                    VolumeNumber,
                    Letter,
                    Label,
                    FileSystem,
                    Type,
                    Size,
                    Status,
                    Info,
                    ReadOnly,
                    Hidden,
                    NoDefaultDriveLetter,
                    ShadowCopy,
                    Offline,
                    BitLockerEncrypted,
                    Installable,
                    VolumeCapacity,
                    VolumeFreeSpace
            }
        }
    }
}