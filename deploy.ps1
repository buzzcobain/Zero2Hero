param(
    [switch]$Release,
    [switch]$Test,
    [switch]$Clean,
    [switch]$Device,
    [switch]$Local
)

# Zero2Hero - Deploy Script
# Usage:
#   .\deploy.ps1           - Run on Pixel (debug, hot reload)
#   .\deploy.ps1 -Release  - Run release build
#   .\deploy.ps1 -Test     - Run all tests with coverage
#   .\deploy.ps1 -Clean    - Clean build cache then run
#   .\deploy.ps1 -Device   - List all connected devices
#   .\deploy.ps1 -Local    - Build to local C: drive instead of network

$FLUTTER     = "C:\Users\netbu\.puro\envs\stable\flutter\bin\flutter.bat"
$ADB         = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$NETWORK_DIR = "\\Dtunes\Harris\Projects\Zero2Hero-build"
$LOCAL_DIR   = "C:\Users\netbu\OneDrive\Desktop\Projects\Zero2Hero\build"

# -- Decide where to build ---------------------------------------------------
# We always build locally to avoid Gradle daemon UNC errors.
# If -Local is not specified, we copy the final APKs to the network share after building.
$env:GRADLE_USER_HOME = "$env:USERPROFILE\.gradle"

if ($Local) {
    Write-Host "Build output -> LOCAL ($LOCAL_DIR)" -ForegroundColor Yellow
} else {
    Write-Host "Build output -> LOCAL with NETWORK copy to $NETWORK_DIR" -ForegroundColor Cyan
}

function Get-PixelDevice {
    $lines = & $ADB devices 2>$null
    foreach ($line in $lines) {
        if ($line -match "^(\S+)\s+device$") {
            return $matches[1]
        }
    }
    return $null
}

# -- List devices ------------------------------------------------------------
if ($Device) {
    Write-Host "Connected devices:" -ForegroundColor Cyan
    & $FLUTTER devices
    exit 0
}

# -- Run tests ---------------------------------------------------------------
if ($Test) {
    Write-Host "Running tests with coverage..." -ForegroundColor Cyan
    & $FLUTTER test --coverage
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Tests passed!" -ForegroundColor Green
    } else {
        Write-Host "Tests failed." -ForegroundColor Red
        exit 1
    }
    exit 0
}

# -- Find device -------------------------------------------------------------
$deviceId = Get-PixelDevice
if (-not $deviceId) {
    Write-Host "ERROR: No Android device found via USB." -ForegroundColor Red
    Write-Host "Make sure USB Debugging is enabled and you tapped Allow on your phone." -ForegroundColor Yellow
    exit 1
}
Write-Host "Found device: $deviceId" -ForegroundColor Green

# -- Clean -------------------------------------------------------------------
if ($Clean) {
    Write-Host "Cleaning build cache..." -ForegroundColor Cyan
    & $FLUTTER clean
    & $FLUTTER pub get
}

# -- Deploy ------------------------------------------------------------------
if ($Release) {
    Write-Host "Building RELEASE and deploying to $deviceId..." -ForegroundColor Cyan
    Write-Host "(No hot reload in release mode)" -ForegroundColor Yellow
    & $FLUTTER run -d $deviceId --release
} else {
    Write-Host "Deploying DEBUG build to $deviceId..." -ForegroundColor Cyan
    Write-Host "Hot reload: r | Hot restart: R | Quit: q" -ForegroundColor Yellow
    & $FLUTTER run -d $deviceId
}

# -- Copy outputs to network share if requested (default) --------------------
if (-not $Local) {
    Write-Host "Copying built APKs to network share..." -ForegroundColor Cyan
    if (-not (Test-Path $NETWORK_DIR)) {
        New-Item -ItemType Directory -Path $NETWORK_DIR -Force | Out-Null
    }
    $apkPath = "build\app\outputs\flutter-apk"
    if (Test-Path $apkPath) {
        Copy-Item -Path "$apkPath\*" -Destination $NETWORK_DIR -Recurse -Force
        Write-Host "Successfully copied built APKs to $NETWORK_DIR" -ForegroundColor Green
    } else {
        Write-Host "No built APKs found at $apkPath to copy." -ForegroundColor Yellow
    }
}
