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
}
