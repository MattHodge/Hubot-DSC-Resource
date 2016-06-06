configuration Hubot
{
    param (
    
        [Parameter(Mandatory=$true)] 
        [ValidateNotNullorEmpty()] 
        [PsCredential] $HubotAccount 
    
    )    

    Import-DscResource -ModuleName PSDesiredStateConfiguration
    Import-DscResource -ModuleName @{ 'ModuleName' = 'Hubot' ; ModuleVersion = '1.1' }

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
            Value = 'XXXX'
            Ensure = 'Present'
        }
          
        User hubotuser
        {
            UserName = $HubotAccount.UserName
            Ensure = 'Present'
            Password = $HubotAccount
            Disabled = $false
            PasswordNeverExpires = $true
            PasswordChangeRequired = $false
        }

        # To Do - deploy from a source to C:\myhubot2 (Git, File.. )

        HubotInstall installHubot
        {
            BotPath = 'C:\myhubot2'
            Ensure = 'Present'
        }

        HubotPrerequisites installPreqs
        {
            ChocolateyInstallPath = 'C:\choco'
        }

        HubotInstallService myhubotservice
        {
            BotPath = 'C:\myhubot2'
            ServiceName = 'Hubot_Bender'
            BotAdapter = 'slack'
            Ensure = 'Present'
            DependsOn = '[HubotPrerequisites]installPreqs'
        }

        Service modifyHubotService
        {
            Name = 'Hubot_Bender'
            Credential = $HubotAccount
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

#$secpasswd = ConvertTo-SecureString 'MyPassword101!' -AsPlainText -Force
#$HubotAccount = New-Object System.Management.Automation.PSCredential ('Hubot', $secpasswd)

#Hubot -ConfigurationData $configData -HubotAccount $HubotAccount -OutputPath C:\temp\

#Start-DscConfiguration -Path C:\temp -Wait -Force -Verbose