configuration Hubot
{   
    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -Name MSFT_xRemoteFile -ModuleName xPSDesiredStateConfiguration
    Import-DscResource -ModuleName Hubot

    node $AllNodes.Where{$_.Role -eq "Hubot"}.NodeName
    {
        # Create a user to install prereqs under and run the hubot service
        User Hubot
        {
            UserName = $Node.HubotUserCreds.UserName
            Password = $Node.HubotUserCreds
            Ensure = 'Present'
            PasswordNeverExpires = $true
            PasswordChangeRequired = $false
        }
        
        # Create a user to install prereqs under and run the hubot service
        Group HubotUser
        {
            GroupName = 'Administrators'
            MembersToInclude = $Node.HubotUserCreds.UserName
            Ensure = 'Present'
            DependsOn = "[User]Hubot"
        }
        
        
        Environment hubotadapter
        {
            Name = 'HUBOT_ADAPTER'
            Value = $Node.HubotAdapter
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
            Value = $Node.SlackAPIKey
            Ensure = 'Present'
        }

        # Install the Prereqs using the same Hubot user
        HubotPrerequisites installPreqs
        {
            ChocolateyInstallPath = 'C:\choco'
            PsDscRunAsCredential = $Node.HubotUserCreds
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
            Destination = $Node.HubotBotPath
            Ensure = 'Present'
            DependsOn = '[xRemoteFile]hubotRepo'
        }

        HubotInstall installHubot
        {
            BotPath = $Node.HubotBotPath
            Ensure = 'Present'
            DependsOn = '[Archive]extractHubotRepo'

        }

        HubotInstallService myhubotservice
        {
            BotPath = $Node.HubotBotPath
            ServiceName = "Hubot_$($Node.HubotBotName)"
            BotAdapter = $Node.HubotAdapter
            Ensure = 'Present'
            DependsOn = '[HubotPrerequisites]installPreqs'
        }

        Service modifyHubotService
        {
            Name = "Hubot_$($Node.HubotBotName)"
            Description = "$($Node.HubotBotName) Hubot Bot"
            Ensure = 'Present'
            StartupType = 'Automatic'
            State = 'Running'
            DependsOn = '[HubotInstallService]myhubotservice'
            Credential = $Node.HubotUserCreds
        }
    }
}

# Create Hubot Credentials (save having to enter them every time - don't do this for production!)
$hubotUserPass = ConvertTo-SecureString 'MyPASSWORD!' -AsPlainText -Force
$hubotUserCreds = New-Object System.Management.Automation.PSCredential ('Hubot', $hubotUserPass)


$configData = @{
AllNodes = @(
        @{
            NodeName = 'localhost';
            PSDscAllowPlainTextPassword = $true
            Role = 'Hubot'
            HubotUserCreds = $hubotUserCreds
            SlackAPIKey = 'xoxb-XXXXXXXXX-XXXXXXXXXXXXXXXXXXXXX'
            HubotAdapter = 'slack'
            HubotBotName = 'bender'
            HubotBotPath = 'C:\myhubot'
        }
    )
}