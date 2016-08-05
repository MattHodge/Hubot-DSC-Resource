# Hubot (DSC Resource)

![Hubot](http://i.imgur.com/NhTqeZ2.png)

[![Build status](https://ci.appveyor.com/api/projects/status/kjweb2q53xa3198h?svg=true)](https://ci.appveyor.com/project/MattHodge/hubot-dsc-resource)

The **Hubot** module contains the `HubotPrerequisites`, `HubotInstall` and `HubotInstallService` DSC Resources to install Hubot on Windows.

This resource installs and runs Hubot as a service on Windows using NSSM.

I recommend using the [HubotWindows](https://github.com/MattHodge/HubotWindows) repository to get the Hubot setup on your node and use the following DSC resources to configure it.

For an introduction to using Hubot on Windows, take a look at [ChatOps on Windows with Hubot and PowerShell](https://hodgkins.io/chatops-on-windows-with-hubot-and-powershell).

## Resources

### HubotPrerequisites

Parameter | Notes |  Mandatory
| --- | --- | --- |
Ensure | Ensures that the prerequisites is Present or Absent | `Yes`

### HubotInstall

Parameter | Notes |  Mandatory
| --- | --- | --- |
BotPath | Path that the Windows Hubot package is installed. (Get from here: https://github.com/MattHodge/HubotWindows) | `Yes`
Ensure | Ensures that the bot is Present or Absent | `Yes`

### HubotInstallService

Parameter | Notes |  Mandatory
| --- | --- | --- |
BotPath | Path that the Windows Hubot package is installed. (Get from here: https://github.com/MattHodge/HubotWindows) | `Yes`
ServiceName | Name to give the Hubot Windows service | `Yes`
Credential | Credential of account to run the Hubot service under. If left blank, the service will run under the `SYSTEM` account. | `No`
BotAdapter | The name of the Hubot adapter to use. (https://github.com/github/hubot/blob/master/docs/adapters.md) | `Yes`
Ensure | Ensures that the bot is Present or Absent | `Yes`

## Examples

You can find an installation example here: [dsc_configuration.ps1](Examples/dsc_configuration.ps1)

## Installation

To install the module, use:

`Install-Module -Name Hubot`

## Packaging

The DSC Resource Module is called `Hubot` and is available on the PowerShell Gallery:
* https://www.powershellgallery.com/packages/Hubot

## Testing Using Test-Kitchen
* Make sure the repo is cloned as `Hubot` or Test-Kitchen will not work.

## Versions

### 1.1.4

* Removing dependency on `cChoco` and `Chocolatey`. This requires the node to reboot after installing Node.js as part of the `HubotPrerequisites` resource unfortunately.


### 1.1.3

* Initial Release
