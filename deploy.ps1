function Deploy-Blog 
{
    param
    (
      [string] $s3BucketName,
      [string] $cloudFrontDistributionId,
      [bool] $runBuild = $true,
      [bool] $sync = $true, 
      [bool] $invalidate = $true
	)
    
    if ($runBuild)
    {
        Write-Host "Building blog"
        bundle exec jekyll build    
    }
    
    if ($sync)
    {
        Write-Host "Synchronizing _site with bucket"
        aws s3 sync s3://$s3BucketName _site/
    }
    else
    {
        Write-Host "Clearing bucket"
        aws s3 rm s3://$s3BucketName --recursive

        Write-Host "Uploading site to bucket"
        aws s3 cp ./_site s3://$s3BucketName --acl public-read --recursive   
    }
    
    if ($invalidate)
    {
        Write-Host "Invalidate CloudFormation distribution"
        aws cloudfront create-invalidation --distribution-id $cloudFrontDistributionId --paths "/*"   
    }
 
}

