describe "Hubot" {

    Context "File Paths and Installs" {
        $pathsToTest = @(
            'C:\Program Files\Git\bin\git.exe'
            'C:\Program Files\nodejs\node.exe'
            'C:\ProgramData\chocolatey\bin\nssm.exe'
            'C:\myhubot'
            'C:\myhubot\node_modules'
            'C:\myhubot\node_modules\edge'
            'C:\myhubot\node_modules\edge-ps'
            'C:\myhubot\node_modules\coffee-script'
        )

        ForEach ($p in $pathsToTest)
        {
            it "$($p) exists" {
                Test-Path -Path $p | Should Be $true
            }
        }
    }

    Context "Environment Variables" {
        $envVarsToTest = @(
            'HUBOT_ADAPTER'
            'HUBOT_LOG_LEVEL'
            'HUBOT_SLACK_TOKEN'
        )

        ForEach ($e in $envVarsToTest)
        {
            It "environment variable $($e) should exist" {
                Test-Path -Path "Env:\$($e)" | Should Be $true
            }

        }
    }

    Context "Hubot Service" {        
        It "should exist" {
            { Get-Service -Name Hubot_bender } | Should Not throw
        }
        It "should be running" {
            (Get-Service -Name Hubot_bender).Status | Should BeExactly 'Running'
        }

        $svc = Get-WMIObject -Class Win32_Service -Filter  "Name='hubot_bender'" | Select-Object *

        It "should have a description of Hubot Service" {
            $svc.Description | Should BeExactly 'Hubot Service' 
        }
        It "should be running under Hubot account" {
            $svc.StartName | Should BeExactly '.\Hubot' 
        }
        It "should have a startmode of Auto" {
            $svc.StartMode | Should BeExactly 'Auto'
        }

    }
}