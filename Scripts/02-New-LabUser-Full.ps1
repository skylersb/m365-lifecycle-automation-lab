# 01-New-LabUser.ps1
# Purpose: Create a new Entra ID user and complete onboarding steps

Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All", "Group.ReadWrite.All"

# --- User Info ---
$firstName = "Taylor"
$lastName = "Reed"
$displayName = "$firstName $lastName"
$mailNickname = "taylor.reed"
$userPrincipalName = "taylor.reed@SkyLab33.onmicrosoft.com"

# --- Password Profile ---
$passwordProfile = @{
    Password = "TempP@ss123!"
    ForceChangePasswordNextSignIn = $true
}

# --- User Parameters ---
$params = @{
    AccountEnabled = $true
    DisplayName = $displayName
    MailNickname = $mailNickname
    UserPrincipalName = $userPrincipalName
    GivenName = $firstName
    Surname = $lastName
    Department = "Operations"
    JobTitle = "Service Desk Technician"
    UsageLocation = "US"
    PasswordProfile = $passwordProfile
}

$existingUser = Get-MgUser -Filter "userPrincipalName eq '$userPrincipalName'" -ErrorAction SilentlyContinue

if ($existingUser) {
    Write-Host "User already exists. Skipping creation..." -ForegroundColor Yellow
    $newUser = $existingUser
}
else {
    # --- Create User ---
    Write-Host "Creating user: $displayName" -ForegroundColor Cyan
    $newUser = New-MgUser @params
}


# --- Assign License ---
$sku = Get-MgSubscribedSku | Where-Object { $_.SkuPartNumber -eq "SPB" }
$currentLicenses = Get-MgUserLicenseDetail -UserId $newUser.Id

$hasLicense = $currentLicenses | Where-Object { $_.SkuId -eq $sku.SkuId }

if ($newUser.Id) {
    if ($hasLicense) {
        Write-Host "License already assigned." -ForegroundColor Yellow
    }
    else {
        Set-MgUserLicense -UserId $newUser.Id -AddLicenses @{SkuId = $sku.SkuId} -RemoveLicenses @()
        Write-Host "License assigned." -ForegroundColor Green
    }
}

# --- Add to Group ---
$group = Get-MgGroup -Filter "displayName eq 'Operations-Users'"

$existingMembership = Get-MgUserMemberOf -UserId $newUser.Id | Where-Object { $_.Id -eq $group.Id }

if ($newUser.Id -and $group.Id) {
    if ($existingMembership) {
        Write-Host "User is already a member of Operations-Users." -ForegroundColor Yellow
    }
    else {
        New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $newUser.Id
        Write-Host "Added to Operations-Users group." -ForegroundColor Green
    }
}

# --- Output Summary ---
if ($newUser) {
    Write-Host "User created successfully." -ForegroundColor Green
}
else {
    Write-Host "User creation failed." -ForegroundColor Red
}
Write-Host "Display Name: $displayName"
Write-Host "UPN: $userPrincipalName"
Write-Host "User ID: $($newUser.Id)"