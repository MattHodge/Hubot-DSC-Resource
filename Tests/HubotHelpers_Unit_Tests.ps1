#################
#  TEST HEADER  #
#################

$dscModule = 'Hubot'

$originalLocation = Get-Location

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $here

describe "HubotHelpers" {
    
    ######################################
    #  USED FOR TESTING CLASS BASED DSC  #
    ######################################

    # To support $root\Tests folder structure
    If (Test-Path "..\$dscModule.psm1") {Copy-Item "..\$dscModule.psm1" 'TestDrive:\script.ps1'}
    # To support $root\Tests\Unit folder structure
    ElseIf (Test-Path "..\..\$dscModule.psm1") {Copy-Item "..\..\$dscModule.psm1" 'TestDrive:\script.ps1'}
    # Or simply throw...
    Else {Throw 'Unable to find source .psm1 file to test against.'}
    
    # Dot source the file to brint classes into current session
    . 'TestDrive:\script.ps1'

    ################
    #  TEST START  #
    ################

    $guid = (New-Guid).Guid

    context "RefreshPathVariable" {
        it "returns something" {
            [HubotHelpers]::new().RefreshPathVariable() | Should Not Be Null
        }

        it "return should contain atleast one semicolon" {
            [HubotHelpers]::new().RefreshPathVariable() | Should BeLike "*;*"
        }

        it "when split into array should have 2 or more items" {
            $array = [HubotHelpers]::new().RefreshPathVariable() -split ';'
            $array.Count | Should BeGreaterThan 1
        }
    }

    context "CheckPathExists" {
        it "returns true when path that exists is passed" {
            [HubotHelpers]::new().CheckPathExists("TestDrive:\") | Should Be $true
        }
        it "returns false when path that does not exist is passed" {          
            [HubotHelpers]::new().CheckPathExists("TestDrive:\$($guid)") | Should Be $false
        }
    }
}

Set-Location $originalLocation