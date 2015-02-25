Import-Module -Force $PSScriptRoot\..\PSDiskPart

Describe 'Invoke-DiskPartScript' {
    
    Context 'Strict mode' { 

        Set-StrictMode -Version latest

        It 'Should list disks on a local system' {
            $OutString = Invoke-DiskPartScript -ComputerName $env:COMPUTERNAME -DiskPartText "list disk" -Raw
            $OutArray = ($out -split "`n") | Where-Object { $_ -match "[A-Za-z0-9]"}
            
            #Hopefully you have at least one disk.
            $OutArray.Count | Should BeGreaterThan 4

            #Is this different on other versions of Windows?  Is there a better regex?
            $OutString | Should Match "\s*Disk ###\s*Status\s*Size\s*Free.*"
        }
    }
}

