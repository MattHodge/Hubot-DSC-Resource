configuration Hubot
{

    Import-DscResource -ModuleName cChoco
    Import-DscResource -ModuleName cHubotDSC

    # One can evaluate expressions to get the node list
    # E.g: $AllNodes.Where('Role -eq Web').NodeName
    node localhost
    {
        cDSCHubotConfig asda
        {
            BotConfigPath = 'C:\PoshHubot\config.json'
            BotName = 'bender'
            BotInstallPath = 'C:\myhubot'
            BotAdapter = 'slack'
            BotOwner = 'Matt <matt@hodge.com>'
            BotDescription = 'My Awesome Bot'
            BotLogPath = 'C:\PoshHubot\Logs'
            BotLogDebug = $true
            BotEnvironmentVariables = @{
                Test = 'ASDaSdaSDaSD'
            }
            Ensure = 'Present'
        }


        cChocoInstaller installChoco
        {
            InstallDir = "c:\choco"
        }

        cChocoPackageInstaller installGit
        {
            Name = "git.install"
            DependsOn = "[cChocoInstaller]installChoco"
        }

        cChocoPackageInstaller installNode
        {
            Name = "nodejs.install"
            Version = "5.10.1"
            DependsOn = "[cChocoInstaller]installChoco"
        }

        cDSCHubotInstall installHubot
        {
            BotConfigPath = 'C:\PoshHubot\config.json'
            Ensure = 'Present'
            DependsOn = "[cChocoPackageInstaller]installNode"
        }

        cDSCHubotScript removeRedisBrain
        {
            BotConfigPath = 'C:\PoshHubot\config.json'
            Name = 'hubot-redis-brain'
            Ensure = 'Absent'
            DependsOn = "[cChocoPackageInstaller]installNode"
        }

        cDSCHubotScript removeHerokuKeepalive
        {
            BotConfigPath = 'C:\PoshHubot\config.json'
            Name = 'hubot-heroku-keepalive'
            Ensure = 'Absent'
            DependsOn = "[cChocoPackageInstaller]installNode"
        }

        cDSCHubotScript addAzureScripts
        {
            BotConfigPath = 'C:\PoshHubot\config.json'
            Name = 'hubot-azure-scripts'
            NameInConfig = 'hubot-azure-scripts/brain/storage-blob-brain'
            Ensure = 'Present'
            DependsOn = "[cChocoPackageInstaller]installNode"
        }
    }
}

#Hubot -OutputPath .
#Start-DscConfiguration -Path C:\dsc -Verbose -Wait
