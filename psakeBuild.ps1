properties {
    $unitTests = "$PSScriptRoot\Tests\unit"
    $MOFTests = "$PSScriptRoot\Tests\mof"
    $DSCResources = Get-ChildItem *.psd1,*.psm1 -Recurse

    # originalPath is the one containing the .psm1 and .psd1
    $originalPath = $PSScriptRoot

    # pathInModuleDir is the path where the symbolic link will be created which points to your repo
    $pathInModuleDir = 'C:\Program Files\WindowsPowerShell\Modules\Hubot'
}

task default -depends Analyze, Test, MOFTestDeploy, MOFTest, BuildArtifact

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

task MOFTestDeploy -depends Analyze, Test {
    try
    {
        if ($env:APPVEYOR)
        {
            Start-Process -FilePath 'robocopy.exe' -ArgumentList "$PSScriptRoot $env:USERPROFILE\Documents\WindowsPowerShell\Modules\Hubot /S /R:1 /W:1" -Wait -NoNewWindow
        }
        else
        {
            New-Item -ItemType SymbolicLink -Path $pathInModuleDir -Target $originalPath -Force | Out-Null
        }
    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Output $ErrorMessage
        Write-Output $FailedItem
        throw "The build failed when trying prepare files for MOF tests."
    }

    finally
    {
        #Remove-Item -Path $pathInModuleDir -Force -Recurse
    }
}

task MOFTest -depends Analyze, Test, MOFTestDeploy {
    $testResults = .\Tests\appveyor.pester.ps1 -Test -TestPath $MOFTests
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester unit tests failed. Build cannot continue!'
    }
}

task BuildArtifact -depends Analyze, Test, MOFTestDeploy, MOFTest {
    New-Item -Path "$PSScriptRoot\Artifact" -ItemType Directory -Force
    Start-Process -FilePath 'robocopy.exe' -ArgumentList "`"$($PSScriptRoot)`" `"$($PSScriptRoot)\Artifact\Hubot`" /S /R:1 /W:1 /XD Artifact .kitchen .git /XF .gitignore build.ps1 psakeBuild.ps1 *.yml" -Wait -NoNewWindow
    Compress-Archive -Path $PSScriptRoot\Artifact\Hubot -DestinationPath $PSScriptRoot\Artifact\Hubot-$build_version.zip -Force

    if ($env:APPVEYOR)
    {
        Get-ChildItem -Path $PSScriptRoot\Artifact\*.zip | Push-AppveyorArtifact
    }
}