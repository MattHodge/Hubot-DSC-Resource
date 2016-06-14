describe "Hubot" {
    
    $pathsToTest = @(
        'C:\Program Files\Git\bin\git.exe'
        'C:\Program Files\nodejs\node.exe'
        'C:\choco\bin\nssm.exe'
    )

    ForEach ($p in $pathsToTest)
    {
        it "$($p) exists" {
            Test-Path -Path $p | Should Be $true
        }
    }
}
