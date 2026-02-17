# Configuration de l'encodage
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# 1. Génération du rapport
$reportPath = "$env:TEMP\battery-report.html"
powercfg /batteryreport /output $reportPath | Out-Null
$content = Get-Content $reportPath -Raw -Encoding UTF8

# 2. Fonctions d'extraction
function Get-SystemModel {
    if ($content -match "SYSTEM PRODUCT NAME\s*</td><td>(.*?)</td>") { return $Matches[1].Trim() }
    return "Modèle Inconnu"
}
function Get-BattText($key) {
    if ($content -match "label"">$key</span></td><td>(.*?)</td>") { return $Matches[1].Trim() }
    return "Inconnu"
}
function Get-BattValue($key) {
    if ($content -match "label"">$key</span></td><td>([\d\s\P{IsBasicLatin}, ]+) mWh") {
        $val = $Matches[1] -replace "[^\d]", ""
        if ($val -ne "") { return [int64]$val }
    }
    return 0
}

# 3. Récupération des données
$sysModel  = Get-SystemModel
$battName  = Get-BattText "NAME"
$mfg       = Get-BattText "MANUFACTURER"
$chemistry = Get-BattText "CHEMISTRY"
$designCap = Get-BattValue "DESIGN CAPACITY"
$fullCap   = Get-BattValue "FULL CHARGE CAPACITY"
$battWMI   = Get-CimInstance -ClassName Win32_Battery
$voltageV  = if ($battWMI.DesignVoltage) { [math]::Round($battWMI.DesignVoltage / 1000, 2) } else { "Inconnu" }
$cycles    = if ($content -match "CYCLE COUNT</span></td><td>\s*(\d+)") { $Matches[1] } else { "N/A" }
$health    = if ($designCap -gt 0) { [math]::Round(($fullCap / $designCap) * 100, 1) } else { 0 }

# --- CONFIGURATION COULEURS ---
$colorBG     = [System.Drawing.ColorTranslator]::FromHtml("#161724")
$colorBlock  = [System.Drawing.ColorTranslator]::FromHtml("#1D1E2E")
$colorTitle  = [System.Drawing.ColorTranslator]::FromHtml("#7542DF")
$colorBtn    = [System.Drawing.ColorTranslator]::FromHtml("#004E70")
$colorWhite  = [System.Drawing.Color]::White

# 4. Interface Graphique
$form = New-Object System.Windows.Forms.Form
$form.Text = "Info Batterie - $sysModel"
$form.Size = New-Object System.Drawing.Size(600, 600)
$form.StartPosition = "CenterScreen"
$form.BackColor = $colorBG
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

$iconPath = Join-Path $PSScriptRoot "batterie.ico"
if (Test-Path $iconPath) { $form.Icon = New-Object System.Drawing.Icon($iconPath) }

$mainTitle = New-Object System.Windows.Forms.Label
$mainTitle.Text = "Ordinateur : $sysModel"
$mainTitle.Font = New-Object System.Drawing.Font("Segoe UI", 12, [System.Drawing.FontStyle]::Bold)
$mainTitle.ForeColor = $colorTitle
$mainTitle.Location = New-Object System.Drawing.Point(20, 15)
$mainTitle.Size = New-Object System.Drawing.Size(540, 30)
$form.Controls.Add($mainTitle)

# --- FONCTION CORRIGÉE (Types forcés [int]) ---
function New-DashboardBlock([string]$title, [string]$text, [int]$posX, [int]$posY, [int]$width, [int]$height) {
    $p = New-Object System.Windows.Forms.Panel
    $p.Location = New-Object System.Drawing.Point($posX, $posY)
    $p.Size = New-Object System.Drawing.Size($width, $height)
    $p.BackColor = $colorBlock
    
    $lt = New-Object System.Windows.Forms.Label
    $lt.Text = $title
    $lt.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
    $lt.ForeColor = $colorTitle
    $lt.Location = New-Object System.Drawing.Point(15, 12)
    $lt.AutoSize = $true
    $p.Controls.Add($lt)

    $li = New-Object System.Windows.Forms.Label
    $li.Text = $text
    $li.Font = New-Object System.Drawing.Font("Segoe UI", 11)
    $li.ForeColor = $colorWhite
    $li.Location = New-Object System.Drawing.Point(15, 38)
    $li.Size = New-Object System.Drawing.Size(($width - 25), ($height - 45))
    $p.Controls.Add($li)
    return $p
}

# Blocs Fiche Technique

$txtFiche = "• Fabricant : $mfg`n• Modèle : $battName`n• Chimie : $chemistry`n• Voltage : $voltageV V"
$blockFiche = New-DashboardBlock "Fiche Technique" $txtFiche 20 60 270 130
$form.Controls.Add($blockFiche)

# Blocs Capacités

$txtCap = "• Usine : $designCap mWh`n• Actuelle : $fullCap mWh`n• Cycles : $cycles"
$blockCap = New-DashboardBlock "Capacités" $txtCap 300 60 260 130
$form.Controls.Add($blockCap)

# Bloc Santé
$blockHealth = New-Object System.Windows.Forms.Panel
$blockHealth.Location = New-Object System.Drawing.Point(20, 205)
$blockHealth.Size = New-Object System.Drawing.Size(540, 100)
$blockHealth.BackColor = $colorBlock

$healthTitle = New-Object System.Windows.Forms.Label
$healthTitle.Text = "Santé de la Batterie"
$healthTitle.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$healthTitle.ForeColor = $colorTitle
$healthTitle.Location = New-Object System.Drawing.Point(15, 10)
$healthTitle.AutoSize = $true
$blockHealth.Controls.Add($healthTitle)

$healthValLabel = New-Object System.Windows.Forms.Label
$healthValLabel.Text = "$health %"
$healthValLabel.Font = New-Object System.Drawing.Font("Segoe UI", 22, [System.Drawing.FontStyle]::Bold)
$healthValLabel.ForeColor = $colorWhite
$healthValLabel.Location = New-Object System.Drawing.Point(15, 35)
$healthValLabel.AutoSize = $true
$blockHealth.Controls.Add($healthValLabel)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(150, 48)
$progressBar.Size = New-Object System.Drawing.Size(365, 25)
$progressBar.Value = [int][math]::Min($health, 100)
$blockHealth.Controls.Add($progressBar)
$form.Controls.Add($blockHealth)

# Bloc Charge Dynamique
$blockCharge = New-Object System.Windows.Forms.Panel
$blockCharge.Location = New-Object System.Drawing.Point(20, 320)
$blockCharge.Size = New-Object System.Drawing.Size(540, 90)
$blockCharge.BackColor = $colorBlock

$chargeTitle = New-Object System.Windows.Forms.Label
$chargeTitle.Text = "Niveau de Charge Actuel"
$chargeTitle.Font = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Bold)
$chargeTitle.ForeColor = $colorTitle
$chargeTitle.Location = New-Object System.Drawing.Point(15, 10)
$chargeTitle.AutoSize = $true
$blockCharge.Controls.Add($chargeTitle)

$chargeLabel = New-Object System.Windows.Forms.Label
$chargeLabel.Text = "Calcul..."
$chargeLabel.Font = New-Object System.Drawing.Font("Segoe UI", 18, [System.Drawing.FontStyle]::Bold)
$chargeLabel.ForeColor = $colorWhite
$chargeLabel.Location = New-Object System.Drawing.Point(15, 38)
$chargeLabel.Size = New-Object System.Drawing.Size(510, 40)
$chargeLabel.TextAlign = "MiddleCenter"
$blockCharge.Controls.Add($chargeLabel)
$form.Controls.Add($blockCharge)

# --- TIMER ---
$hasBeeped = $false
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000 
$timer.Add_Tick({
    $statusWMI = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
    $charge = $statusWMI.EstimatedChargeRemaining
    $stCode = $statusWMI.BatteryStatus 

    if ($charge -eq 100) {
        $chargeLabel.Text = "100 % (TERMINÉE)"
        $chargeLabel.ForeColor = [System.Drawing.Color]::ForestGreen
        if (-not $hasBeeped -and ($stCode -eq 2 -or $stCode -eq 6)) {
            [System.Media.SystemSounds]::Exclamation.Play()
            $hasBeeped = $true
        }
    }
    elseif ($stCode -eq 2 -or $stCode -eq 6) {
        $chargeLabel.Text = "$charge % (SUR SECTEUR)"
        $chargeLabel.ForeColor = [System.Drawing.Color]::DodgerBlue
        $hasBeeped = $false 
    }
    else {
        $chargeLabel.Text = "$charge % (DÉCHARGE)"
        $chargeLabel.ForeColor = [System.Drawing.Color]::Orange
        $hasBeeped = $false
    }
})
$timer.Start()

# --- BOUTONS ---
function New-StyledButton($text, $posX, $posY) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $text
    $b.Location = New-Object System.Drawing.Point($posX, $posY)
    $b.Size = New-Object System.Drawing.Size(165, 45)
    $b.BackColor = $colorBtn
    $b.ForeColor = $colorWhite
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderSize = 0
    $b.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
    return $b
}

$btnRapport = New-StyledButton "Rapport Détaillé" 20 440
$btnRapport.Add_Click({ Start-Process $reportPath })
$form.Controls.Add($btnRapport)

$btnParam = New-StyledButton "Paramètres Batterie" 205 440
$btnParam.Add_Click({ Start-Process "ms-settings:batterysaver" })
$form.Controls.Add($btnParam)

$btnAlim = New-StyledButton "Option d'Alimentation" 395 440
$btnAlim.Add_Click({ Start-Process "powercfg.cpl" })
$form.Controls.Add($btnAlim)

$form.Add_FormClosing({ $timer.Stop() })
$form.ShowDialog() | Out-Null