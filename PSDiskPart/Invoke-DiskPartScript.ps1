Function Invoke-DiskPartScript {
    <#
    .SYNOPSIS
	    Run a DiskPart script on one or more remote systems

    .FUNCTIONALITY
        Computers

    .DESCRIPTION
	    Run a DiskPart script on one or more remote systems.  Results and errors sent to text files on that system, returned by this function, and filtered as specified.

        Command runs via cmd /c on the remote system, not PowerShell.
        Command invoked via Win32_Process Create method.

        Returns an object containing the computer, results, errors, command, and pattern.
	
        Be very, very catreful with this.  DiskPart can do evil things.  Use this at your own risk.

    .PARAMETER ComputerName
        Computer(s) to run command on.

    .PARAMETER DiskPartText
        Text to run as a DiskPart script

    .PARAMETER Pattern
        Optional regular expression to filter results

    .PARAMETER ScriptFile
        Temporary file to store DiskPart script on remote system.  Must be relative to remote system (not a file share).  Default is "C:\DiskPartScript.txt"

    .PARAMETER TempOutputFile
        Temporary file to store results on remote system.  Must be relative to remote system (not a file share).  Default is "C:\DiskPartOutput.txt"
    
    .PARAMETER TempErrorFile
        Temporary file to store redirected errors.  Must be relative to remote system (not a file share).  Defaults to "C:\DiskPartError.txt"

    .PARAMETER Raw
        Return only the output from the command

    .EXAMPLE
        Invoke-DiskPartScript -computername wbf, c-is-hyperv-1 -DiskPartText "list volume"

        # Run 'list volume' on wbf and c-is-hyperv-1.

    .EXAMPLE
	    Invoke-DiskPartScript -computername wbf, c-is-hyperv-1 -DiskPartText "list disk" -pattern "offline" | select-object computer, results

        # Run 'list disk' on wbf and c-is-hyperv-1.  Filter output to lines that match 'offline'.  Only display the Computer and Results

    .EXAMPLE
        $ScriptContent = Get-Content C:\DiskPart.txt -Raw
        Invoke-DiskPartScript -ComputerName c-is-hyperv-1 -DiskPartText $ScriptContent

        # Get the content of an existing diskpart script, use it against C-IS-HYPERV-1.

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

    #>
    [OutputType('System.Management.Automation.PSObject', 'System.String')]
	[CmdletBinding()]
	param(
        [Parameter(
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,

        $DiskPartText = "list disk",

        $Pattern,

        $ScriptFile = "C:\DiskPartScript.txt",
        
        $TempOutputFile = "C:\DiskPartOutput.txt",

        $TempErrorFile = "C:\DiskPartError.txt",

        [switch]$Raw
	)
    
	Begin
    {

        Function Wait-Path {
            [cmdletbinding()]
            param (
                [string[]]$Path,
                [int]$Timeout = 5,
                [int]$Interval = 1,
                [switch]$Passthru
            )

            $StartDate = Get-Date
            $First = $True

            Do
            {
                #Only sleep if this isn't the first run
                    if($First -eq $True)
                    {
                        $First = $False
                    }
                    else
                    {
                        Start-Sleep -Seconds $Interval
                    }

                #Test paths and collect output
                    [bool[]]$Tests = foreach($PathItem in $Path)
                    {
                        Try
                        {
                            if(Test-Path $PathItem -ErrorAction stop)
                            {
                                Write-Verbose "'$PathItem' exists"
                                $True
                            }
                            else
                            {
                                Write-Verbose "Waiting for '$PathItem'"
                                $False
                            }
                        }
                        Catch
                        {
                            Write-Error "Error testing path '$PathItem': $_"
                            $False
                        }
                    }

                # Identify whether we can see everything
                    $Return = $Tests -notcontains $False -and $Tests -contains $True
        
                # Poor logic, but we break the Until here
                    # Did we time out?
                    # Error if we are not passing through
                    if ( ((Get-Date) - $StartDate).TotalSeconds -gt $Timeout)
                    {
                        if( $Passthru )
                        {
                            $False
                            break
                        }
                        else
                        {
                            Throw "Timed out waiting for paths $($Path -join ", ")"
                        }
                    }
                    elseif($Return)
                    {
                        if( $Passthru )
                        {
                            $True
                        }
                        break
                    }
            }
            Until( $False ) # We break out above
        }

        #Initialize command string and variables for status tracking
            [string]$cmd = "cmd /c diskpart /s $ScriptFile > $TempOutputFile 2> $tempErrorFile"
	}
	
	Process
    {
        foreach($Computer in $ComputerName){
            
            Write-Verbose "Running '$cmd' on '$computer'"

            #define remote file path - computername, drive, folder path
            $remoteTempOutputFile = "\\{0}\{1}`${2}" -f "$computer", (split-path $TempOutputFile -qualifier).TrimEnd(":"), (Split-Path $TempOutputFile -noqualifier)
            $remoteTempErrorFile = "\\{0}\{1}`${2}" -f "$computer", (split-path $tempErrorFile -qualifier).TrimEnd(":"), (Split-Path $tempErrorFile -noqualifier)
            $remoteScriptFile = "\\{0}\{1}`${2}" -f "$computer", (split-path $ScriptFile -qualifier).TrimEnd(":"), (Split-Path $ScriptFile -noqualifier)

            #Attempt to delete any previous results, run command
            Try
            {
                Remove-Item -Path $remoteTempOutputFile, $remoteTempErrorFile -Force -ErrorAction SilentlyContinue -Confirm:$False
                Set-Content -Path $remoteScriptFile -Value $DiskPartText -force -ErrorAction stop
            }
            Catch
            {
                Write-Error "Error preparing $computer`n:$_"
                Continue
            }
            Try
            {
                Wait-Path -Path $remoteScriptFile -Timeout 10 -Interval .5 -ErrorAction stop
                $processID = (Invoke-WmiMethod -class Win32_process -name Create -ArgumentList $cmd -ComputerName $computer -ErrorAction Stop).processid
            }
            Catch
            {
                Write-Error "Error running '$cmd' on $computer"
                Continue
            }

            #wait for process to complete
            while (
                $(
                    try
                    {
                        Get-Process -Id $processid -ComputerName $computer -ErrorAction Stop
                    }
                    catch
                    {
                        if($_ -like "Cannot find a process with*")
                        {
                            $FALSE
                        }
                        else
                        {
                            Write-Error "Error checking for PID $ProcessId on $Computer`: $_"
                        } 
                    }
                )
            )
            { Start-Sleep -seconds 2 }
        
            #gather results
            if( Wait-Path $remoteTempOutputFile -Timeout 15 -Interval .5 -Passthru )
            {
                if($pattern)
                {
                    $Results = ( Select-String -Path $remoteTempOutputFile -Pattern $Pattern | Select -ExpandProperty Line ) -join "`n"
                }
                else
                {
                    $results = Get-Content -Path $remoteTempOutputFile -Raw
                }
            }
            else
            {
                $results = "Results from '$TempOutputFile' on $computer converted to '$remoteTempOutputFile'.  This path is not accessible from your system."
            }
            
            #gather errors
            if( Wait-Path -Path $remoteTempErrorFile -Timeout 10 -Interval .5 -Passthru )
            {
                $errors = Get-Content -Path $remoteTempErrorFile
            }
            else
            {
                $results = "Errors from '$tempErrorFile' on $computer converted to '$remoteTempErrorFile'.  This path is not accessible from your system."
            }

            if($Raw)
            {
                $Results
                if($Errors)
                {
                    Write-Error $Errors
                }
            }
            else
            {
                #write out the results
                [pscustomobject] @{
                    Computer = $computer
                    Results = $Results
                    Errors = $errors
                    Command = $cmd
                    Pattern = $Pattern
                }
            }

            Remove-Item -Path $remoteTempOutputFile, $remoteScriptFile, $remoteTempErrorFile -Force -ErrorAction SilentlyContinue
        }
    }

}