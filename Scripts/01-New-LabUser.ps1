# 01-New-LabUser.ps1
# Purpose: Create a new Entra ID user for lifecycle automation testing
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"

$firstName = "Taylor"
$lastName = "Reed"
$displayName = "$firstName $lastName"
$mailNickname = "taylor.reed"
$userPrincipalName = "taylor.reed@SkyLab33.onmicrosoft.com"

$passwordProfile = @{
    Password = "TempP@ssw0rd123!"
    ForceChangePasswordNextSignIn = $true
}

$params = @{
    AccountEnabled    = $true
    DisplayName       = $displayName
    MailNickname      = $mailNickname
    UserPrincipalName = $userPrincipalName
    GivenName         = $firstName
    Surname           = $lastName
    Department        = "Operations"
    JobTitle          = "Service Desk Technician"
    UsageLocation     = "US"
    PasswordProfile   = $passwordProfile
}

Write-Host "Creating user: $displayName" -ForegroundColor Cyan

$newUser = New-MgUser @params

Write-Host "User created successfully." -ForegroundColor Green
Write-Host "Display Name: $($newUser.DisplayName)"
Write-Host "UPN: $($newUser.UserPrincipalName)"
Write-Host "User ID: $($newUser.Id)"
