
<#
MIT License

Project: "Windows Firewall Ruleset" serves to manage firewall on Windows systems
Homepage: https://github.com/metablaster/WindowsFirewallRuleset

Copyright (C) 2019, 2020 metablaster zebal@protonmail.ch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
#>

. $PSScriptRoot\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $RepoDir\Modules\System
Test-SystemRequirements

# Includes
. $PSScriptRoot\DirectionSetup.ps1
. $PSScriptRoot\..\IPSetup.ps1
Import-Module -Name $RepoDir\Modules\UserInfo
Import-Module -Name $RepoDir\Modules\ProgramInfo
Import-Module -Name $RepoDir\Modules\FirewallModule

#
# Setup local variables:
#
$Group = "Additional Networking"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Firewall predefined rules related to networking not handled by other more strict scripts
#

#
# Cast to device predefined rules
#

New-NetFirewallRule -Platform $Platform `
-DisplayName "Cast to Device functionality (qWave)" -Service QWAVE -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Public -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress PlayToDevice4 -LocalPort Any -RemotePort 2177 `
-LocalUser Any `
-Description "Outbound rule for the Cast to Device functionality to allow use of the Quality Windows Audio Video Experience Service.
Quality Windows Audio Video Experience (qWave) is a networking platform for Audio Video (AV) streaming applications on IP home networks.
qWave enhances AV streaming performance and reliability by ensuring network quality-of-service (QoS) for AV applications.
It provides mechanisms for admission control, run time monitoring and enforcement, application feedback, and traffic prioritization." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Cast to Device functionality (qWave)" -Service QWAVE -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Public -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress PlayToDevice4 -LocalPort Any -RemotePort 2177 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Outbound rule for the Cast to Device functionality to allow use of the Quality Windows Audio Video Experience Service.
Quality Windows Audio Video Experience (qWave) is a networking platform for Audio Video (AV) streaming applications on IP home networks.
qWave enhances AV streaming performance and reliability by ensuring network quality-of-service (QoS) for AV applications.
It provides mechanisms for admission control, run time monitoring and enforcement, application feedback, and traffic prioritization." | Format-Output

$Program = "%SystemRoot%\System32\mdeserver.exe"
Test-File $Program
New-NetFirewallRule -Platform $Platform `
-DisplayName "Cast to Device streaming server (RTP)" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Public -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress PlayToDevice4 -LocalPort Any -RemotePort Any `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Rule for the Cast to Device server to allow streaming using RTSP and RTP." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Cast to Device streaming server (RTP)" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress LocalSubnet4 -LocalPort Any -RemotePort Any `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Rule for the Cast to Device server to allow streaming using RTSP and RTP." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Cast to Device streaming server (RTP)" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Domain -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Rule for the Cast to Device server to allow streaming using RTSP and RTP." | Format-Output

#
# Connected devices platform predefined rules
#

New-NetFirewallRule -Platform $Platform `
-DisplayName "Connected Devices Platform - Wi-Fi Direct Transport" -Service CDPSvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Public -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any `
-Description "Outbound rule to use Wi-Fi Direct traffic in the Connected Devices Platform." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Connected Devices Platform" -Service CDPSvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any `
-Description "Outbound rule for Connected Devices Platform traffic." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Connected Devices Platform" -Service CDPSvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile  Private, Domain -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Outbound rule for Connected Devices Platform traffic." | Format-Output

#
# AllJoyn Router predefined rules
#

New-NetFirewallRule -Platform $Platform `
-DisplayName "AllJoyn Router" -Service AJRouter -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any `
-Description "Outbound rule for AllJoyn Router traffic.
AllJoyn Router service routes AllJoyn messages for the local AllJoyn clients.
If this service is stopped the AllJoyn clients that do not have their own bundled routers will be unable to run." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "AllJoyn Router" -Service AJRouter -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Outbound rule for AllJoyn Router traffic.
AllJoyn Router service routes AllJoyn messages for the local AllJoyn clients.
If this service is stopped the AllJoyn clients that do not have their own bundled routers will be unable to run." | Format-Output

#
# Proximity sharing predefined rule
#

# TODO: probably does not exist in Windows Server 2019
$Program = "%SystemRoot%\System32\ProximityUxHost.exe"
Test-File $Program
New-NetFirewallRule -Platform $Platform `
-DisplayName "Proximity sharing" -Service Any -Program $Program `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile Private, Public -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any `
-Description "Outbound rule for Proximity sharing over." | Format-Output
