describe "cHubotDSC" {

    it "C:\poshhubot folder is created" {
        Test-Path -Path 'C:\poshhubot' | Should Be $true
    }

    it "C:\poshhubot\config.json configuration file is created" {
        Test-Path -Path 'C:\poshhubot\config.json' | Should Be $true
    }

    it "configuration file is valid json" {
        { $x = Get-Content -Path 'C:\poshhubot\config.json' | ConvertFrom-Json -ErrorAction Stop } | Should Not Throw
    }
}
