# Load config
. ($PSScriptRoot + '\' + 'Config.ps1')
# Publish-ToGitHub
Write-Host ('[status]Publishing to GitHub:' + $GitTargetBranch)
Publish-ToGitHub -UserEmail:($GitUserEmail) -UserName:($GitUserName) -CommitMessage:($GitCommitMessage_BuildModule) -Branch:($GitTargetBranch)