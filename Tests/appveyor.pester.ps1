$PSVersion = $PSVersionTable.PSVersion.Major
$TestFile = "TestsResults$($PSVersionTable.PSVersion.Major).xml"

#Run a test with the current version of PowerShell
    Write-Output "Testing with PowerShell $PSVersion"
    $PesterOutput = Invoke-Pester -Path ".\Tests" -OutputFormat NUnitXml -OutputFile $TestFile -PassThru

    #Upload test output - you can see results on the 'Test' page
    (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path ".\$TestFile"))

    if ($PesterOutput.FailedCount -gt 0) {
        throw "$($PesterOutput.FailedCount) tests failed for PowerShell $PSVersion."
    }