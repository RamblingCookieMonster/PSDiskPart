#handle PS2
    if(-not $PSScriptRoot)
    {
        $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
    }

#Get public and private function definition files.
    $Public  = Get-ChildItem $PSScriptRoot\*.ps1 -ErrorAction SilentlyContinue 
    $Private = Get-ChildItem $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue 

#Dot source the files
    Foreach($import in @($Public + $Private))
    {
        Try
        {
            . $import.fullname
        }
        Catch
        {
            Write-Error "Failed to import function $($import.fullname)"
        }
    }
    
#Create some aliases, export public functions
    Export-ModuleMember -Function $($Public | Select -ExpandProperty BaseName) -Alias *