# https://ramblingcookiemonster.github.io/Building-A-PowerShell-Module/
# $ModuleName = $env:moduleName
$ModuleName = 'ElliottNewModule'
$JCAPIKEY = $env:xApiKey
$SingleAdminAPIKey = $env:xApiKey
$NuGetApiKey = $env:nuGetApiKey
$Folder_ModuleRootPath = (Get-Item -Path:($PSScriptRoot)).Parent.FullName
# Define folder path variables
$Folder_Module = $Folder_ModuleRootPath + '\' + $ModuleName
$ModuleNameOld = $ModuleName + '_Old'
$Folder_Module_Old = $Folder_ModuleRootPath + '\' + $ModuleNameOld
$Folder_Private = $Folder_Module + '\' + 'Private'
$Folder_Public = $Folder_Module + '\' + 'Public'
$Folder_HelpFiles = $Folder_Module + '\' + 'en-US'
$Folder_Tests = $Folder_Module + '\' + 'Tests'
$Folder_Docs = $Folder_Module + '\' + 'Docs'
# Define file path variables
$File_Psm1 = $Folder_Module + '\' + $ModuleName + '.psm1'
$File_Psd1 = $Folder_Module + '\' + $ModuleName + '.psd1'
$File_Ps1Xml = $Folder_Module + '\' + $ModuleName + '.Format.ps1xml'
$File_HelpTxt = $Folder_HelpFiles + '\' + 'about_' + $ModuleName + '.help.txt'
$File_TestsPs1_Template = '{0}\{1}.{2}.Tests.ps1'
$File_ModuleMd = $Folder_Docs + '\' + $ModuleName + '.md'
# Define git variables
$GitUserEmail = 'AzurePipelines@NotAnEmail.com'
$GitUserName = 'AzurePipelines'
$GitCommitMessage_HelpFiles = '[AzurePipelines]Committing updated help files'
$GitCommitMessage_BuildModule = '[AzurePipelines]Committing updated build module'
$GitCurrentBranch = $env:BUILD_SOURCEBRANCHNAME
$GitTargetBranch = 'azure-devops'
# Get function names
$Functions_Public = If (Test-Path -Path:($Folder_Public)) {Get-ChildItem -Path:($Folder_Public + '\' + '*.ps1') -Recurse}
$Functions_Private = If (Test-Path -Path:($Folder_Private)) {Get-ChildItem -Path:($Folder_Private + '\' + '*.ps1') -Recurse}
# Misc functions
Function Publish-ToGitHub
{
    param (
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 0)][ValidateNotNullOrEmpty()][string]$UserEmail,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 1)][ValidateNotNullOrEmpty()][string]$UserName,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 2)][ValidateNotNullOrEmpty()][string]$CommitMessage,
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, Position = 3)][ValidateNotNullOrEmpty()][string]$Branch

    )
    # Publish to GitHub
    Write-Host ('[status]Git version')
    git --version
    Write-Host ('[status]Set git user email to: ' + $UserEmail)
    git config user.email $UserEmail
    Write-Host ('[status]Set git user name to: ' + $UserName)
    git config user.name $UserName
    Write-Host ('[status]Git add all uncommitted changes')
    git add -A
    Write-Host ('[status]Git commit all changes with message: ' + $CommitMessage)
    git commit -a -m $CommitMessage
    Write-Host ('[status]Check git status')
    git status
    Write-Host ('[status]Git push to: ' + $Branch)
    git push --force origin HEAD:refs/heads/$Branch
}