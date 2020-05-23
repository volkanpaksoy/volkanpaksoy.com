#! /bin/bash

backupDir='/repos'
token='{GITHUB USERNAME}:{PERSONAL ACCESS TOKEN}'
base64Token=$(echo -n $token | base64)

cd $backupDir
page=1
perPage=30
url="https://api.github.com/user/repos?page=$page&per_page=$perPage"

response=$(curl -H "Authorization: Basic $base64Token" $url)
#echo $response

for row in $(echo "${response}" | jq -r '.[] | @base64'); do
    _jq() {
      echo ${row} | base64 -d | jq -r ${1}
    }

   repoName=$(echo $(_jq '.name'))
   repoUrl=$(echo $(_jq '.ssh_url'))
   repoPath=$backupDir/$repoName

    if [ ! -d "$repoPath" ]; then
      echo "Repo doesn't exist, clone it"
      git clone $repoUrl
    else
      echo "Repo exists, update"
      cd $repoPath
      git fetch --all
      git reset --hard origin/master
      cd $backupDir
    fi
done
