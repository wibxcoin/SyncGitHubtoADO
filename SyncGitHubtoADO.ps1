param(
    [Parameter()]
    [string]$ADODestinationPAT,

    [Parameter()]
    [string]$GitHubSourcePAT,
    
    [Parameter()]
    [string]$AzureRepoName,
    
    [Parameter()]
    [string]$ADOCloneURL,
    
    [Parameter()]
    [string]$GitHubCloneURL
)

Write-Host ' - - - - - - - - - - - - - - - - - - - - - - - - -'
Write-Host ' reflect Azure Devops repo changes to GitHub repo'
Write-Host ' - - - - - - - - - - - - - - - - - - - - - - - - - '

$stageDir = pwd | Split-Path
Write-Host "stage Dir is : $stageDir"
$githubDir = Join-Path $stageDir "gitHub"
Write-Host "github Dir : $githubDir"

$sourceURL = "https://$($GitHubSourcePAT)@$($GitHubCloneURL)"
write-host "source URL : $sourceURL"
$destURL = "https://$($ADODestinationPAT)@$($ADOCloneURL)"
write-host "dest URL : $destURL"

# Check if the directory exists and delete
if (Test-Path -path $githubDir) {
    Remove-Item -Path $githubDir -Recurse -force
}
# Create the directory and clone the repo
New-Item -ItemType directory -Path $githubDir
Set-Location $githubDir
git clone --mirror $sourceURL

# Verify the cloned repo directory
$clonedRepoDir = Get-ChildItem $githubDir | Where-Object { $_.PSIsContainer } | Select-Object -First 1
if ($null -eq $clonedRepoDir) {
    Write-Host "Cloning failed or the cloned directory is not found."
    exit
}
$destination = $clonedRepoDir.FullName
Write-Host "destination: $destination"

Set-Location $destination
Write-Output '*****Git removing remote secondary****'
git remote rm secondary
Write-Output '*****Git remote add****'
git remote add --mirror=fetch secondary $destURL
Write-Output '*****Git fetch origin****'
git fetch $sourceURL
Write-Output '*****Git push secondary****'
git push secondary --all -f
Write-Output '**Azure Devops repo synced with Github repo**'
Set-Location $stageDir

# Clean up
if (Test-Path -path $githubDir) {
    Remove-Item -Path $githubDir -Recurse -force
}
write-host "Job completed"
