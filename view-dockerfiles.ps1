# Script to view Dockerfile contents

Write-Host "=== Backend JS Dockerfile ===" -ForegroundColor Cyan
Get-Content -Path "docker\backend-js\Dockerfile" -ErrorAction SilentlyContinue

Write-Host "`n=== Backend Java Dockerfile ===" -ForegroundColor Cyan
Get-Content -Path "docker\backend-java\Dockerfile" -ErrorAction SilentlyContinue

Write-Host "`n=== Nginx Dockerfile ===" -ForegroundColor Cyan
Get-Content -Path "docker\nginx\Dockerfile" -ErrorAction SilentlyContinue
