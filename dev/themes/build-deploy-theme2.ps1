# ===============================================
# Build et déploiement Liferay Theme
# ===============================================

$bladeJar      = "C:\Users\mashk\IdeaProjects\liferay-blade-cli\cli\build\libs\blade.jar"
$workspaceRoot = "C:\Users\mashk\IdeaProjects\liferay-work\dev"
$modulesDir    = Join-Path $workspaceRoot "modules"
$deployDir     = "C:\Users\mashk\IdeaProjects\liferay-work\infra\liferay\deploy"

$themeName     = "rafaros-theme"
$companyName   = "Rafaros-IT"
$logoPath      = "C:\Users\mashk\IdeaProjects\logo\MonLogo.png"
$themeDir      = Join-Path $modulesDir $themeName

# -----------------------------
# 0 - Supprimer ancien thème
# -----------------------------
if (Test-Path $themeDir) {
    Write-Host "Suppression ancien thème dans modules..."
    Remove-Item -Recurse -Force $themeDir
    Start-Sleep -Seconds 1
    if (Test-Path $themeDir) {
        Write-Error "Impossible de supprimer le thème"
        exit 1
    }
}

# -----------------------------
# 1 - Créer le thème
# -----------------------------
cd $workspaceRoot
Write-Host "Création du thème..."
java -jar $bladeJar create -t theme $themeName

if (-Not (Test-Path $themeDir)) {
    Write-Error "Échec de création du thème"
    exit 1
}

# -----------------------------
# 2 - Copier le logo
# -----------------------------
$imgDir = Join-Path $themeDir "src\images"
if (-Not (Test-Path $imgDir)) { New-Item -ItemType Directory -Force -Path $imgDir | Out-Null }
Copy-Item $logoPath (Join-Path $imgDir "MonLogo.png") -Force
Write-Host "Logo copié"

# -----------------------------
# 3 - Configurer SCSS
# -----------------------------
$cssDir = Join-Path $themeDir "src\css"
if (-Not (Test-Path $cssDir)) { New-Item -ItemType Directory -Force -Path $cssDir | Out-Null }
$scss = Join-Path $cssDir "_custom.scss"
$scssContent = @"
\$navbar-brand-image: "images/MonLogo.png";
\$navbar-brand-text: "$companyName";
"@
Set-Content -Path $scss -Value $scssContent -Force
Write-Host "_custom.scss configuré"

# -----------------------------
# 4 - S'assurer que le module est dans settings.gradle
# -----------------------------
$settingsGradle = Join-Path $workspaceRoot "settings.gradle"
if (-Not (Get-Content $settingsGradle | Select-String ":$themeName")) {
    Add-Content -Path $settingsGradle -Value "`ninclude ':$themeName'"
    Write-Host "Ajout du module $themeName dans settings.gradle"
}

# -----------------------------
# 5 - Build le thème
# -----------------------------
if (Test-Path "$workspaceRoot\gradlew.bat") {
    Write-Host "Build Gradle depuis le module..."
    # Build depuis le dossier du module pour éviter les erreurs de chemin
    cd $themeDir
    ..\..\gradlew clean build
} else {
    Write-Error "gradlew introuvable"
    exit 1
}

# -----------------------------
# 6 - Copier le WAR dans deploy
# -----------------------------
$war = Get-ChildItem "$themeDir\build\libs\*.war" -ErrorAction SilentlyContinue
if ($war) {
    Copy-Item $war.FullName $deployDir -Force
    Write-Host "Deploy OK : $($war.Name)"
} else {
    Write-Error "WAR non trouvé. Vérifie le build Gradle"
}

# -----------------------------
# 7 - Info finale
# -----------------------------
Write-Host "`nScript terminé. Applique le thème depuis le Control Panel."
Write-Host "Si le logo ou le nom n'apparaît pas, vide le cache du thème dans Liferay (Server Administration → Clear Cache)."