# Accept all Android SDK licenses automatically
Write-Host "Accepting Android SDK licenses..." -ForegroundColor Green

# Run the command with 'y' responses
$yes = "y`ny`ny`ny`ny`ny`ny`ny`ny`n"
$yes | flutter doctor --android-licenses

Write-Host "Done! Licenses should be accepted." -ForegroundColor Green




