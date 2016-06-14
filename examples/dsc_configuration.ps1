configuration Hubot
{
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Name MSFT_xRemoteFile -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName Hubot

    node $AllNodes.Where{$_.Role -eq "Hubot"}.NodeName
    {
        Environment hubotslackadapter
        {
            Name = 'HUBOT_ADAPTER'
            Value = 'slack'
            Ensure = 'Present'
        }

        Environment hubotdebug
        {
            Name = 'HUBOT_LOG_LEVEL'
            Value = 'debug'
            Ensure = 'Present'
        }

        Environment hubotslacktoken
        {
            Name = 'HUBOT_SLACK_TOKEN'
            Value = 'xoxb-XXXXXXXXXXX-XXXXXXXXXXXXXXXXXXXXXX'
            Ensure = 'Present'
        }

        HubotPrerequisites installPreqs
        {
            ChocolateyInstallPath = 'C:\choco'
        }

        # Download the HubotWindows Repo
        xRemoteFile hubotRepo
        {
            DestinationPath = "$($env:Temp)\HubotWindows.zip"
            Uri = "https://github.com/MattHodge/HubotWindows/releases/download/0.0.1/HubotWindows-0.0.1.zip"
        }

        # Extract the Hubot Repo
        Archive extractHubotRepo
        {
            Path = "$($env:Temp)\HubotWindows.zip"
            Destination = "C:\myhubot"
            Ensure = 'Present'
            DependsOn = '[xRemoteFile]hubotRepo'
        }

        HubotInstall installHubot
        {
            BotPath = 'C:\myhubot'
            Ensure = 'Present'
            DependsOn = '[Archive]extractHubotRepo'
        }

        HubotInstallService myhubotservice
        {
            BotPath = 'C:\myhubot'
            ServiceName = 'Hubot_Bender'
            BotAdapter = 'slack'
            Ensure = 'Present'
            DependsOn = '[HubotPrerequisites]installPreqs'
        }

        Service modifyHubotService
        {
            Name = 'Hubot_Bender'
            Description = 'Bender Hubot Bot'
            Ensure = 'Present'
            StartupType = 'Automatic'
            State = 'Running'
            DependsOn = '[HubotInstallService]myhubotservice'
        }
    }
}

$configData = @{
AllNodes = @(
    @{
        NodeName = 'localhost';
        PSDscAllowPlainTextPassword = $true
        Role = 'Hubot'
        }
    )
}
