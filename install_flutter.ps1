$targetDir = "C:\src"
if (!(Test-Path $targetDir)) { 
    New-Item -ItemType Directory -Path $targetDir 
}
$targetFlutter = "C:\src\flutter"
$zipFile = "C:\src\flutter_sdk.zip"

Write-Host "--- Starting Flutter Installation ---"
Write-Host "Downloading Flutter SDK... (~1GB)"
Invoke-WebRequest -Uri "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.41.6-stable.zip" -OutFile $zipFile

Write-Host "Extracting files to $targetDir..."
Expand-Archive -Path $zipFile -DestinationPath $targetDir -Force

Write-Host "Cleaning up..."
Remove-Item $zipFile

Write-Host "--- Flutter Installed Successfully at C:\src\flutter ---"
