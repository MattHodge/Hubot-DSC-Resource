# Defines the values for the resource's Ensure property.
enum Ensure
{
    # The resource must be absent.
    Absent
    # The resource must be present.
    Present
}

class HubotConfigHelper
{
    [psobject] LoadHubotConfig ([string] $configPath)
    {
        if (!(Test-Path -Path $configPath))
        {
            throw "Unable to find configuration file at $($configPath)"
        }
        
        # Load the PSHubot Config
        try
        {
            $Config = Get-Content -Path $configPath | ConvertFrom-Json
            Write-Verbose "Config loaded from $($configPath)"
            return $Config
        }
        catch
        {
            throw "Configuration file at $($configPath) cannot be converted from json"
        }
    }

    [System.Collections.ArrayList] GetExternalScripts ([string] $configPath)
    {
        $Config = $this.LoadHubotConfig($configPath)

        Write-Verbose "Loading external scripts from $($Config.BotExternalScriptsPath)"

        # Load the external scripts into an array
        [System.Collections.ArrayList]$externalScripts = Get-Content -Path $Config.BotExternalScriptsPath -Raw | ConvertFrom-Json

        return $externalScripts
    }

    [bool] ContainsExternalScript ([string] $configPath, [string]$Name)
    {
        # Load external scripts
        $externalScripts = $this.GetExternalScripts($configPath)

        if ($externalScripts -contains $Name)
        {
            Write-Verbose "External scripts contains $($Name)."
            return $true
        }
        else
        {
            Write-Verbose "External scripts does not contain $($Name)."
            return $false
        }
    }

    [bool] NpmInstallationOccured ([string] $configPath)
    {
        $Config = $this.LoadHubotConfig($configPath)
        
        # Check if NPM has been run
        $coffeeScriptNPM = Test-Path -Path "$($env:APPDATA)\npm\coffee"
        $foreverNPM = Test-Path -Path "$($env:APPDATA)\npm\forever"
        $yoNPM = Test-Path -Path "$($env:APPDATA)\npm\yo"

        # See if hubot has been installed
        $hubotInstall = Test-Path -Path "$($config.BotInstallPath)\package.json"


        if ($coffeeScriptNPM -and $foreverNPM -and $yoNPM -and $hubotInstall)
        {
            return $true
        }
        else
        {
            return $false
        }
    }
}

[DscResource()]
class HubotConfig
{

    # A DSC resource must define at least one key property.
    [DscProperty(Key)]
    [string]$BotConfigPath

    [DscProperty(Mandatory)]
    [string]$BotName

    [DscProperty(Mandatory)]
    [string]$BotInstallPath

    [DscProperty(Mandatory)]
    [string]$BotOwner

    [DscProperty(Mandatory)]
    [string]$BotAdapter

    [DscProperty(Mandatory)]
    [string]$BotDescription

    [DscProperty(Mandatory)]
    [string]$BotLogPath

    [DscProperty(Mandatory)]
    [bool]$BotLogDebug

    [DscProperty()]
    [hashtable]$BotEnvironmentVariables

    [DscProperty()]
    [string]$BotStartArgument

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    # Sets the desired state of the resource.
    [void] Set()
    {
        if ($this.Ensure -eq [Ensure]::Absent)
        {
            Remove-Item -Path $this.BotConfigPath -Force
        }
        else
        {
            # create folder to hold configuration file
            $folderToCreate = Split-Path -Path $this.BotConfigPath

            if (-not(Test-Path -Path $folderToCreate))
            {
                New-Item -Path $folderToCreate -ItemType directory | Out-Null
            }

            Write-Verbose $this.ToString()

            # Build Configs
            $config = @{}
            $config.BotConfigPath = $this.BotConfigPath
            $config.BotInstallPath = $this.BotInstallPath
            $config.BotAdapter = $this.BotAdapter
            $config.BotLogDebug = $this.BotLogDebug
            $config.BotDescription = $this.BotDescription
            $config.BotOwner = $this.BotOwner
            $config.BotLogPath = $this.BotLogPath
            $config.ArgumentList = "--adapter $($this.BotAdapter)"
            $config.BotExternalScriptsPath = "$($this.BotInstallPath)\external-scripts.json"
            $config.BotName = $this.BotName

            # Create a path to the pid file
            $config.PidPath = "$($this.BotInstallPath)\$($this.BotName).pid"

            # Add some environment variables
            $config.EnvironmentVariables += @{
                'HUBOT_ADAPTER' = $this.BotAdapter
            }

            # Add Extra Bot Environment Variables
            if ($this.BotEnvironmentVariables)
            {
                $config.EnvironmentVariables += $this.BotEnvironmentVariables
            }

            # Enable Debugging for Hubot
            if ($this.BotLogDebug)
            {
                $config.EnvironmentVariables += @{
                    'HUBOT_LOG_LEVEL' = 'debug'
                }
            }

            $json = $config | ConvertTo-Json

            Write-Verbose $json

            try
            {
                Set-Content -Path $this.BotConfigPath -Value $json
                Write-Verbose "PoshHubot Configuration saved to $($this.BotConfigPath)."
            }
            catch
            {
                throw "Error writing configuration file."
            }
        }
    }

    # Tests if the resource is in the desired state.
    [bool] Test()
    {
        if ($this.Ensure -eq [Ensure]::Absent)
        {
            # Bot config exists when it shouldn't
            if (Test-Path -Path $this.BotConfigPath)
            {
                Write-Verbose "Absent set but config file exists. DSC will run to delete the config file."
                return $false
            }
            # Bot config does not exist whe it shouldn't
            else
            {
                return $true
            }
        }
        else
        {
            # TO DO, Work out how to test this resource properly
            return $false
        }
    }
    # Gets the resource's current state.
    [HubotConfig] Get()
    {
        return @{
            BotName = $this.BotName
            Ensure = $this.Ensure
        }
    }
}

[DscResource()]
class HubotInstall
{

    # A DSC resource must define at least one key property.
    [DscProperty(Key)]
    [string]$BotConfigPath

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    # Sets the desired state of the resource.
    [void] Set()
    {
        # load helper functions
        $helper = [HubotConfigHelper]::new()
        
        # Load config
        $config = $helper.LoadHubotConfig($this.BotConfigPath)       

        Write-Verbose -Message "Reloading Path Enviroment Variables"
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

 
        if ($this.Ensure -eq [Ensure]::Present)
        {
            $npmCmd = 'install'

            # Create bot directory
            if (-not(Test-Path -Path $Config.BotInstallPath))
            {
                New-Item -Path $Config.BotInstallPath -ItemType Directory
            }
        }
        else
        {
            $npmCmd = 'uninstall'
            Remove-Item -Path $this.BotConfigPath -Force
        }

        Write-Verbose -Message "$($npmCmd)ing CoffeeScript"
        Start-Process -FilePath npm -ArgumentList "$($npmCmd) -g coffee-script" -Wait -NoNewWindow

        Write-Verbose -Message "$($npmCmd)ing Hubot Generator"
        Start-Process -FilePath npm -ArgumentList "$($npmCmd) -g yo generator-hubot" -Wait -NoNewWindow

        Write-Verbose -Message "$($npmCmd)ing Forever"
        Start-Process -FilePath npm -ArgumentList "$($npmCmd) -g forever" -Wait -NoNewWindow

        if ($this.Ensure -eq [Ensure]::Present)
        {
            Write-Verbose -Message "Generating Bot"
            Start-Process -FilePath yo -ArgumentList "hubot --owner=""$($Config.BotOwner)"" --name=""$($Config.BotName)"" --description=""$($Config.BotDescription)"" --adapter=""$($Config.BotAdapter)"" --no-insight" -NoNewWindow -Wait -WorkingDirectory $Config.BotInstallPath
        }
    }

    # Tests if the resource is in the desired state.
    [bool] Test()
    {
        # load helper functions
        $helper = [HubotConfigHelper]::new()     
        
        if ($this.Ensure -eq [Ensure]::Present)
        {
            if ($helper.NpmInstallationOccured($this.BotConfigPath))
            {
                return $true
            }
            else
            {
                return $false
            }
        }
        # absent case
        else
        {
            if ($helper.NpmInstallationOccured($this.BotConfigPath))
            {
                # if npm is install when it is meant to be absent, not in desired state
                return $false
            }
            else
            {
                return $true
            }
        }
    }
    # Gets the resource's current state.
    [HubotInstall] Get()
    {
        return @{
            BotConfigPath = $this.BotConfigPath
            Ensure = $this.Ensure
        }
    }
}

[DscResource()]
class HubotScript
{

    # A DSC resource must define at least one key property.
    [DscProperty(Key)]
    [string]$Name
        
    [DscProperty(Mandatory)]
    [string]$BotConfigPath

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [DscProperty()]
    [string]$NameInConfig


    # Sets the desired state of the resource.
    [void] Set()
    {
        # load helper functions
        $helper = [HubotConfigHelper]::new()

        # If NameInConfig is set use that as the name (some npm packages have different names than the actual files)
        if ($this.NameInConfig)
        {
            $NameInConfigFile = $this.NameInConfig
        }
        else
        {
            $NameInConfigFile = $this.Name
        }

        # Load config file
        $Config = $helper.LoadHubotConfig($this.BotConfigPath)
        
        # Load an array of the external scripts
        $externalScripts = $helper.GetExternalScripts($this.BotConfigPath)

        if ($this.Ensure -eq [Ensure]::Present)
        {
            $verboseMsg = "$($NameInConfigFile) added to external scripts"
            $npmCmd = 'install'
            $externalScripts.Add($NameInConfigFile)
        }
        else
        {
            $verboseMsg = "$($NameInConfigFile) removed from external scripts"
            $npmCmd = 'uninstall'
            $externalScripts.Remove($NameInConfigFile)
        }

        Write-Verbose $verboseMsg

        # building splat for npm command
        $spSplat = @{
            FilePath = 'npm'
            ArgumentList = "$($npmCmd) $($this.Name) --save"
            Wait = $true
            NoNewWindow = $true
            WorkingDirectory = $Config.BotInstallPath
        }

        Write-Verbose "Running npm $($npmCmd) $($this.Name) --save"
        Start-Process @spSplat 
        
        # saving the external scripts back to the file
        Set-Content -Path $config.BotExternalScriptsPath -Value ($externalScripts | ConvertTo-Json)
    }

    # Tests if the resource is in the desired state.
    [bool] Test()
    {
        # load helper functions
        $helper = [HubotConfigHelper]::new()        
        
        # If NameInConfig is set use that as the name (some npm packages have different names than the actual files)
        if ($this.NameInConfig)
        {
            $NameInConfigFile = $this.NameInConfig
        }
        else
        {
            $NameInConfigFile = $this.Name
        }

        Write-Verbose "Looking for a script with the name $($NameInConfigFile)."
             
        # Absent
        if ($this.Ensure -eq [Ensure]::Absent)
        {
            if ($helper.ContainsExternalScript($this.BotConfigPath, $NameInConfigFile))
            {
                return $false
            }
            else
            {
                return $true
            }
        }
        # Present
        else
        {
            if ($helper.ContainsExternalScript($this.BotConfigPath, $NameInConfigFile))
            {
                return $true
            }
            else
            {
                return $false
            }
        }
    }
    # Gets the resource's current state.
    [HubotScript] Get()
    {
        return @{
            BotConfigPath = $this.BotConfigPath
            Ensure = $this.Ensure
        }
    }
}

