properties {
    $unitTests = "$PSScriptRoot\Tests\unit"
    $integrationTests = "$PSScriptRoot\Tests\integration"
    $DSCResources = Get-ChildItem *.psd1,*.psm1 -Recurse
}

task default -depends Analyze, Test, IntegrationDeploy

task TestProperties { 
  Assert ($build_version -ne $null) "build_version should not be null"
}

task Analyze {
    ForEach ($resource in $DSCResources)
    {
        try
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
        . $PSScriptRoot\Examples\dsc_configuration.ps1

        Write-Verbose "Generating mof and putting it in $($PSScriptRoot)\mof"
        Hubot -ConfigurationData $configData -OutputPath "$($PSScriptRoot)\mof"

        Start-DscConfiguration -Path "$($PSScriptRoot)\mof" -Wait -Force -Verbose
    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
        $FailedItem = $_.Exception.ItemName
        Write-Output $ErrorMessage
        Write-Output $FailedItem
        Write-Error "The build failed when trying to generate mof."
    }
}

task IntegrationTEst -depends Analyze, Test, IntegrationDeploy
{
    $testResults = .\Tests\appveyor.pester.ps1 -Test -TestPath $integrationTests
    # $testResults = Invoke-Pester -Path $unitTests -PassThru
    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester integration tests failed. Build cannot continue!'
    }  
}