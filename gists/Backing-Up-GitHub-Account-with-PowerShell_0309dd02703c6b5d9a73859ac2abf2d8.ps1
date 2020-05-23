$backupDirectory = '{BACKUP ROOT DIRECTORY}'
$token = '{GIT USERNAME}:{PERSONAL ACCESS TOKEN}'
$base64Token = [System.Convert]::ToBase64String([char[]]$token)

$headers = @{
    Authorization = 'Basic {0}' -f $base64Token
};

Set-Location -Path $backupDirectory
$page = 1
$perPage = 30

Do
{
    Write-Host "Getting page: $page"
    $response = Invoke-RestMethod -Headers $headers -Uri "https://api.github.com/user/repos?page=$page&per_page=$perPage"
    
    foreach ($repo in $response)
    {
        $repoName = $repo.name
        $repoPath = "$backupDirectory/$repoName"

        Write-Host "Processing repo at path: $repoPath"

        if ( (Test-Path $repoPath) -eq 0)
        {
            Write-Host "Repo doesn't exist, clone it"
            git clone $repo.ssh_url
        }
        else 
        {
            Write-Host "Repo exists, update"

            # Change to repo directory to fetch updates
            Set-Location -Path $repoPath

            git fetch --all
            git reset --hard origin/master

            # Change back to root backup directory
            Set-Location -Path $backupDirectory
        }
    }
    
    $page = $page + 1
}
While ($response.Count -gt 0)