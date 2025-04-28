function Get-BBUsers {
    [CmdletBinding()]
    param(
        [Object[]] $Properties = @('Name', 'LastLogonDate', 'Department', 'Company', 'EmployeeID', 'OfficePhone', 'MobilePhone')	,
        [switch] $Enabled = $true,
        [switch] $All = $false,
        [switch] $IncludeEPM = $false,
        [switch] $IncludeConsultants = $false
    )

    $baseproperties = @('Name', 'LastLogonDate', 'Department', 'Company')

    $searchbase = "OU=Accounts-User,OU=Booth Bay,DC=bbay,DC=corp" 

    if ($All) {
        $filter = '(Department -ne "Special")' 
        $IncludeEPM = $true
        $IncludeConsultants = $true
    }
    else {
        $filter = '(Department -eq "Boothbay")' 
    }

    if ($IncludeEPM) {
        $filter += ' -or (Department -like "*EPM*")'
    }
    if ($IncludeConsultants) {
        $filter += ' -or (Department -like "*Consultant*")'
    }
    $filter = $filter + ' -and (Company -eq "Boothbay"'

    if ($Enabled) {
        $filter += ' -and enabled -eq $true)'
    }
    else {
        $filter += ' -and enabled -eq $false)'
    }
    
    if (-not $properties.contains('*')) {
        $properties = $baseproperties + $properties | select-object -Unique
        write-verbose("Adding properties to query: $($properties -join ', ')")
    }

    write-verbose("Filter: $filter")
    write-verbose("SearchBase: $searchbase")
    write-verbose("Properties: $($properties -join ', ')")

    $users = get-aduser -filter $filter -SearchBase $searchbase -properties $properties | select $properties | Sort-Object Name

    return $users

}

# Export the function
Export-ModuleMember -Function Get-BBUsers
