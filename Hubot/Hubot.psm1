# Defines the values for the resource's Ensure property.
enum Ensure
{
    # The resource must be absent.
    Absent
    # The resource must be present.
    Present
}

[DscResource()]
class HubotInstall
{

    # A DSC resource must define at least one key property.
    [DscProperty(Key)]
    [string]$BotPath
       
    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    # Sets the desired state of the resource.
    [void] Set()
    {
        Write-Verbose -Message "Reloading Path Enviroment Variables"
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        $nodeModulesPath = Join-Path -Path $this.BotPath -ChildPath 'node_modules'
 
        if ($this.Ensure -eq [Ensure]::Present)
        {
            $npmCmd = 'install'
        }
        else
        {
            $npmCmd = 'uninstall'
        }

        Write-Verbose -Message "$($npmCmd)ing CoffeeScript"
        #Start-Process -FilePath npm -ArgumentList "$($npmCmd) -g coffee-script" -Wait -NoNewWindow
        Start-Process -FilePath npm -ArgumentList "$($npmCmd) coffee-script" -Wait -NoNewWindow -WorkingDirectory $this.BotPath
        
        Write-Verbose "$($npmCmd)ing all required npm modules"
        Start-Process -FilePath npm -ArgumentList "$($npmCmd)" -Wait -NoNewWindow -WorkingDirectory $this.BotPath

        if ($this.Ensure -eq [Ensure]::Absent)
        {
            Remove-Item -Path $nodeModulesPath -Force
        }
    }

    # Tests if the resource is in the desired state.
    [bool] Test()
    {   
        $nodeModulesPath = Join-Path -Path $this.BotPath -ChildPath 'node_modules'
        
        # present case
        if ($this.Ensure -eq [Ensure]::Present)
        {
            if (Test-Path -Path $nodeModulesPath)
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
            if (Test-Path -Path $nodeModulesPath)
            {
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
            BotConfigPath = $this.BotPath
            Ensure = $this.Ensure
        }
    }
}

[DscResource()]
class HubotInstallService
{

    # Path where the Hubot is located
    [DscProperty(Key)]
    [string]$BotPath
       
    # Name for the Hubot service
    [DscProperty(Mandatory)]
    [string]$ServiceName

    # Bot adapter for Hubot to be used. Used as a paramater to start the server (-a $botadapter)
    [DscProperty(Mandatory)]
    [string]$BotAdapter

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [void] Set()
    {
        Write-Verbose -Message "Reloading Path Enviroment Variables"
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

        if ($this.Ensure -eq [Ensure]::Present)
        {
            
            $botLogPath = Join-Path -Path $this.BotPath -ChildPath 'Logs'
            Write-Verbose "Creating bot logging path at $($botLogPath)"
            New-Item -Path $botLogPath -Force -ItemType Directory
            
            Write-Verbose "Installing Bot Service $($this.ServiceName)"
            Start-Process -FilePath nssm.exe -ArgumentList "install $($this.ServiceName) node" -Wait -NoNewWindow
            Start-Process -FilePath nssm.exe -ArgumentList "set $($this.ServiceName) AppDirectory $($this.BotPath)" -Wait -NoNewWindow
            Start-Process -FilePath nssm.exe -ArgumentList "set $($this.ServiceName) AppParameters "".\node_modules\coffee-script\bin\coffee .\node_modules\hubot\bin\hubot -a $($this.BotAdapter)""" -Wait -NoNewWindow
            Start-Process -FilePath nssm.exe -ArgumentList "set $($this.ServiceName) AppStdout ""$($botLogPath)\$($this.ServiceName)_log.txt""" -Wait -NoNewWindow
            Start-Process -FilePath nssm.exe -ArgumentList "set $($this.ServiceName) AppStderr ""$($botLogPath)\$($this.ServiceName)_error.txt""" -Wait -NoNewWindow
            Start-Process -FilePath nssm.exe -ArgumentList "set $($this.ServiceName) AppRotateFiles 1" -Wait -NoNewWindow
            Start-Process -FilePath nssm.exe -ArgumentList "set $($this.ServiceName) AppRotateOnline 1" -Wait -NoNewWindow 
            Start-Process -FilePath nssm.exe -ArgumentList "set $($this.ServiceName) AppRotateSeconds 86400" -Wait -NoNewWindow
        }
        else
        {
            Write-Verbose "Removing Bot Service $($this.ServiceName)"
            Stop-Service -Name $this.ServiceName -Force -ErrorAction SilentlyContinue
            Start-Process -FilePath nssm.exe -ArgumentList "remove $($this.ServiceName) confirm" -Wait -NoNewWindow
        }
    }

    # Tests if the resource is in the desired state.
    [bool] Test()
    {   
        # present case
        if ($this.Ensure -eq [Ensure]::Present)
        {
            if (Get-Service -Name $this.ServiceName -ErrorAction SilentlyContinue)
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
            if (Get-Service -Name $this.ServiceName -ErrorAction SilentlyContinue)
            {
                return $false
            }
            else
            {
                return $true
            }
        }
    }
    # Gets the resource's current state.
    [HubotInstallService] Get()
    {
        return @{
            BotPath = $this.BotPath
            ServiceName = $this.ServiceName
            BotAdapter = $this.BotAdapter
            Ensure = $this.Ensure
        }
    }
}