
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
Import-Module -Name $RepoDir\Modules\FirewallModule

#
# Setup local variables:
#
$Group = "Basic Networking - IPv4"
$Profile = "Any"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

# TODO: specifiying -InterfaceAlias $Loopback does not work, dropped packets
# NOTE: even thogh we specify "IPv4 the loopback interface alias is the same for for IPv4 and IPv6, meaning there is only one loopback interface!"
# $Loopback = Get-NetIPInterface | Where-Object {$_.InterfaceAlias -like "*Loopback*" -and $_.AddressFamily -eq "IPv4"} | Select-Object -ExpandProperty InterfaceAlias

#
# Predefined rules from Core Networking are here
#

#
# Loopback
# Used on TCP, UDP, IGMP
#

New-NetFirewallRule -Platform $Platform `
-DisplayName "Loopback" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
-Direction $Direction -Protocol Any -LocalAddress Any -RemoteAddress 127.0.0.1 -LocalPort Any -RemotePort Any `
-LocalUser Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Loopback" -Service Any -Program Any `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType Any `
-Direction $Direction -Protocol Any -LocalAddress 127.0.0.1 -RemoteAddress Any -LocalPort Any -RemotePort Any `
-LocalUser Any `
-Description "Network software and utilities use loopback address to access a local computer's TCP/IP network resources." | Format-Output

#
# DNS (Domain Name System)
#

# TODO: official rule uses loose source mapping
New-NetFirewallRule -Platform $Platform `
-DisplayName "Domain Name System" -Service Dnscache -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress DNS4 -LocalPort Any -RemotePort 53 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $true `
-Description "Allow DNS requests.
DNS responses based on requests that matched this rule will be permitted regardless of source address.
This behavior is classified as loose source mapping." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Domain Name System" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress DefaultGateway4 -LocalPort Any -RemotePort 53 `
-LocalUser $NT_AUTHORITY_System -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Allow DNS requests by System to default gateway." | Format-Output

#
# mDNS (Multicast Domain Name System)
# NOTE: this should be placed in Multicast.ps1 like it is for IPv6, but it's here because of specific address,
# which is part of "Local Network Control Block" (224.0.0.0 - 224.0.0.255)
# mDNS message is a multicast UDP packet sent using the following addressing:
# IPv4 address 224.0.0.251 or IPv6 address ff02::fb
# UDP port 5353
# https://en.wikipedia.org/wiki/Multicast_DNS
#

New-NetFirewallRule -Platform $Platform `
-DisplayName "Multicast Domain Name System" -Service Dnscache -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile Private, Domain -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 224.0.0.251 -LocalPort 5353 -RemotePort 5353 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames to IP addresses
within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)." | Format-Output

New-NetFirewallRule -Platform $Platform `
-DisplayName "Multicast Domain Name System" -Service Dnscache -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Block -Group $Group -Profile Public -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress 224.0.0.251 -LocalPort 5353 -RemotePort 5353 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "In computer networking, the multicast DNS (mDNS) protocol resolves hostnames to IP addresses
within small networks that do not include a local name server.
It is a zero-configuration service, using essentially the same programming interfaces,
packet formats and operating semantics as the unicast Domain Name System (DNS)." | Format-Output

#
# DHCP (Dynamic Host Configuration Protocol)
#

New-NetFirewallRule -Platform $Platform `
-DisplayName "Dynamic Host Configuration Protocol" -Service Dhcp -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress DHCP4 -LocalPort 68 -RemotePort 67 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Allow DHCPv4 messages for stateful auto-configuration." | Format-Output

#
# IGMP (Internet Group Management Protocol)
#

New-NetFirewallRule -Platform $Platform `
-DisplayName "Internet Group Management Protocol" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol 2 -LocalAddress Any -RemoteAddress LocalSubnet4, 224.0.0.0/24 -LocalPort Any -RemotePort Any `
-LocalUser $NT_AUTHORITY_System `
-Description "IGMP messages are sent and received by nodes to create, join and depart multicast groups." | Format-Output

#
# IPHTTPS (IPv4 over HTTPS)
#

New-NetFirewallRule -Platform $Platform `
-DisplayName "IPv4 over HTTPS" -Service Any -Program System `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort IPHTTPSout `
-LocalUser $NT_AUTHORITY_System `
-Description "Allow IPv4 IPHTTPS tunneling technology to provide connectivity across HTTP proxies and firewalls." | Format-Output

#
# Teredo
#

New-NetFirewallRule -Platform $Platform `
-DisplayName "Teredo" -Service iphlpsvc -Program $ServiceHost `
-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
-Direction $Direction -Protocol UDP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 3544 `
-LocalUser Any -LocalOnlyMapping $false -LooseSourceMapping $false `
-Description "Allow Teredo edge traversal, a technology that provides address assignment and automatic tunneling
for unicast IPv6 traffic when an IPv6/IPv4 host is located behind an IPv4 network address translator." | Format-Output
