
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

. $PSScriptRoot\..\..\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $RepoDir\Modules\System
Test-SystemRequirements

# Includes
. $PSScriptRoot\..\DirectionSetup.ps1
. $PSScriptRoot\..\..\IPSetup.ps1
Import-Module -Name $RepoDir\Modules\UserInfo
Import-Module -Name $RepoDir\Modules\ProgramInfo
Import-Module -Name $RepoDir\Modules\FirewallModule

#
# Setup local variables:
#
$Group = "Development - Github"
$Profile = "Private, Public"

# Ask user if he wants to load these rules
Update-Context "IPv$IPVersion" $Direction $Group
if (!(Approve-Execute)) { exit }

# First remove all existing rules matching group
Remove-NetFirewallRule -PolicyStore $PolicyStore -Group $Group -Direction $Direction -ErrorAction SilentlyContinue

#
# Git and Git Desktop installation directories
# TODO: Username?
#
$GitRoot = "%ProgramFiles%\Git"
$GithubRoot = "%SystemDrive%\Users\User\AppData\Local\GitHubDesktop\app-2.2.3"

#
# Rules for git
#

# Test if installation exists on system
if ((Test-Installation "Git" ([ref] $GitRoot)) -or $Force)
{
	$Program = "$GitRoot\mingw64\bin\curl.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Git - curl" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UserAccountsSDDL `
	-Description "curl download tool" | Format-Output

	# TODO: unsure if it's 443 or 80
	$Program = "$GitRoot\mingw64\bin\git.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Git - git" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UserAccountsSDDL `
	-Description "" | Format-Output

	$Program = "$GitRoot\mingw64\libexec\git-core\git-remote-https.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Git - remote-https" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled True -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UserAccountsSDDL `
	-Description "git HTTPS acces (https cloning)" | Format-Output

	$Program = "$GitRoot\usr\bin\ssh.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "Git - ssh" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 22 `
	-LocalUser $UserAccountsSDDL `
	-Description "git SSH acces" | Format-Output
}

#
# Rules for Github desktop
#

# Test if installation exists on system
if ((Test-Installation "GithubDesktop" ([ref] $GithubRoot)) -or $Force)
{
	$Program = "$GithubRoot\GitHubDesktop.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "GitHub Desktop - App" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UserAccountsSDDL `
	-Description "" | Format-Output

	$Program = "$GithubRoot\resources\app\git\mingw64\bin\git-remote-https.exe"
	Test-File $Program
	New-NetFirewallRule -Platform $Platform `
	-DisplayName "GitHub Desktop - remote-https" -Service Any -Program $Program `
	-PolicyStore $PolicyStore -Enabled False -Action Allow -Group $Group -Profile $Profile -InterfaceType $Interface `
	-Direction $Direction -Protocol TCP -LocalAddress Any -RemoteAddress Internet4 -LocalPort Any -RemotePort 443 `
	-LocalUser $UserAccountsSDDL `
	-Description "cloning repos" | Format-Output
}
