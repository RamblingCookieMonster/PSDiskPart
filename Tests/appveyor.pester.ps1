$PSVersion = $PSVersionTable.PSVersion.Major
$TestFile = "TestsResults$($PSVersionTable.PSVersion.Major).xml"
#http://www.appveyor.com/docs/environment-variables
$ProjectRoot = $ENV:APPVEYOR_BUILD_FOLDER

Import-Module Pester

#Run a test with the current version of PowerShell
    Write-Output "Testing with PowerShell $PSVersion"
    $PesterOutput = Invoke-Pester -Path "$ProjectRoot\Tests" -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile" -PassThru

    #Upload test output - you can see results on the 'Test' page
    (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path "$ProjectRoot\$TestFile"))

    if ($PesterOutput.FailedCount -gt 0) {
        throw "$($PesterOutput.FailedCount) tests failed for PowerShell $PSVersion."
    }