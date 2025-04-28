# BBUsers Tool Installer
Write-Host "Installing BBUsers Management Tool..." -ForegroundColor Cyan

# Create installation directory
$installDir = "$env:USERPROFILE\BBUsersTool"
if (!(Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir -Force | Out-Null
    Write-Host "Created installation directory: $installDir" -ForegroundColor Green
}

# Download required files
$baseUrl = "https://raw.githubusercontent.com/bziobnic/bbusers/main"
$files = @(
    "BBUsersGUI.xaml",
    "BBUsersGUI.ps1",
    "Get-BBUsers.ps1"
)

foreach ($file in $files) {
    Write-Host "Downloading $file..." -ForegroundColor Yellow
    Invoke-RestMethod -Uri "$baseUrl/$file" -OutFile "$installDir\$file"
}

# Create shortcut in Start Menu
$startMenuPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\BBUsers Tool"
if (!(Test-Path $startMenuPath)) {
    New-Item -ItemType Directory -Path $startMenuPath -Force | Out-Null
}

$shortcutPath = "$startMenuPath\BBUsers Tool.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$installDir\BBUsersGUI.ps1`""
$shortcut.WorkingDirectory = $installDir
$shortcut.IconLocation = "powershell.exe,0"
$shortcut.Save()

# Optional: Create desktop shortcut
$desktopPath = [Environment]::GetFolderPath("Desktop")
$desktopShortcut = "$desktopPath\BBUsers Tool.lnk"
$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($desktopShortcut)
$shortcut.TargetPath = "powershell.exe"
$shortcut.Arguments = "-ExecutionPolicy Bypass -File `"$installDir\BBUsersGUI.ps1`""
$shortcut.WorkingDirectory = $installDir
$shortcut.IconLocation = "powershell.exe,0"
$shortcut.Save()

Write-Host "`nBBUsers Tool has been successfully installed!" -ForegroundColor Green
Write-Host "You can find it in your Start Menu or on your Desktop." -ForegroundColor Green
Write-Host "Or run it directly from: $installDir\BBUsersGUI.ps1" -ForegroundColor Green

# Optional: Run the tool immediately
$runNow = Read-Host "Would you like to run BBUsers Tool now? (Y/N)"
if ($runNow -eq 'Y' -or $runNow -eq 'y') {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -File `"$installDir\BBUsersGUI.ps1`""
}
