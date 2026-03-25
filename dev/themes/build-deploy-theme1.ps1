# ===============================================
# Script PowerShell : generer, build et deployer
# theme Liferay (modules only - version finale)
# ===============================================

# Variables
$bladeJar      = "C:\Users\mashk\IdeaProjects\liferay-blade-cli\cli\build\libs\blade.jar"
$workspaceRoot = "C:\Users\mashk\IdeaProjects\liferay-work\dev"
$modulesDir    = Join-Path $workspaceRoot "modules"
$deployDir     = "C:\Users\mashk\IdeaProjects\liferay-work\infra\liferay\deploy"

$themeName     = "rafaros-theme"
$companyName   = "Rafaros-IT"
$logoPath      = "C:\Users\mashk\IdeaProjects\logo\MonLogo.png"

$themeDir      = Join-Path $modulesDir $themeName

# -----------------------------
# 0 - Clean ancien theme
# -----------------------------
if (Test-Path $themeDir) {
    Write-Host "Suppression ancien theme dans modules..."
    Remove-Item -Recurse -Force $themeDir
    Start-Sleep -Seconds 1

    if (Test-Path $themeDir) {
        Write-Error "Impossible de supprimer le theme"
        exit 1
    }
}

# -----------------------------
# 1 - Creation theme (IMPORTANT: depuis root)
# -----------------------------
cd $workspaceRoot
Write-Host "Creation du theme..."
java -jar $bladeJar create -t theme $themeName

if (-Not (Test-Path $themeDir)) {
    Write-Error "Echec creation theme dans modules"
    exit 1
}

# -----------------------------
# 2 - Logo
# -----------------------------
$imgDir = Join-Path $themeDir "src\images"
New-Item -ItemType Directory -Force -Path $imgDir | Out-Null
Copy-Item $logoPath (Join-Path $imgDir "MonLogo.png") -Force
Write-Host "Logo copie"

# -----------------------------
# 3 - SCSS
# -----------------------------
$cssDir = Join-Path $themeDir "src\css"
New-Item -ItemType Directory -Force -Path $cssDir | Out-Null

$scss = Join-Path $cssDir "_custom.scss"

Set-Content $scss '$navbar-logo-image: "../images/MonLogo.png";'
Add-Content $scss ('$navbar-logo-alt: "' + $companyName + '";')

Write-Host "SCSS configure"

# -----------------------------
# 4 - Build Gradle
# -----------------------------
cd $workspaceRoot

if (Test-Path ".\gradlew.bat") {
    Write-Host "Build Gradle..."
  #  .\gradlew ":modules:$themeName:build"
    .\gradlew (":modules:" + $themeName + ":build")
} else {
    Write-Error "gradlew introuvable"
    exit 1
}

# -----------------------------
# 5 - Deploy
# -----------------------------
$war = Get-ChildItem "$themeDir\build\libs\*.war" -ErrorAction SilentlyContinue

if ($war) {
    Copy-Item $war.FullName $deployDir -Force
    Write-Host "Deploy OK"
} else {
    Write-Error "WAR non trouve"
}