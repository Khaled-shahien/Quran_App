<#
Builds the signed Google Play App Bundle for Sakina.

Run from the repository root in PowerShell:
    powershell -ExecutionPolicy Bypass -File scripts\build_release.ps1

Stops at the first failing step. Produces:
    build\app\outputs\bundle\release\app-release.aab        (upload to Play)
    build\app\outputs\mapping\release\mapping.txt           (upload as deobfuscation file)
    build\release-archive\<version>\                        (AAB + Dart symbols + mapping; back this up outside the repo)
#>
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)

function Step($name, [scriptblock]$action) {
    Write-Host "`n==> $name" -ForegroundColor Cyan
    & $action
    if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "Failed: $name (exit $LASTEXITCODE)" }
}

Step 'Check Flutter channel is stable' {
    $version = flutter --version 2>&1 | Out-String
    if ($version -notmatch 'channel stable') {
        throw "Release builds must use the stable channel. Run: flutter channel stable; flutter upgrade`n$version"
    }
    Write-Host ($version -split "`n")[0]
}

Step 'Check release inputs' {
    if (-not (Test-Path 'android\key.properties')) { throw 'android\key.properties is missing (upload key).' }
    if (-not (Test-Path '.env')) { throw '.env is missing (YOUTUBE_API_KEY).' }
    if (-not (Test-Path 'android\app\google-services.json')) { throw 'android\app\google-services.json is missing.' }
}

Step 'flutter pub get' { flutter pub get }
Step 'Generate localizations' { flutter gen-l10n }
Step 'Verify formatting' { dart format --output=none --set-exit-if-changed lib test integration_test scripts }
Step 'Scan for committed secrets' { dart run scripts/check_secrets.dart }
Step 'Static analysis' { flutter analyze --no-pub }
Step 'Unit and widget tests' { flutter test --no-pub }

$python = Get-Command python -ErrorAction SilentlyContinue
if ($python) {
    Step 'Religious content integrity' { python scripts/verify_content.py }
} else {
    Write-Host 'Python not found: skipping content integrity check (CI still runs it).' -ForegroundColor Yellow
}

Step 'Build signed App Bundle' {
    # Without --no-pub so the plugin registrant is regenerated for release
    # (the test step leaves one that lists dev-only plugins such as integration_test).
    flutter build appbundle --release `
        --obfuscate --split-debug-info=build/symbols/android `
        --dart-define=APP_ENV=production `
        --dart-define-from-file=.env
}

$versionLine = (Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(.+)$').Matches[0].Groups[1].Value.Trim()
$archive = Join-Path 'build\release-archive' ($versionLine -replace '\+', '_build')
New-Item -ItemType Directory -Force -Path $archive | Out-Null
Copy-Item 'build\app\outputs\bundle\release\app-release.aab' $archive
Copy-Item -Recurse -Force 'build\symbols\android' (Join-Path $archive 'dart-symbols')
if (Test-Path 'build\app\outputs\mapping\release\mapping.txt') {
    Copy-Item 'build\app\outputs\mapping\release\mapping.txt' $archive
}
git rev-parse HEAD 2>$null | Out-File (Join-Path $archive 'commit.txt')

Write-Host "`nDone. Version $versionLine" -ForegroundColor Green
Write-Host "Upload: build\app\outputs\bundle\release\app-release.aab"
Write-Host "Archive (back up outside the repo): $archive"
