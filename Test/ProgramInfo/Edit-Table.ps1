
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

#
# Unit test for Edit-Table
#
. $PSScriptRoot\..\..\Config\ProjectSettings.ps1

# Check requirements for this project
Import-Module -Name $RepoDir\Modules\System
Test-SystemRequirements

# Includes
. $RepoDir\Test\ContextSetup.ps1
Import-Module -Name $RepoDir\Modules\Test
Import-Module -Name $RepoDir\Modules\ProgramInfo
Import-Module -Name $RepoDir\Modules\FirewallModule

# Ask user if he wants to load these rules
Update-Context $TestContext $($MyInvocation.MyCommand.Name -replace ".{4}$")
if (!(Approve-Execute)) { exit }

$User = "haxor"

New-Test "Good system path"
Initialize-Table
Edit-Table "%SystemRoot%\System32\WindowsPowerShell\v1.0"

New-Test "Table data"
$global:InstallTable | Format-Table -AutoSize


New-Test "Bad system path"
Initialize-Table
Edit-Table "%ProgramFiles(x86)%\Microsoft Help Viewer\v2.3"

New-Test "Table data"
$global:InstallTable | Format-Table -AutoSize

New-Test "Good user profile path"
Initialize-Table
Edit-Table "C:\\Users\$User\source\\repos\WindowsFirewallRuleset\"

New-Test "Table data"
$global:InstallTable | Format-Table -AutoSize

New-Test "Bad user profile path"
Initialize-Table
Edit-Table "%HOME%\source\\repos\WindowsFirewallRuleset\"

New-Test "Table data"
$global:InstallTable | Format-Table -AutoSize

Exit-Test
