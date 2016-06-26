using module "..\..\Hubot.psm1"

describe "Hubot DSC Module - Unit Testing" {
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

    context "HubotInstall" {
        it "does not throw" {
            { 
                $x = [HubotInstall]::new()
                $x.BotPath = 'C:\myhubot'
                $x.Ensure = 'Present'
                $x.Get() 
            } | Should Not Throw
        }

        it "returns a [HubotInstall] class" {
            $x = [HubotInstall]::new()
            $x.BotPath = 'TestDrive:\'
            $x.Ensure = 'Present'
            $x.Get().GetType().Name | Should Be 'HubotInstall'
        }

        it "returns ensure present if BotPath exists" {
            $fakeModuleFolder = Join-Path $TestDrive 'node_modules'
            New-Item -Path $fakeModuleFolder -ItemType Directory -Force
            $x = [HubotInstall]::new()
            $x.BotPath = $TestDrive
            $x.Get().Ensure | Should Be 'Present'
        }

        it "node modules path should be valid" {
            $fakeModuleFolder = Join-Path $TestDrive 'node_modules'
            New-Item -Path $fakeModuleFolder -ItemType Directory -Force
            $x = [HubotInstall]::new()
            $x.BotPath = $TestDrive
            $x.Get().NodeModulesPath | Should Be $fakeModuleFolder
        }

        it "returns ensure absent if BotPath does not exist" {
            $x = [HubotInstall]::new()
            $x.BotPath = "TestDrive:\$($guid)"
            $x.Get().Ensure | Should Be 'Absent'
        }


    }
}
