# This script will invoke pester tests
# It should invoke on PowerShell v2 and later
# We serialize XML results and pull them in appveyor.yml

#If Finalize is specified, we collect XML output, upload tests, and indicate build errors
param([switch]$Finalize)

#Initialize some variables, move to the project root
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestsResultsPS$PSVersion.xml"
    $ProjectRoot = $ENV:APPVEYOR_BUILD_FOLDER
    Set-Location $ProjectRoot
   

#Run a test with the current version of PowerShell
if(-not $Finalize)
{
    "`n`tSTATUS: Testing with PowerShell $PSVersion`n"
    
    Import-Module Pester

    Invoke-Pester -Path "$ProjectRoot\Tests" -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile" -PassThru |
        Select -ExpandProperty FailedCount |
        Export-Clixml -Path "$ProjectRoot\PesterResults$PSVersion.xml"
}
#If finalize is specified, check for failures and 
else
{
    #Show status...
        $AllFiles = Get-ChildItem -Path $ProjectRoot\*Results*.xml | Select -ExpandProperty FullName
        "`n`tSTATUS: Finalizing results`n"
        "COLLATING FILES:`n$($AllFiles | Out-String)"

    #Upload results for test page
        Get-ChildItem -Path "$ProjectRoot\TestResultsPS*.xml" | Foreach-Object {
        
            $Address = "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)"
            $Source = $_.FullName

            "UPLOADING FILES: $Address $Source"

            (New-Object 'System.Net.WebClient').UploadFile( $Address, $Source )
        }

    #What failed?
        $FailedCount = Get-ChildItem -Path "$ProjectRoot\PesterResults*.xml" |
            Import-Clixml | 
            Measure-Object -Sum |
            Select -ExpandProperty Sum
    
        if ($FailedCount -gt 0) {
            throw "$FailedCount tests failed."
        }
}