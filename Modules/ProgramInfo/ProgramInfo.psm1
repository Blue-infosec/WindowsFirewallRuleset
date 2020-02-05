
<#
MIT License

Copyright (c) 2019 metablaster zebal@protonmail.ch

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

# Includes
Import-Module -Name $PSScriptRoot\..\UserInfo
Import-Module -Name $PSScriptRoot\..\ComputerInfo
Import-Module -Name $PSScriptRoot\..\FirewallModule

# about: get store app SID
# input: Username and "PackageFamilyName" string
# output: store app SID (security identifier) as string
# sample: Get-AppSID("User", "Microsoft.MicrosoftEdge_8wekyb3d8bbwe")
function Get-AppSID
{
    param (
        [parameter(Mandatory = $true, Position=0)]
        [ValidateLength(1, 100)]
        [string] $UserName,

        [parameter(Mandatory = $true, Position=1)]
        [ValidateLength(1, 100)]
        [string] $AppName
    )
    
    $ACL = Get-ACL "C:\Users\$UserName\AppData\Local\Packages\$AppName\AC"
    $ACE = $ACL.Access.IdentityReference.Value
    
    $ACE | ForEach-Object {
        # package SID starts with S-1-15-2-
        if($_ -match "S-1-15-2-") {
            return $_
        }
    }
}

# about: check if file such as an *.exe exists
# input: path to file
# output: warning message if file not found
# sample: Test-File("C:\Users\User\AppData\Local\Google\Chrome\Application\chrome.exe")
function Test-File
{
    param (
        [parameter(Mandatory = $true)]
        [string] $FilePath
    )

    if ($global:InstallationStatus)
    {
        $ExpandedPath = [System.Environment]::ExpandEnvironmentVariables($FilePath)

        if (!([System.IO.File]::Exists($ExpandedPath)))
        {
            # NOTE: number for Get-PSCallStack is 1, which means 2 function calls back and then get script name (call at 0 is this script)
            $Script = (Get-PSCallStack)[1].Command
            $SearchPath = Split-Path -Path $ExpandedPath -Parent
            $Executable = Split-Path -Path $ExpandedPath -Leaf
            Set-Variable -Name WarningsDetected -Scope Global -Value $true
            
            Write-Warning "Executable '$Executable' was not found, rule won't have any effect
         Searched path was: $SearchPath"

            Write-Host "NOTE: To fix the problem find '$Executable' then adjust the path in $Script and re-run the script later again" -ForegroundColor Green
        }
    }
}

# about: Same as Test-Path but expands system environment variables
function Test-Environment
{
    param (
        [parameter(Mandatory = $true)]
        [string] $FilePath
    )

    return (Test-Path -Path ([System.Environment]::ExpandEnvironmentVariables($FilePath)))
}

# input: User account in form of "COMPUTERNAME\USERNAME"
# output: list of programs for specified USERNAME
# sample: Get-UserPrograms "COMPUTERNAME\USERNAME"
function Get-UserPrograms
{
    param (
        [parameter(Mandatory = $true)]
        [string] $UserAccount
    )

    $ComputerName = ($UserAccount.split("\"))[0]

    if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet)
    {
        $HKU = Get-AccountSID $UserAccount
        $HKU += "\Software\Microsoft\Windows\CurrentVersion\Uninstall"
        
        $RegistryHive = [Microsoft.Win32.RegistryHive]::Users
    
        $RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)
        $UserKey = $RemoteKey.OpenSubkey($HKU)

        $UserPrograms = @()
        if ($UserKey)
        {
            foreach ($SubKey in $UserKey.GetSubKeyNames())
            {
                foreach ($KeyEntry in $UserKey.OpenSubkey($SubKey))
                {
                    # Get more key entries as needed
                    $UserPrograms += (New-Object PSObject -Property @{
                    "ComputerName" = $ComputerName
                    "Name" = $KeyEntry.GetValue("displayname")
                    "InstallLocation" = $KeyEntry.GetValue("InstallLocation")})
                }
            }
        }
        else
        {
            Write-Warning "Failed to open registry key: $HKU"
        }

        return $UserPrograms
    } 
    else
    {
        Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact '$ComputerName'"
    }
}

# input: ComputerName
# output: list of programs installed for all users
# sample: Get-SystemPrograms "COMPUTERNAME"
function Get-SystemPrograms
{
    param (
        [parameter(Mandatory = $true)]
        [string] $ComputerName
    )

    if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet)
    {
        # The value of the [IntPtr] property is 4 in a 32-bit process, and 8 in a 64-bit process.
        if ([IntPtr]::Size -eq 4)
        {
            $HKLM = "Software\Microsoft\Windows\CurrentVersion\Uninstall"
        }
        else
        {
            $HKLM = @(
                "Software\Microsoft\Windows\CurrentVersion\Uninstall"
                "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            )
        }
        
        $RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
        $RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

        $SystemPrograms = @()
        foreach ($HKLMKey in $HKLM)
        {
            $UserKey = $RemoteKey.OpenSubkey($HKLMKey)

            if ($UserKey)
            {
                foreach ($SubKey in $UserKey.GetSubKeyNames())
                {
                    foreach ($KeyEntry in $UserKey.OpenSubkey($SubKey))
                    {
                        # Get more key entries as needed
                        $SystemPrograms += (New-Object PSObject -Property @{
                        "ComputerName" = $ComputerName
                        "Name" = $KeyEntry.GetValue("DisplayName")
                        "InstallLocation" = $KeyEntry.GetValue("InstallLocation")})
                    }
                }
            }
            else
            {
                Write-Warning "Failed to open registry key: $HKLMKey"
            }
        }

        return $SystemPrograms | Where-Object { $_.InstallLocation }
    }
    else
    {
        Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact '$ComputerName'"
    }
}

# about: Create data table used to hold information for specific program for each user
# input: Table name, but not mandatory
# output: Empty table with 2 columns, user entry and install location
# sample: $MyTable = Initialize-Table
function Initialize-Table
{
    param (
        [parameter(Mandatory = $false)]
        [string] $TableName = "InstallationTable"
    )

    # Create Table object
    $global:InstallTable = New-Object System.Data.DataTable $TableName

    # Define Columns
    $UserColumn = New-Object System.Data.DataColumn User, ([string])
    $InstallColumn = New-Object System.Data.DataColumn InstallRoot, ([string])

    # Add the Columns
    $global:InstallTable.Columns.Add($UserColumn)
    $global:InstallTable.Columns.Add($InstallColumn)

    #return Write-Output -NoEnumerate $global:InstallTable
}

# about: Search and add new program installation directory to the global table
# input: Search string which corresponds to the output of "Get programs" functions
# input: true if user profile is to be searched too, system locations only otherwise
# output: Global installation table is updated
# sample: Update-Table "Google Chrome"
function Update-Table
{
    param (
        [parameter(Mandatory = $true)]
        [string] $SearchString,

        [parameter(Mandatory = $false)]
        [bool] $UserProfile = $false
    )

    Initialize-Table
    $SystemPrograms = Get-SystemPrograms (Get-ComputerName)

    if ($SystemPrograms.Name -like $SearchString)
    {
        foreach ($User in $global:UserNames)
        {
            # Create a row
            $Row = $global:InstallTable.NewRow()

            # Enter data in the row
            $Row.User = $User
            $Row.InstallRoot = $SystemPrograms | Where-Object { $_.Name -like $SearchString } | Select-Object -ExpandProperty InstallLocation

            # Add row to the table
            $global:InstallTable.Rows.Add($Row)
        }
    }

    if ($UserProfile)
    {
        foreach ($Account in $global:UserAccounts)
        {
            $UserPrograms = Get-UserPrograms $Account
            
            if ($UserPrograms.Name -like $SearchString)
            {
                # Create a row
                $Row = $global:InstallTable.NewRow()

                # Enter data in the row
                $Row.User = $Account.Split("\")[1]
                $Row.InstallRoot = $UserPrograms | Where-Object { $_.Name -like $SearchString } | Select-Object -ExpandProperty InstallLocation

                # Add the row to the table
                $global:InstallTable.Rows.Add($Row)
            }
        }
    }
}

# about: Add new (row) program installation directory to the global table from string for each user
# input: Program installation directory
# output: Global installation table is updated
# sample: Edit-Table "%ProgramFiles(x86)%\TeamViewer"
function Edit-Table
{
    param (
        [parameter(Mandatory = $true)]
        [string] $InstallRoot
    )

    # test since input may come from user input too!
    if (Test-Environment $InstallRoot)
    {
        foreach ($User in $global:UserNames)
        {
            # Create a row
            $Row = $global:InstallTable.NewRow()

            # Enter data in the row
            $Row.User = $User
            $Row.InstallRoot = $InstallRoot

            # Add the row to the table
            $global:InstallTable.Rows.Add($Row)
        }
    }
}

# about: test if given installation directory is valid
# input: predefined program name and path to program (excluding executable)
# output: if test OK same path, if not try to update path, else return given path back
# sample: Test-Installation "Office" "%ProgramFiles(x86)%\Microsoft Office\root\Office16"
function Test-Installation
{
    param (
        [parameter(Mandatory = $true, Position = 0)]
        [string] $Program,

        [parameter(Mandatory = $true, Position = 1)]
        [ref] $FilePath,

        [parameter(Mandatory = $false, Position = 2)]
        [bool] $Terminate = $true
    )

    if ($FilePath -like "%UserProfile%")
    {
        Write-Warning "Bad environment variable detected '%UserProfile%', rule may not work!"
        Set-Variable -Name WarningsDetected -Scope Global -Value $true
    }

    if (!(Test-Environment $FilePath))
    {
        if (!(Find-Installation $Program))
        {
            if ($Terminate)
            {
                exit # installation not found, exit script
            }

            return $false # installation not found
        }
        else
        {
            $InstallRoot = $global:InstallTable | Select-Object -ExpandProperty InstallRoot

            Write-Host "NOTE: Path corrected from: $($FilePath.Value)
to: $InstallRoot" -ForegroundColor Green

            $FilePath.Value = $InstallRoot
            # path updated
        }
    }

    return $true # path exists
}

# about: find installation directory for given program
# input: predefined program name
# output: installation directory if found, otherwise empty string
# sample: Find-Installation "Office"
function Find-Installation
{
    param (
        [parameter(Mandatory = $true)]
        [string] $Program
    )

    [string] $InstallRoot = ""

    # TODO: need to check some of these search strings (cases), also remove hardcoded directories
    # NOTE: we want to preserve system environment variables for firewall GUI,
    # otherwise firewall GUI will show full paths which is not desired for sorting reasons
    switch -Wildcard ($Program)
    {
        "VSCode"
        {
            Update-Table "Visual Studio Code"
            break
        }
        "MicrosoftOffice"
        {
            Update-Table "Microsoft Office"
            break
        }
        "TeamViewer"
        {
            Update-Table "Team Viewer"

            # TODO: not sure if search string should be 'TeamViewer or 'Team Viewer'
            if ($global:InstallTable.Rows.Count -eq 0)
            {
                $InstallRoot = "%ProgramFiles(x86)%\TeamViewer"
                if (Test-Environment $InstallRoot)
                {
                    Edit-Table $InstallRoot
                }
            }
            break
        }
        "EdgeChromium"
        {
            Update-Table "Microsoft Edge"
            break         
        }
        "Chrome"
        {
            Update-Table "Google Chrome" $true
            break
        }
        "Firefox"
        {
            Update-Table "Firefox" $true
            break
        }
        "Yandex"
        {
            Update-Table "Yandex" $true
            break
        }
        "Tor"
        {
            Update-Table "Tor" $true
            break
        }
        "uTorrent"
        {
            Update-Table "uTorrent" $true
            break
        }
        "Thuderbird"
        {
            Update-Table "Thuderbird" $true
            break
        }
        "Steam"
        {
            Update-Table "Steam"
            break
        }
        "Nvidia64"
        {
            $InstallRoot = "%ProgramFiles%\NVIDIA Corporation"
            if (Test-Environment $InstallRoot)
            {
                Edit-Table $InstallRoot
            }
            break
        }
        "Nvidia86"
        {
            $InstallRoot = "%ProgramFiles(x86)%\NVIDIA Corporation"
            if (Test-Environment $InstallRoot)
            {
                Edit-Table $InstallRoot
            }
            break
        }
        "WarThunder"
        {
            $InstallRoot = "%ProgramFiles(x86)%\Steam\steamapps\common\War Thunder"
            if (Test-Environment $InstallRoot)
            {
                Edit-Table $InstallRoot
            }
            break
        }
        "PokerStars"
        {
            Update-Table "PokerStars"
            break
        }
        "VisualStudio"
        {
            $InstallRoot = "%ProgramFiles(x86)%\Microsoft Visual Studio\2019\Community"
            if (Test-Environment $InstallRoot)
            {
                Edit-Table $InstallRoot
            }
            break
        }
        "MSYS2"
        {
            Update-Table "MSYS2" $true
            break
        }
        "VisualStudioInstaller"
        {
            $InstallRoot = "%ProgramFiles(x86)%\Microsoft Visual Studio\Installer"
            if (Test-Environment $InstallRoot)
            {
                Edit-Table $InstallRoot
            }
            break
        }
        "Git"
        {
            Update-Table "Git"
            break
        }
        "GithubDesktop"
        {
            # TODO: need to overcome version number
            # TODO: default location?
            foreach ($User in $global:UserNames)
            {
                $InstallRoot = "%SystemDrive%\Users\$User\AppData\Local\GitHubDesktop\app-2.2.3"
                if (Test-Environment $InstallRoot)
                {
                    Edit-Table $InstallRoot
                }
            }
            break
        }
        "EpicGames"
        {
            $InstallRoot = "%ProgramFiles(x86)%\Epic Games\Launcher"
            if (Test-Environment $InstallRoot)
            {
                Edit-Table $InstallRoot
            }
            break
        }
        "UnrealEngine"
        {
            # TODO: need default installation
            foreach ($User in $global:UserNames)
            {
                $InstallRoot = "%SystemDrive%\Users\$User\source\repos\UnrealEngine\Engine"
                if (Test-Environment $InstallRoot)
                {
                    Edit-Table $InstallRoot
                }
            }
            break
        }
        Default
        {
            Write-Warning "Parameter '$Program' not recognized"
        }
    }

    if ($global:InstallTable.Rows.Count -gt 0)
    {
        # Display the table
        # TODO: is this temporary for debugging?
        # $global:InstallTable | Format-Table -AutoSize

        return $true
    }
    else
    {
        Write-Warning "Installation directory for '$Program' not found"
        # NOTE: number for Get-PSCallStack is 2, which means 3 function calls back and then get script name (call at 0 and 1 is this script)
        $Script = (Get-PSCallStack)[2].Command
    
        Write-Host "NOTE: If you installed $Program elsewhere you can input the correct path now
        or adjust the path in $Script and re-run the script later.
        otherwise ignore this warning if you don't have $Program installed." -ForegroundColor Green
        if (Approve-Execute "Yes" "Rule group for $Program" "Do you want to input path now?")
        {
            while ($global:InstallTable.Rows.Count -eq 0)
            {
                $InstallRoot = Read-Host "Input path to '$Program' root directory"

                Edit-Table $InstallRoot
    
                if ($global:InstallTable.Rows.Count -gt 0)
                {        
                    return $true
                }
                else
                {
                    Write-Warning "Installation directory for '$Program' not found"
                    if (Approve-Execute "No" "Unable to locate '$InstallRoot'" "Do you want to try again?")
                    {
                        break
                    }
                }
            }
        }
        
        return $false
    }
}

# about: Return installed NET Frameworks
# input: Computer name for which to list installed installed framework
# output: Table of installed NET Framework versions and install paths
# sample: Get-NetFramework COMPUTERNAME
function Get-NetFramework
{
    param (
        [parameter(Mandatory = $true)]
        [string] $ComputerName
    )

    if (Test-Connection -ComputerName $ComputerName -Count 2 -Quiet)
    {
        $HKLM = "SOFTWARE\Microsoft\NET Framework Setup\NDP"

        $RegistryHive = [Microsoft.Win32.RegistryHive]::LocalMachine
        $RemoteKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($RegistryHive, $ComputerName)

        $NetFramework = @()
        $RootKey = $RemoteKey.OpenSubkey($HKLM)

        if (!$RootKey)
        {
            Write-Warning "Failed to open RootKey: $HKLM"
        }
        else
        {
            foreach ($HKLMKey in $RootKey.GetSubKeyNames())
            {
                $KeyEntry = $RootKey.OpenSubkey($HKLMKey)

                if (!$KeyEntry)
                {
                    Write-Warning "Failed to open KeyEntry: $HKLMKey"
                    continue
                }

                $Version = $KeyEntry.GetValue("Version")
                if ($null -ne $Version)
                {
                    $NetFramework += New-Object -TypeName PSObject -Property @{
                        "ComputerName" = $ComputerName
                        "KeyEntry" = Split-Path $KeyEntry.ToString() -Leaf
                        "Version" = $Version
                        "InstallPath" = $KeyEntry.GetValue("InstallPath")}        
                }
                else
                {
                    foreach ($SubKey in $KeyEntry.GetSubKeyNames())
                    {
                        $SubKeyEntry = $KeyEntry.OpenSubkey($SubKey)
                        if (!$SubKeyEntry)
                        {
                            Write-Warning "Failed to open SubKeyEntry: $SubKey"
                            continue
                        }

                        $Version = $SubKeyEntry.GetValue("Version")
                        if ($null -ne $Version)
                        {
                            $NetFramework += New-Object -TypeName PSObject -Property @{
                                "ComputerName" = $ComputerName
                                "KeyEntry" = Split-Path $SubKeyEntry.ToString() -Leaf
                                "Version" = $Version
                                "InstallPath" = $SubKeyEntry.GetValue("InstallPath")}            
                        }
                    }
                }
            }
        }

        return $NetFramework
    }
    else
    {
        Write-Error -Category ConnectionError -TargetObject $ComputerName -Message "Unable to contact '$ComputerName'"
    }
}

# Global status to check if installation directory exists, used by Test-File
New-Variable -Name InstallationStatus -Scope Global -Value $false
New-Variable -Name InstallTable -Scope Global -Value $null

#
# Function exports
#

Export-ModuleMember -Function Get-UserPrograms
Export-ModuleMember -Function Get-SystemPrograms
Export-ModuleMember -Function Test-File
Export-ModuleMember -Function Find-Installation
Export-ModuleMember -Function Test-Installation
Export-ModuleMember -Function Get-AppSID
Export-ModuleMember -Function Test-Environment
Export-ModuleMember -Function Initialize-Table
Export-ModuleMember -Function Get-NetFramework

# For debugging only
Export-ModuleMember -Function Update-Table

#
# Variable exports
#

Export-ModuleMember -Variable InstallationStatus
Export-ModuleMember -Variable InstallTable