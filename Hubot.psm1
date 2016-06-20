# TO DO
# - Make class for calling NPM Install
# - Make class for getting service state
# - Make it retur HubotInstall object and HubotInstallService object
# - Fix Script Analyiser Warnings

# Defines the values for the resource's Ensure property.
enum Ensure
{
    # The resource must be absent.
    Absent
    # The resource must be present.
    Present
}

class HubotHelpers
{
    [string] RefreshPathVariable ()
    {
        $updatedPath = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        return $updatedPath
    }

    [bool] CheckPathExists ([string]$Path)
    {
        if (Test-Path -Path $Path)
        {
            Write-Verbose "Directory $($Path) exists."
            return $true
        }
        else
        {
            Write-Verbose "Directory $($Path) exists."
            return $false
        }
    }
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
        $env:Path = [HubotHelpers]::new().RefreshPathVariable()

        $nodeModulesPath = Join-Path -Path $this.BotPath -ChildPath 'node_modules'

        if (!(Test-Path -Path $this.BotPath))
        {
            throw "The path $($this.BotPath) must exist and contain a Hubot installation in it. You can clone one from here: https://github.com/MattHodge/HubotWindows"
        }


        if ($this.Ensure -eq [Ensure]::Present)
        {
            $npmCmd = 'install'
        }
        else
        {
            $npmCmd = 'uninstall'
        }

        Write-Verbose -Message "$($npmCmd)ing CoffeeScript at $($this.BotPath)"

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
            return [HubotHelpers]::new().CheckPathExists($nodeModulesPath)
        }
        # absent case
        else
        {
            return (![HubotHelpers]::new().CheckPathExists($nodeModulesPath))
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

    # Credential to run the service under
    [DscProperty()]
    [PSCredential]$Credential

    # Bot adapter for Hubot to be used. Used as a paramater to start the server (-a $botadapter)
    [DscProperty(Mandatory)]
    [string]$BotAdapter

    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    [void] Set()
    {
        if (Get-Command -CommandType Application -Name nssm -ErrorAction SilentlyContinue)
        {
            $nssmPath = (Get-Command -CommandType Application -Name nssm).Source
        }
        else
        {
            throw "nssm.exe cannot be found. Cannot continue. Have you run the HubotInstall resource?"
        }

        $env:Path = [HubotHelpers]::new().RefreshPathVariable()

        if ($this.Ensure -eq [Ensure]::Present)
        {
            if (Get-Service -Name $this.ServiceName -ErrorAction SilentlyContinue)
            {
                Write-Verbose "Removing old service"
                Stop-Service -Name $this.ServiceName -Force
                Start-Process -FilePath $nssmPath -ArgumentList "remove $($this.ServiceName) confirm" -Wait -NoNewWindow
            }
            $botLogPath = Join-Path -Path $this.BotPath -ChildPath 'Logs'
            Write-Verbose "Creating bot logging path at $($botLogPath)"
            New-Item -Path $botLogPath -Force -ItemType Directory

            Write-Verbose "Installing Bot Service $($this.ServiceName)"
            Start-Process -FilePath $nssmPath -ArgumentList "install $($this.ServiceName) node" -Wait -NoNewWindow
            Start-Process -FilePath $nssmPath -ArgumentList "set $($this.ServiceName) AppDirectory $($this.BotPath)" -Wait -NoNewWindow
            Start-Process -FilePath $nssmPath -ArgumentList "set $($this.ServiceName) AppParameters "".\node_modules\coffee-script\bin\coffee .\node_modules\hubot\bin\hubot -a $($this.BotAdapter)""" -Wait -NoNewWindow
            Start-Process -FilePath $nssmPath -ArgumentList "set $($this.ServiceName) AppStdout ""$($botLogPath)\$($this.ServiceName)_log.txt""" -Wait -NoNewWindow
            Start-Process -FilePath $nssmPath -ArgumentList "set $($this.ServiceName) AppStderr ""$($botLogPath)\$($this.ServiceName)_error.txt""" -Wait -NoNewWindow
            Start-Process -FilePath $nssmPath -ArgumentList "set $($this.ServiceName) AppRotateFiles 1" -Wait -NoNewWindow
            Start-Process -FilePath $nssmPath -ArgumentList "set $($this.ServiceName) AppRotateOnline 1" -Wait -NoNewWindow
            Start-Process -FilePath $nssmPath -ArgumentList "set $($this.ServiceName) AppRotateSeconds 86400" -Wait -NoNewWindow
            Start-Process -FilePath $nssmPath -ArgumentList "set $($this.ServiceName) Description Hubot Service" -Wait -NoNewWindow
            Start-Process -FilePath $nssmPath -ArgumentList "set $($this.ServiceName) Start SERVICE_AUTO_START" -Wait -NoNewWindow

            # if a credetial is passed with no password assume LocalSystem
            if ([string]::IsNullOrEmpty($this.Credential.UserName))
            {
                Write-Verbose "No credential passed, using LocalSystem."
                Start-Process -FilePath $nssmPath -ArgumentList "set $($this.ServiceName) ObjectName LocalSystem" -Wait -NoNewWindow
            }
            # if a credential is passed with a password
            else
            {
                Write-Verbose "Credential passed, using username $($this.Credential.UserName)."
                Start-Process -FilePath $nssmPath -ArgumentList "set $($this.ServiceName) ObjectName .\$($this.Credential.UserName) $($this.Credential.GetNetworkCredential().Password)" -Wait -NoNewWindow
            }
            
            Start-Service -Name $this.ServiceName
        }
        else
        {
            Write-Verbose "Removing Bot Service $($this.ServiceName)"
            Stop-Service -Name $this.ServiceName -Force -ErrorAction SilentlyContinue
            Start-Process -FilePath $nssmPath -ArgumentList "remove $($this.ServiceName) confirm" -Wait -NoNewWindow
        }
    }

    # Tests if the resource is in the desired state.
    [bool] Test()
    {
        # present case
        if ($this.Ensure -eq [Ensure]::Present)
        {
            # array to store stat
            $states = @()
            
            if (Get-Service -Name $this.ServiceName -ErrorAction SilentlyContinue)
            {
                $states += $true

                if ((Get-Service -Name $this.ServiceName).Status -eq 'Running')
                {
                    $states += $true
                }
                else
                {
                    $states += $false
                }
            }
            else
            {
                $states += $false
            }

            if ($states -notcontains $false)
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
