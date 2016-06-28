describe "Hubot DSC Module - MOF Testing" {

    context "Get-DSCResource" {
        $res = Get-DscResource
        
        it "returns something" {
            $res | Should Not Be Null
        }

        $hubotRes = @(
            'HubotInstall'
            'HubotInstallService'
            'HubotPrerequisites'
        )

        ForEach ($h in $hubotRes)
        {
            it "contains resource $($h)" {
                $res.Name -contains $h | Should Be $true
            }
        }
    }

    context "Example dsc_configuration" {
        it "is valid powershell" {
            $psfile = Get-Content -Path .\Examples\dsc_configuration.ps1 -Raw -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($psfile, [ref]$errors)
            $errors.Count | Should Be 0
        }

        . .\Examples\dsc_configuration.ps1

        it "module version of Hubot.psd1 matches module version in dsc_example.ps1" {
            $moduleVersion = Select-String -Path .\Hubot.psd1 -Pattern "ModuleVersion = '(.*)'"
            $moduleVersion = $moduleVersion.Matches.Groups[1].Value

            $exampleVersion = Select-String -Path .\Examples\dsc_configuration.ps1 -Pattern 'ModuleName=\"Hubot\"\; RequiredVersion=\"(.*)\"'
            $exampleVersion = $exampleVersion.Matches.Groups[1].Value

            $exampleVersion | Should BeExactly $moduleVersion
        }

        it "does not have a real api key" {
            $configData.AllNodes.SlackAPIKey | Should Be 'xoxb-XXXXXXXXXXXXXXXX-XXXXXXXXXXXXXXXX'
        }

        it "does not throw on mof generation" {
            { Hubot -OutputPath TestDrive:\mof -ConfigurationData $configData } | Should Not Throw
        }

        it "mof file is created on disk" {
            Test-Path -Path "TestDrive:\mof\localhost.mof" | Should Be $true
        }
    }
}
