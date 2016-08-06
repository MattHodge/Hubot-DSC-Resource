properties {
    # $unitTests = "$PSScriptRoot\Tests\unit"
    $unitTests = Get-ChildItem .\Tests\*Unit_Tests.ps1
    $mofTests = Get-ChildItem .\Tests\*MOF_Generation_Tests.ps1
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
    ForEach ($unitTest in $unitTests)
    {
        $testResults = .\Tests\appveyor.pester.ps1 -Test -TestPath $unitTest

        if ($testResults.FailedCount -gt 0) {
            $testResults | Format-List
            Write-Error -Message 'One or more Pester unit tests failed. Build cannot continue!'
        }
    }
}

task MOFTestDeploy -depends Analyze, Test {
    try
    {
        if ($env:APPVEYOR)
        {
            # copy into the userprofile in appveyor so the module can be loaded
            Start-Process -FilePath 'robocopy.exe' -ArgumentList "$PSScriptRoot $env:USERPROFILE\Documents\WindowsPowerShell\Modules\Hubot /S /R:1 /W:1" -Wait -NoNewWindow
        }
        else
        {
            # on a local system just create a symlink
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
}

task MOFTest -depends Analyze, Test, MOFTestDeploy {
    ForEach ($moftest in $mofTests)
    {
        $testResults = .\Tests\appveyor.pester.ps1 -Test -TestPath $moftest
        if ($testResults.FailedCount -gt 0) {
            $testResults | Format-List
            Write-Error -Message 'One or more Pester unit tests failed. Build cannot continue!'
        }
    }
}

task BuildArtifact -depends Analyze, Test, MOFTestDeploy, MOFTest {
    # Create a clean to build the artifact
    New-Item -Path "$PSScriptRoot\Artifact" -ItemType Directory -Force

    # Copy the correct items into the artifacts directory, filtering out the junk
    Start-Process -FilePath 'robocopy.exe' -ArgumentList "`"$($PSScriptRoot)`" `"$($PSScriptRoot)\Artifact\Hubot`" /S /R:1 /W:1 /XD Artifact .kitchen .git /XF .gitignore build.ps1 psakeBuild.ps1 *.yml *.xml" -Wait -NoNewWindow

    # Create a zip file artifact
    Compress-Archive -Path $PSScriptRoot\Artifact\Hubot -DestinationPath $PSScriptRoot\Artifact\Hubot-$build_version.zip -Force

    if ($env:APPVEYOR)
    {
        # Push the artifact into appveyor
        $zip = Get-ChildItem -Path $PSScriptRoot\Artifact\*.zip |  % { Push-AppveyorArtifact $_.FullName -FileName $_.Name }
    }
}