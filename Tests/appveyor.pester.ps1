$PSVersion = $PSVersionTable.PSVersion.Major
$TestFile = "TestsResults$($PSVersionTable.PSVersion.Major).xml"

#Change to the project path that we assume in pester
    #http://www.appveyor.com/docs/environment-variables
    $ProjectRoot = $ENV:APPVEYOR_BUILD_FOLDER
    Set-LocalGroup $ProjectRoot


#Run a test with the current version of PowerShell
    Import-Module Pester
    Write-Output "Testing with PowerShell $PSVersion"
    $PesterOutput = Invoke-Pester -Path "$ProjectRoot\Tests" -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile" -PassThru

    #Upload test output - you can see results on the 'Test' page
    (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path "$ProjectRoot\$TestFile"))

    if ($PesterOutput.FailedCount -gt 0) {
        throw "$($PesterOutput.FailedCount) tests failed for PowerShell $PSVersion."
    }