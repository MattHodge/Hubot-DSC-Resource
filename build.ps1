properties {
    $vmsForProject = @('default-Win2016TP5-wmf5')
}

task default -depends test

task test {
   $testResults = Invoke-Pester -Script ..\TestKitchenHelper\kitchen.tests.ps1 -PassThru

    if ($testResults.FailedCount -gt 0) {
        $testResults | Format-List
        Write-Error -Message 'One or more Pester tests failed. Build cannot continue!'
    }
}

task create -depends test {
   kitchen create
}

task converge -depends test {
    ForEach ($vm in $vmsForProject)
    {
        Get-VM -Name $vm | Checkpoint-VM -SnapshotName "$(Get-date -Format s) From Build"
    }

    kitchen exec -c "powershell.exe -command '& {Restart-Service winmgmt -Force -Verbose}'"

    kitchen converge
}

task clean -depends test {
    kitchen destroy
}