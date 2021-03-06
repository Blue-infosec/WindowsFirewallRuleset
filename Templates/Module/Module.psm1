
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

# TODO: Include modules you need, update licence Copyright and start writing code

# Includes
# Import-Module -Name $RepoDir\UserInfo
# Import-Module -Name $RepoDir\ProgramInfo
# Import-Module -Name $RepoDir\ComputerInfo
# Import-Module -Name $RepoDir\FirewallModule

# about: Sample function
# input: nothing
# output: $null
# sample: Test-Function
function Test-Function
{
	param (
		[Parameter(Mandatory = $true)]
		[string] $Param
	)

	return $null
}

#
# Module variables
#

# Set to false to avoid checking powershell version
New-Variable -Name NewModule -Scope Global -Value $true

#
# Function exports
#

Export-ModuleMember -Function Test-Function

#
# Variable exports
#

Export-ModuleMember -Variable NewModule
