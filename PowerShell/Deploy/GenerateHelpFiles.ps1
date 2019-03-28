# Load config
. ($PSScriptRoot + '\' + 'Config.ps1')
# Import module
Import-Module ($File_Psm1) -Force
# Install PlatyPS
Install-Module -Name:('PlatyPS') -Force
# Create/Update markdown help files
Write-Host ('[status]Creating/Updating help files')
$Functions_Public | ForEach-Object {
    $FunctionName = $_.BaseName
    $FilePath_Md = $Folder_Docs + '\' + $FunctionName + '.md'
    If (Test-Path -Path:($FilePath_Md))
    {
        Update-MarkdownHelp -Path:($FilePath_Md) -Force
    }
    Else
    {
        New-MarkdownHelp  -Command:($FunctionName) -OutputFolder:($Folder_Docs) -Force
    }
}
# Create new ExternalHelp file
Write-Host ('[status]Creating new external help file')
New-ExternalHelp -Path:($Folder_Docs) -OutputPath:($Folder_HelpFiles) -Force
# Publish new help files
Write-Host ('[status]Publishing to GitHub:' + $GitCurrentBranch + ':' + $GitCommitMessage_HelpFiles)
Publish-ToGitHub -UserEmail:($GitUserEmail) -UserName:($GitUserName) -CommitMessage:($GitCommitMessage_HelpFiles) -Branch:($GitCurrentBranch)
# Validate that help files have been populated
Write-Host ('[status]Validating help file fields have been populated')
$HelpFilePopulation = Get-ChildItem -Path:($Folder_Docs) | Select-String -Pattern:('(\{\{)(.*?)(\}\})')
If ($HelpFilePopulation)
{
    $HelpFilePopulation
    Write-Error ('Go populate the help files!')
}

# Get-Command -Module:('PlatyPS') | % { "Get-Help -Name:('$_')"}
# Get-Help -Name:('Get-HelpPreview')
# Get-Help -Name:('Get-MarkdownMetadata')

# Get-Help -Name:('New-ExternalHelp')
# Get-Help -Name:('New-ExternalHelpCab')
# Get-Help -Name:('New-MarkdownAboutHelp')
# Get-Help -Name:('New-YamlHelp')
# Get-Help -Name:('Update-MarkdownHelpModule')

# Get-Help -Name:('Merge-MarkdownHelp')
# Get-Help -Name:('New-MarkdownHelp') -Examples
# Get-Help -Name:('Update-MarkdownHelp') -Examples