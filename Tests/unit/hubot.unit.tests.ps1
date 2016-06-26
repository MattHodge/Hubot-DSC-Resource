using module "..\..\Hubot.psm1"

describe "Hubot DSC Module - Unit Testing" {

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
            [HubotHelpers]::new().CheckPathExists($TestDrive) | Should Be $true
        }
        it "returns false when path that does not exist is passed" {
            $guid = (New-Guid).Guid
            
            [HubotHelpers]::new().CheckPathExists("$($TestDrive)\$($guid)") | Should Be $false
        }
    }
}
