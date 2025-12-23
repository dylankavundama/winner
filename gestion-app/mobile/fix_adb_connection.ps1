# ADB Connection Troubleshooting Script
# This script helps fix common ADB installation issues

Write-Host "=== ADB Connection Troubleshooting ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Kill and restart ADB server
Write-Host "Step 1: Restarting ADB server..." -ForegroundColor Yellow
adb kill-server
Start-Sleep -Seconds 2
adb start-server
Start-Sleep -Seconds 2

# Step 2: Check connected devices
Write-Host "`nStep 2: Checking connected devices..." -ForegroundColor Yellow
$devices = adb devices
Write-Host $devices

# Step 3: Try to reconnect devices
Write-Host "`nStep 3: Attempting to reconnect devices..." -ForegroundColor Yellow
adb reconnect
Start-Sleep -Seconds 3

# Step 4: Check devices again
Write-Host "`nStep 4: Checking devices after reconnect..." -ForegroundColor Yellow
adb devices -l

# Step 5: Check if app is already installed
Write-Host "`nStep 5: Checking if app is already installed..." -ForegroundColor Yellow
$appInstalled = adb shell pm list packages | Select-String "com.winnercompany.app"
if ($appInstalled) {
    Write-Host "App is already installed. Attempting to uninstall..." -ForegroundColor Yellow
    adb uninstall com.winnercompany.app
    Start-Sleep -Seconds 2
}

Write-Host "`n=== Troubleshooting Complete ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "If device is still offline, try:" -ForegroundColor Yellow
Write-Host "1. Unplug and replug the USB cable" -ForegroundColor White
Write-Host "2. Enable USB debugging on your device (Settings > Developer Options)" -ForegroundColor White
Write-Host "3. Check for 'Allow USB debugging?' popup on your device and click 'Allow'" -ForegroundColor White
Write-Host "4. Try a different USB cable or USB port" -ForegroundColor White
Write-Host "5. Install proper USB drivers for your device" -ForegroundColor White
Write-Host ""
Write-Host "After fixing the connection, run: flutter run" -ForegroundColor Green

