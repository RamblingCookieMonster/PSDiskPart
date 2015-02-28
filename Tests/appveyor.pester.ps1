# This script will invoke pester tests
# It should invoke on PowerShell v2 and later
# We serialize XML results and pull them in appveyor.yml

#If Finalize is specified, we collect XML output, upload tests, and indicate build errors
param([switch]$Finalize)

#Initialize some variables, move to the project root
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestsResults$PSVersion.xml"
    $ProjectRoot = $ENV:APPVEYOR_BUILD_FOLDER
    Set-Location $ProjectRoot
   

#Run a test with the current version of PowerShell
if(-not $Finalize)
{
    Write-Output "STATUS: Testing with PowerShell $PSVersion`n"
    
    Import-Module Pester

    Invoke-Pester -Path "$ProjectRoot\Tests" -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile" -PassThru |
        Select -ExpandProperty FailedCount |
        Export-Clixml -Path "$ProjectRoot\PesterResults$PSVersion.xml"
}
#If finalize is specified, check for failures and 
else
{
    Write-Output "STATUS: Collating results`n"

    $FailedCount = Get-ChildItem -Path "$ProjectRoot\PesterResults*.xml" |
        Import-Clixml | 
        Measure-Object -Sum |
        Select -ExpandProperty Sum

    Get-ChildItem -Path "$ProjectRoot\TestResults*.xml" | Foreach-Object {

        $Destination = "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)"
        $Source = $_.FullName

        (New-Object 'System.Net.WebClient').UploadFile( $Destination, $Source )
    }

    #Upload test output - you can see results on the 'Test' page

    if ($FailedCount -gt 0) {
        throw "$FailedCount tests failed."
    }
}