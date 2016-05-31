using module ..\Hubot\Hubot.psm1

describe "Hubot DSC Module - Unit Testing" {

    context "HubotConfigHelper" {
        it "LoadHubotConfig throws when the config file passed doesn't exist" {
            {
                $myClass = [HubotConfigHelper]::new()
                $myClass.LoadHubotConfig('X:\fake_text_file.config')
            } | Should throw
        }
    }

}
