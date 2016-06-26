properties {
    $unitTests = "$PSScriptRoot\Tests\unit"
    $integrationTests = "$PSScriptRoot\Tests\integration"
    $DSCResources = Get-ChildItem *.psd1,*.psm1 -Recurse

    # originalPath is the one containing the .psm1 and .psd1
    $originalPath = $PSScriptRoot

    # pathInModuleDir is the path where the symbolic link will be created which points to your repo
    $pathInModuleDir = 'C:\Program Files\WindowsPowerShell\Modules\Hubot'
}

task default -depends Analyze, Test, IntegrationDeploy, IntegrationTest

task TestProperties { 
  Assert ($build_version -ne $null) "build_version should not be null"
}

task Analyze {
    ForEach ($resource in $DSCResources)
    {      
        try
        {
            Write-Output "Running ScriptAnalyzer on $($resource)"

            if ($env:APPVEYOR)
            {
                Add-AppveyorTest -Name "PsScriptAnalyzer" -Outcome Running
                $timer = [System.Diagnostics.Stopwatch]::StartNew()
            }

            $saResults = Invoke-ScriptAnalyzer -Path $resource.FullName -Verbose:$false
            if ($saResults) {
                $saResults | Format-Table
                $saResultsString = $saResults | Out-String
                if ($saResults.Severity -contains 'Error' -or $saResults.Severity -contains 'Warning')
                {
                    if ($env:APPVEYOR)
                    {
                        Add-AppveyorMessage -Message "PSScriptAnalyzer output contained one or more result(s) with 'Error or Warning' severity.`
                        Check the 'Tests' tab of this build for more details." -Category Error
                        Update-AppveyorTest -Name "PsScriptAnalyzer" -Outcome Failed -ErrorMessage $saResultsString                  
                    }               

                    Write-Error -Message "One or more Script Analyzer errors/warnings where found in $($resource). Build cannot continue!"  
                }
                else
                {
                    Write-Output "All ScriptAnalyzer tests passed"

                    if ($env:APPVEYOR)
                    {
                        Update-AppveyorTest -Name "PsScriptAnalyzer" -Outcome Passed -StdOut $saResultsString -Duration $timer.ElapsedMilliseconds
                    }
                }
            }
        }
        catch
        {
            $ErrorMessage = $_.Exception.Message
            $FailedItem = $_.Exception.ItemName
            Write-Output $ErrorMessage
            Write-Output $FailedItem
            Write-Error "The build failed when working with $($resource)."
        }

    } 
}

task Test {
    $testResults = .\Tests\appveyor.pester.ps1 -Test -TestPath $unitTests
    # $testResults = Invoke-Pester -Path $unitTests -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester unit tests failed. Build cannot continue!'
    }
}

task IntegrationDeploy -depends Analyze, Test {
    try
    {
        New-Item -ItemType SymbolicLink -Path $pathInModuleDir -Target $originalPath -Force   
        
        . $PSScriptRoot\Examples\dsc_configuration.ps1

        Write-Verbose "Generating mof and putting it in $($PSScriptRoot)\mof"
        Hubot -ConfigurationData $configData -OutputPath "$($PSScriptRoot)\mof" -ErrorAction Stop

        if ($env:APPVEYOR)
        {
            Get-Module -Name *

            Get-DscResource
            
            Start-DscConfiguration -Path "$($PSScriptRoot)\mof" -Wait -Force -Verbose -ErrorAction Stop
        }
    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Output $ErrorMessage
        Write-Output $FailedItem
        throw "The build failed when trying to generate mof."
    }

    finally
    {
        Remove-Item -Path $pathInModuleDir -Force -Recurse
    }
}

task IntegrationTest -depends Analyze, Test, IntegrationDeploy {
    if ($env:APPVEYOR)
    {
        $testResults = .\Tests\appveyor.pester.ps1 -Test -TestPath $integrationTests
        if ($testResults.FailedCount -gt 0) {
            $testResults | Format-List
            Write-Error -Message 'One or more Pester integration tests failed. Build cannot continue!'
        }  
    }
    else
    {
        Write-Output "Not doing integration testing as this is not Appveyor"
    }
}