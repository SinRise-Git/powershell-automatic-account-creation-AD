Import-Module ActiveDirectory

$fullDomain = "Exampel.com"
$dcPath = ( ($fullDomain -split "\.") | ForEach-Object { "DC=$_" } ) -join ","

$Defaults = [PSCustomObject]@{
    OU                    = "OU=Exampel,$($dcPath)"
    Domain                = $fullDomain
    Enabled               = $true
    ChangePasswordAtLogon = $true
    Password              = "ExamplePassword123!"
    Description           = "Account for $fullDomain"
    Department            = "Example Department"
}

$securePassword = ConvertTo-SecureString $Defaults.Password -AsPlainText -Force
$email = {
    param(
        [string]$FullName
    )
    $names = $FullName -split " "

    if ($names.Count -eq 1) {
        "$($names[0])@$($Defaults.Domain)"
    }
    else {
        "$($names[0]).$($names[-1])@$($Defaults.Domain)"
    }
}
$logonName = {
    param (
        [string]$FullName
    )

    $parts = $FullName -split '\s+'

    if ($parts.Count -ge 2) {
        $first = $parts[0]
        $last = $parts[-1]

        $firstPart = $first.Substring(0, [Math]::Min(3, $first.Length))
        $lastPart = $last.Substring(0, [Math]::Min(3, $last.Length))

        return ($firstPart + $lastPart).ToLower()
    }
    else {
        return $FullName.ToLower()
    }
} 

$users = Get-Content "userlist.txt" | ForEach-Object {
    $line = $_.Trim()
    $parts = $line -split ":"
    
    
    $fullname = $parts[0]

    $userData = [ordered]@{
        Name                  = & $logonName $fullname
        FullName              = $fullname
        Email                 = & $email $fullname
        OU                    = $Defaults.OU
        Domain                = $Defaults.Domain
        Enabled               = $Defaults.Enabled
        ChangePasswordAtLogon = $Defaults.ChangePasswordAtLogon
        Password              = $securePassword
        Description           = $Defaults.Description
        Department            = $Defaults.Department
        Groups                = @()
    }
    
    if ($parts.Count -gt 1) {
        foreach ($item in $parts[1..($parts.Count - 1)]) {
            if ($item -match "=") {
                $key, $value = $item -split "=", 2
                $key = $key.Trim()
                $value = $value.Trim()

                if ($key -eq "OU") {
                    $ouParts = $value -split "/"
                    $ouPath = ($ouParts | ForEach-Object { "OU=$_" }) -join ","
                    $value = "$ouPath,$dcPath"
                }

                elseif ($key -eq "Groups") {
                    $value = $value -split "," | ForEach-Object { $_.Trim() }
                }

                elseif ($userData.Contains($key) -and $userData[$key] -is [bool]) {
                    $value = [bool]::Parse($value)
                }

                if ($userData.Contains($key)) {
                    $userData[$key] = $value
                }
            }
        }
    }
    [PSCustomObject]$userData
}

Write-Host "`nUsers that will be created:" -ForegroundColor Cyan
$users | Select-Object Name, FullName, Email, OU, Department, Enabled | Format-Table -AutoSize
$confirm = Read-Host "`nDo you want to create these users? (y/n)"

if ($confirm -notin @('y', 'Y')) {
    Write-Host "Operation cancelled." -ForegroundColor Yellow
    return
}

foreach ($user in $users) {
    if (Get-ADUser -Filter "SamAccountName -eq '$($user.Name)'" -ErrorAction SilentlyContinue) {
        Write-Host "User $($user.Name) already exists - skipping" -ForegroundColor Yellow
        continue
    }
    Write-Host $dcPath
    Write-Host $user.OU

    try {
        New-ADUser `
            -Name $user.FullName `
            -SamAccountName $user.Name `
            -UserPrincipalName "$($user.Name)@$($user.Domain)" `
            -GivenName ($user.FullName -split " ")[0] `
            -Surname ($user.FullName -split " ")[-1] `
            -EmailAddress $user.Email `
            -AccountPassword $user.Password `
            -Enabled $user.Enabled `
            -ChangePasswordAtLogon $user.ChangePasswordAtLogon `
            -Path $user.OU `
            -Description $user.Description `
            -Department $user.Department

        Write-Host "Created user: $($user.FullName)" -ForegroundColor Green

        if ($user.Groups -and $user.Groups.Count -gt 0) {
            foreach ($group in $user.Groups) {
                try {
                    Add-ADGroupMember -Identity $group -Members $user.Name
                    Write-Host "  Added to group: $group" -ForegroundColor Cyan
                }
                catch {
                    Write-Host "  Failed to add to group $group : $_" -ForegroundColor Red
                }
            }
        }

    }
    catch {
        Write-Host "Failed to create user $($user.FullName): $_" -ForegroundColor Red
    }
}