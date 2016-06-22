properties {
    $unitTests = "$PSScriptRoot\Tests\unit"
    $DSCResources = Get-ChildItem *.psd1,*.psm1 -Recurse
}

task default -depends Analyze, Test

task TestProperties { 
  Assert ($build_version -ne $null) "build_version should not be null"
}

task Analyze {
    ForEach ($resource in $DSCResources)
    {
        Write-Output "Running ScriptAnalyzer on $($resource)"
        $saResults = Invoke-ScriptAnalyzer -Path $resource.FullName -Verbose:$false
        if ($saResults) {
            $saResults | Format-Table
            if ($saResults.Severity -contains 'Error' -or $saResults.Severity -contains 'Warning')
            {
                Write-Error -Message "One or more Script Analyzer errors/warnings where found in $($resource). Build cannot continue!"  
            }
        }
    } 
}

task Test {
    $testResults = .\Tests\appveyor.pester.ps1 -Test -TestPath $unitTests
    # $testResults = Invoke-Pester -Path $unitTests -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
    }
}

<#
task Deploy -depends Analyze, Test {
    Invoke-PSDeploy -Path '.\ServerInfo.psdeploy.ps1' -Force -Verbose:$VerbosePreference
}
#>