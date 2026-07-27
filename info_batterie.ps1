# ============================================================
# Info Batterie — ofbridge_lab
# Style : Cyber-HUD Tech-Noir (réf. Palette.cs — TechFixerHub.NET)
# ============================================================
# Source de vérité de version : fichier VERSION à la racine du projet.
# Garder $ScriptVersion synchronisé avec VERSION à chaque bump (convention §1).
$ScriptVersion = "2.1.001"

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ============================================================
# RAPPORT
# ============================================================
$reportPath = "$env:TEMP\battery-report.html"
powercfg /batteryreport /output $reportPath | Out-Null
$content = Get-Content $reportPath -Raw -Encoding UTF8

# ============================================================
# EXTRACTION  (support mono ET multi-batterie)
# ============================================================
function Get-SystemModel {
    if ($content -match "SYSTEM PRODUCT NAME\s*</td><td>(.*?)</td>") { return $Matches[1].Trim() }
    return "Unknown Device"
}

# Récupère TOUTES les valeurs d'un label (une par batterie installée), dans l'ordre du rapport.
function Get-BattTextAll($key) {
    $opt = [System.Text.RegularExpressions.RegexOptions]::Singleline
    $ms  = [regex]::Matches($content, "label"">$key</span></td><td>(.*?)</td>", $opt)
    $out = [System.Collections.Generic.List[string]]::new()
    foreach ($m in $ms) {
        $v = ($m.Groups[1].Value -replace '<[^>]+>', '').Trim()
        $out.Add($(if ($v -eq "" -or $v -eq "-") { "—" } else { $v }))
    }
    return $out
}
function Get-BattValueAll($key) {
    $opt = [System.Text.RegularExpressions.RegexOptions]::Singleline
    $ms  = [regex]::Matches($content, "label"">$key</span></td><td>([\d\s\P{IsBasicLatin}, ]+?) mWh", $opt)
    $out = [System.Collections.Generic.List[int64]]::new()
    foreach ($m in $ms) {
        $val = $m.Groups[1].Value -replace "[^\d]", ""
        $out.Add($(if ($val -ne "") { [int64]$val } else { [int64]0 }))
    }
    return $out
}

$sysModel = Get-SystemModel

# Assemble la liste des batteries en zippant les colonnes par index.
$namesL   = Get-BattTextAll  "NAME"
$mfgL     = Get-BattTextAll  "MANUFACTURER"
$chemL    = Get-BattTextAll  "CHEMISTRY"
$designL  = Get-BattValueAll "DESIGN CAPACITY"
$fullL    = Get-BattValueAll "FULL CHARGE CAPACITY"
$cycOpt   = [System.Text.RegularExpressions.RegexOptions]::Singleline
$cycMs    = [regex]::Matches($content, "CYCLE COUNT</span></td><td>\s*(\d+)", $cycOpt)

$nbBatt = [Math]::Max($namesL.Count, $designL.Count)
if ($nbBatt -lt 1) { $nbBatt = 1 }

$batteries = [System.Collections.Generic.List[PSObject]]::new()
for ([int]$i = 0; $i -lt $nbBatt; $i++) {
    $batteries.Add([PSCustomObject]@{
        Name      = if ($i -lt $namesL.Count)  { $namesL[$i] }  else { "Batterie $($i+1)" }
        Mfg       = if ($i -lt $mfgL.Count)    { $mfgL[$i] }    else { "—" }
        Chemistry = if ($i -lt $chemL.Count)   { $chemL[$i] }   else { "—" }
        DesignCap = if ($i -lt $designL.Count) { $designL[$i] } else { [int64]0 }
        FullCap   = if ($i -lt $fullL.Count)   { $fullL[$i] }   else { [int64]0 }
        Cycles    = if ($i -lt $cycMs.Count)   { $cycMs[$i].Groups[1].Value } else { "N/A" }
        Health    = 0.0
    })
}
foreach ($b in $batteries) {
    $b.Health = if ($b.DesignCap -gt 0) { [math]::Round(($b.FullCap / $b.DesignCap) * 100, 1) } else { 0 }
}

# Agrégats pack (santé globale calculée sur les totaux — correct pour 1 ou N batteries)
$battName  = $batteries[0].Name
$mfg       = $batteries[0].Mfg
$chemistry = $batteries[0].Chemistry
$designCap = ($batteries | Measure-Object -Property DesignCap -Sum).Sum
$fullCap   = ($batteries | Measure-Object -Property FullCap   -Sum).Sum
$cyclesList = ($batteries | ForEach-Object { $_.Cycles })
$cycles    = ($cyclesList -join " / ")
$health    = if ($designCap -gt 0) { [math]::Round(($fullCap / $designCap) * 100, 1) } else { 0 }

$battWMI   = @(Get-CimInstance -ClassName Win32_Battery)
$dv0       = if ($battWMI.Count -gt 0) { @($battWMI[0].DesignVoltage)[0] } else { $null }
$voltageV  = if ($dv0) { [math]::Round($dv0 / 1000, 2) } else { "—" }

# ── Contenu des cartes (adapté au nombre de batteries) ──────
if ($nbBatt -le 1) {
    $ficheText = "• Fabricant : $mfg`n• Modèle : $battName`n• Chimie : $chemistry`n• Voltage : $voltageV V"
    $capText   = "• Usine : {0:N0} mWh`n• Actuelle : {1:N0} mWh`n• Cycles : {2}" -f $designCap, $fullCap, $cycles
} else {
    $sbF = "• Batteries : $nbBatt   ·   $voltageV V`n"
    [int]$k = 1
    foreach ($b in $batteries) {
        $sbF += "• B$k : $($b.Mfg) · $($b.Chemistry)`n"; $k++
    }
    $ficheText = $sbF.TrimEnd("`n")

    $detD = ($batteries | ForEach-Object { '{0:N0}' -f $_.DesignCap }) -join " / "
    $detF = ($batteries | ForEach-Object { '{0:N0}' -f $_.FullCap })   -join " / "
    $capText = "• Usine (tot.) : {0:N0} mWh`n• Actuelle (tot.) : {1:N0} mWh`n• Détail usine : {2}`n• Détail act. : {3}`n• Cycles : {4}" -f `
        $designCap, $fullCap, $detD, $detF, $cycles
}

# ============================================================
# PALETTE — Cyber-HUD Tech-Noir (réf. Palette.cs — TechFixerHub.NET)
# ============================================================
$cBG        = [System.Drawing.ColorTranslator]::FromHtml("#0B0C14")   # Bg     Deep Space Black
$cPanel     = [System.Drawing.ColorTranslator]::FromHtml("#0F1020")   # Panel
$cPanelB    = [System.Drawing.ColorTranslator]::FromHtml("#0D0E1C")   # Panel2
$cBorder    = [System.Drawing.ColorTranslator]::FromHtml("#1F2A33")   # Border
$cAccent    = [System.Drawing.ColorTranslator]::FromHtml("#00D4FF")   # Cyan
$cAccent2   = [System.Drawing.ColorTranslator]::FromHtml("#7B4FFF")   # Violet
$cGreen     = [System.Drawing.ColorTranslator]::FromHtml("#41B375")   # Green  OK / sain
$cAmber     = [System.Drawing.ColorTranslator]::FromHtml("#FF8C00")   # Amber  Avertissement
$cRed       = [System.Drawing.ColorTranslator]::FromHtml("#FF3B3B")   # Red    Danger
$cText      = [System.Drawing.ColorTranslator]::FromHtml("#C8E4FF")   # corps
$cTextMid   = [System.Drawing.ColorTranslator]::FromHtml("#4A7A8C")   # Muted
$cTextDim   = [System.Drawing.ColorTranslator]::FromHtml("#2A4A55")   # Dim
$cWhite     = [System.Drawing.Color]::White

$clrAC      = $cAccent                                                # AC / secteur → Cyan
$clrBatt    = $cAmber                                                 # Batterie     → Amber
$clrSuspend = [System.Drawing.ColorTranslator]::FromHtml("#14202A")  # Veille (teinte Border sombre)
$clrInact   = [System.Drawing.ColorTranslator]::FromHtml("#0D0E1C")  # fond piste inactive (Panel2)

# ============================================================
# TIMELINE DATA
# ============================================================
function Get-TimelineEvents {
    $rows = [regex]::Matches($content,
        '<tr[^>]*class="[^"]*"[^>]*>\s*<td[^>]*class="dateTime"[^>]*><span[^>]*class="date"[^>]*>(.*?)</span>\s*<span[^>]*class="time"[^>]*>(.*?)</span></td>\s*<td[^>]*class="state"[^>]*>\s*(.*?)\s*</td>\s*<td[^>]*>(.*?)</td>\s*<td[^>]*>(.*?)</td>',
        [System.Text.RegularExpressions.RegexOptions]::Singleline)

    $events = [System.Collections.Generic.List[PSObject]]::new()
    $currentDate = ""
    foreach ($row in $rows) {
        $rawDate = $row.Groups[1].Value.Trim()
        $time    = $row.Groups[2].Value.Trim()
        $state   = ($row.Groups[3].Value -replace '<[^>]+>','').Trim()
        $source  = ($row.Groups[4].Value -replace '<[^>]+>','').Trim()
        $cap     = ($row.Groups[5].Value -replace '<[^>]+>','').Trim()
        if ($rawDate -match '\d{4}-\d{2}-\d{2}') { $currentDate = $rawDate.Trim() }
        if ($currentDate -eq "" -or $time -eq "") { continue }
        try { $dt = [datetime]::ParseExact("$currentDate $time", "yyyy-MM-dd HH:mm:ss", $null) }
        catch { continue }
        $events.Add([PSCustomObject]@{ DateTime=$dt; Date=$currentDate; Time=$time; State=$state; Source=$source; Capacity=$cap })
    }
    return $events
}

$tlEvents = Get-TimelineEvents
$tlByDate = [System.Collections.Generic.Dictionary[string, System.Collections.Generic.List[PSObject]]]::new()
foreach ($ev in $tlEvents) {
    if (-not $tlByDate.ContainsKey($ev.Date)) { $tlByDate[$ev.Date] = [System.Collections.Generic.List[PSObject]]::new() }
    $tlByDate[$ev.Date].Add($ev)
}
$tlDates = ($tlByDate.Keys | Sort-Object | Select-Object -Last 3)

# ============================================================
# LAYOUT
# ============================================================
[int]$W = 580

[int]$Y_HEADER   = 0
[int]$Y_CARDS    = 58
[int]$Y_HEALTH   = 210
[int]$Y_CHARGE   = 324
[int]$Y_TL_TITLE = 432
[int]$Y_TL_PANEL = 454

[int]$ROW_H   = 82
[int]$BAR_H   = 34
[int]$LEGEND_H = 32
[int]$nbDays  = $tlDates.Count
[int]$panelH  = $nbDays * $ROW_H + $LEGEND_H

[int]$BAR_L   = 88
[int]$BAR_R   = 558
[int]$BAR_W   = $BAR_R - $BAR_L

[int]$Y_BTNS  = $Y_TL_PANEL + $panelH + 14
[int]$Y_SIG   = $Y_BTNS + 44
[int]$FORM_H  = $Y_SIG + 22

# ============================================================
# FORMULAIRE
# ============================================================
$form = New-Object System.Windows.Forms.Form
$form.Text            = "Battery Monitor  ·  $sysModel"
$form.ClientSize      = New-Object System.Drawing.Size(($W + 20), $FORM_H)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = $cBG
$form.FormBorderStyle = "FixedSingle"
$form.MaximizeBox     = $false

# Icône embarquée en base64
$iconB64 = @"
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
"@
try {
    $iconBytes  = [System.Convert]::FromBase64String($iconB64)
    $iconStream = New-Object System.IO.MemoryStream(,$iconBytes)
    $form.Icon  = New-Object System.Drawing.Icon($iconStream)
    $iconStream.Dispose()
} catch { }

# ============================================================
# HELPER : panneau GDI avec bord néon
# ============================================================
function Add-GlowPanel {
    param([int]$X, [int]$Y, [int]$W, [int]$H, [System.Drawing.Color]$BorderColor)
    $p = New-Object System.Windows.Forms.Panel
    $p.Location  = New-Object System.Drawing.Point($X, $Y)
    $p.Size      = New-Object System.Drawing.Size($W, $H)
    $p.BackColor = $cPanelB
    $p.Add_Paint({
        param($s, $e)
        $pen = New-Object System.Drawing.Pen($s.Tag, 1)
        $e.Graphics.DrawRectangle($pen, 0, 0, ($s.Width - 1), ($s.Height - 1))
    })
    $p.Tag = $BorderColor
    return $p
}

# ============================================================
# HEADER
# ============================================================
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Location  = New-Object System.Drawing.Point(0, 0)
$headerPanel.Size      = New-Object System.Drawing.Size(600, 56)
$headerPanel.BackColor = $cPanel
$headerPanel.Add_Paint({
    param($s, $e)
    $g = $e.Graphics
    $pen1 = New-Object System.Drawing.Pen($cAccent2, 1)
    $g.DrawLine($pen1, 0, 55, 600, 55)
    $brA = New-Object System.Drawing.SolidBrush($cAccent)
    $g.FillRectangle($brA, 20, 20, 3, 18)
})
$form.Controls.Add($headerPanel)

$lblDevice = New-Object System.Windows.Forms.Label
$lblDevice.Text      = $sysModel.ToUpper()
$lblDevice.Font      = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$lblDevice.ForeColor = $cAccent
$lblDevice.Location  = New-Object System.Drawing.Point(32, 10)
$lblDevice.Size      = New-Object System.Drawing.Size(500, 18)
$headerPanel.Controls.Add($lblDevice)

$lblSub = New-Object System.Windows.Forms.Label
$lblSub.Text      = "BATTERY MONITOR  ·  OFBRIDGE LAB  ·  v$ScriptVersion"
$lblSub.Font      = New-Object System.Drawing.Font("Consolas", 7, [System.Drawing.FontStyle]::Regular)
$lblSub.ForeColor = $cTextDim
$lblSub.Location  = New-Object System.Drawing.Point(32, 30)
$lblSub.Size      = New-Object System.Drawing.Size(400, 14)
$headerPanel.Controls.Add($lblSub)

# ============================================================
# CARTE FICHE TECHNIQUE
# ============================================================
$cardFiche = Add-GlowPanel 10 $Y_CARDS 278 140 $cAccent2
$form.Controls.Add($cardFiche)

$lblFicheTitle = New-Object System.Windows.Forms.Label
$lblFicheTitle.Text      = if ($nbBatt -le 1) { "Fiche Technique" } else { "Fiche Technique · $nbBatt batt." }
$lblFicheTitle.Font      = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$lblFicheTitle.ForeColor = $cAccent2
$lblFicheTitle.Location  = New-Object System.Drawing.Point(12, 10)
$lblFicheTitle.AutoSize  = $true
$cardFiche.Controls.Add($lblFicheTitle)

$lblFicheContent = New-Object System.Windows.Forms.Label
$lblFicheContent.Text      = $ficheText
$lblFicheContent.Font      = New-Object System.Drawing.Font("Consolas", 9)
$lblFicheContent.ForeColor = $cText
$lblFicheContent.Location  = New-Object System.Drawing.Point(12, 34)
$lblFicheContent.Size      = New-Object System.Drawing.Size(252, 126)
$cardFiche.Controls.Add($lblFicheContent)

# ============================================================
# CARTE CAPACITÉS
# ============================================================
$cardCap = Add-GlowPanel 296 $Y_CARDS 294 140 $cAccent
$form.Controls.Add($cardCap)

$lblCapTitle = New-Object System.Windows.Forms.Label
$lblCapTitle.Text      = "Capacités"
$lblCapTitle.Font      = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
$lblCapTitle.ForeColor = $cAccent
$lblCapTitle.Location  = New-Object System.Drawing.Point(12, 10)
$lblCapTitle.AutoSize  = $true
$cardCap.Controls.Add($lblCapTitle)

$lblCapContent = New-Object System.Windows.Forms.Label
$lblCapContent.Text      = $capText
$lblCapContent.Font      = New-Object System.Drawing.Font("Consolas", 9)
$lblCapContent.ForeColor = $cText
$lblCapContent.Location  = New-Object System.Drawing.Point(12, 34)
$lblCapContent.Size      = New-Object System.Drawing.Size(268, 90)
$cardCap.Controls.Add($lblCapContent)

# ============================================================
# BLOC SANTÉ
# ============================================================
$healthPanel = New-Object System.Windows.Forms.Panel
$healthPanel.Location  = New-Object System.Drawing.Point(10, $Y_HEALTH)
$healthPanel.Size      = New-Object System.Drawing.Size(580, 100)
$healthPanel.BackColor = $cPanelB
$healthPanel.Add_Paint({
    param($s, $e)
    $g = $e.Graphics
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias

    $pen = New-Object System.Drawing.Pen($cAccent2, 1)
    $g.DrawRectangle($pen, 0, 0, ($s.Width-1), ($s.Height-1))

    $fSmall = New-Object System.Drawing.Font("Consolas", 12, [System.Drawing.FontStyle]::Bold)
    $brDim  = New-Object System.Drawing.SolidBrush($cAccent2)
    $g.DrawString("Santé de la batterie", $fSmall, $brDim, [float]14, [float]10)

    $fBig  = New-Object System.Drawing.Font("Consolas", 28, [System.Drawing.FontStyle]::Bold)
    $brVal = New-Object System.Drawing.SolidBrush($cWhite)
    $g.DrawString("$health %", $fBig, $brVal, [float]14, [float]28)

    [int]$bx = 175; [int]$by = 42; [int]$bw = 380; [int]$bh = 18
    [int]$segments = 20
    [int]$filled   = [int]([math]::Round($health / 100 * $segments))
    [int]$segW     = ($bw - $segments + 1) / $segments

    for ([int]$seg = 0; $seg -lt $segments; $seg++) {
        [int]$sx = $bx + $seg * ($segW + 1)
        if ($seg -lt $filled) {
            # gradient rouge → violet sur les segments remplis
            [int]$r  = [int](255 + (100 - 255) * $seg / $segments)
            [int]$gv = [int](20  + (30  - 20)  * $seg / $segments)
            [int]$b  = [int](80  + (255 - 80)  * $seg / $segments)
            $clrSeg  = [System.Drawing.Color]::FromArgb($r, $gv, $b)
        } else {
            $clrSeg = $clrInact
        }
        $g.FillRectangle((New-Object System.Drawing.SolidBrush($clrSeg)), $sx, $by, $segW, $bh)
    }
})
$form.Controls.Add($healthPanel)

# ============================================================
# BLOC CHARGE DYNAMIQUE
# ============================================================
$chargePanel = New-Object System.Windows.Forms.Panel
$chargePanel.Location  = New-Object System.Drawing.Point(10, $Y_CHARGE)
$chargePanel.Size      = New-Object System.Drawing.Size(580, 92)
$chargePanel.BackColor = $cPanelB
$chargePanel.Add_Paint({
    param($s, $e)
    $g = $e.Graphics
    $pen = New-Object System.Drawing.Pen($cAccent, 1)
    $g.DrawRectangle($pen, 0, 0, ($s.Width-1), ($s.Height-1))
    $fSmall  = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Bold)
    $brTitle = New-Object System.Drawing.SolidBrush($cAccent)
    $g.DrawString("CHARGE LEVEL", $fSmall, $brTitle, [float]20, [float]10)
})
$form.Controls.Add($chargePanel)

$chargeLabel = New-Object System.Windows.Forms.Label
$chargeLabel.Text      = "···"
$chargeLabel.Font      = New-Object System.Drawing.Font("Consolas", 22, [System.Drawing.FontStyle]::Bold)
$chargeLabel.ForeColor = $cWhite
$chargeLabel.Location  = New-Object System.Drawing.Point(0, 30)
$chargeLabel.Size      = New-Object System.Drawing.Size(580, 52)
$chargeLabel.TextAlign = "MiddleCenter"
$chargePanel.Controls.Add($chargeLabel)

$stateBar = New-Object System.Windows.Forms.Panel
$stateBar.Location  = New-Object System.Drawing.Point(14, 28)
$stateBar.Size      = New-Object System.Drawing.Size(3, 52)
$stateBar.BackColor = $cTextDim
$chargePanel.Controls.Add($stateBar)

# ============================================================
# TIMER
# ============================================================
$hasBeeped = $false
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000
$timer.Add_Tick({
    $wmi = @(Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue)
    if ($wmi.Count -eq 0) { return }

    # Agrégation multi-batterie : charge moyenne, statut = charge si une seule charge
    $charges = @($wmi | ForEach-Object { [int]$_.EstimatedChargeRemaining })
    $charge  = [int][math]::Round(($charges | Measure-Object -Average).Average)
    $states  = @($wmi | ForEach-Object { [int]$_.BatteryStatus })
    $isChg   = ($states | Where-Object { $_ -eq 2 -or $_ -eq 6 }).Count -gt 0
    $isFull  = ($charge -ge 100)
    $suffix  = if ($wmi.Count -gt 1) { "  ·  $($wmi.Count) batt." } else { "" }

    if ($isFull) {
        $chargeLabel.Text      = "100 %   CHARGÉE$suffix"
        $chargeLabel.ForeColor = $cGreen
        $stateBar.BackColor    = $cGreen
        $chargePanel.Invalidate()
        if (-not $hasBeeped -and $isChg) {
            [System.Media.SystemSounds]::Exclamation.Play(); $hasBeeped = $true
        }
    } elseif ($isChg) {
        $chargeLabel.Text      = "$charge %   EN CHARGE$suffix"
        $chargeLabel.ForeColor = $cAccent
        $stateBar.BackColor    = $cAccent
        $chargePanel.Invalidate()
        $hasBeeped = $false
    } else {
        $chargeLabel.Text      = "$charge %   BATTERIE$suffix"
        $chargeLabel.ForeColor = $cAmber
        $stateBar.BackColor    = $cAmber
        $chargePanel.Invalidate()
        $hasBeeped = $false
    }
})
$timer.Start()

# ============================================================
# TIMELINE GDI+
# ============================================================
$tlTitle = New-Object System.Windows.Forms.Label
$tlTitle.Text      = "$([char]0x25BA) USAGE TIMELINE  ·  3 DERNIERS JOURS"
$tlTitle.Font      = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
$tlTitle.ForeColor = $cAccent2
$tlTitle.Location  = New-Object System.Drawing.Point(14, $Y_TL_TITLE)
$tlTitle.AutoSize  = $true
$tlTitle.Cursor    = [System.Windows.Forms.Cursors]::Hand
$tlTitle.Add_Click({ $script:tlExpanded = -not $script:tlExpanded; Update-Layout })
$tlTitle.Add_MouseEnter({ $this.ForeColor = $cAccent })
$tlTitle.Add_MouseLeave({ $this.ForeColor = $cAccent2 })
$form.Controls.Add($tlTitle)

$tlPanel = New-Object System.Windows.Forms.Panel
$tlPanel.Location  = New-Object System.Drawing.Point(10, $Y_TL_PANEL)
$tlPanel.Size      = New-Object System.Drawing.Size(580, $panelH)
$tlPanel.BackColor = $cBG

$script:tlHitZones = [System.Collections.Generic.List[PSObject]]::new()

$tlPanel.Add_Paint({
    param($sender, $e)
    $g = $e.Graphics
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

    $fDate   = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)
    $fSmall  = New-Object System.Drawing.Font("Consolas", 10, [System.Drawing.FontStyle]::Regular)
    $fLegend = New-Object System.Drawing.Font("Consolas", 11, [System.Drawing.FontStyle]::Bold)

    $brDate  = New-Object System.Drawing.SolidBrush($cAccent2)
    $brDim   = New-Object System.Drawing.SolidBrush($cTextDim)
    $brPanel = New-Object System.Drawing.SolidBrush($cPanelB)
    $brInact = New-Object System.Drawing.SolidBrush($clrInact)

    $penBorder = New-Object System.Drawing.Pen($cBorder, 1)
    $penMark   = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(35, 38, 65), 1)
    $penNoon   = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(55, 58, 95), 1)

    $script:tlHitZones.Clear()

    [int]$rowIdx = 0
    foreach ($date in $tlDates) {
        $evs = ($tlByDate[$date] | Sort-Object DateTime)
        [int]$y = $rowIdx * $ROW_H + 4

        $g.FillRectangle($brPanel, ($BAR_L - 6), ($y - 2), ($BAR_W + 12), ($ROW_H - 6))
        $g.DrawRectangle($penBorder, ($BAR_L - 6), ($y - 2), ($BAR_W + 11), ($ROW_H - 7))

        $parts = $date -split '-'
        $g.DrawString("$($parts[2])/$($parts[1])", $fDate,  $brDate, [float]4,  [float]($y + 4))
        $g.DrawString($parts[0],                   $fSmall, $brDim,  [float]6,  [float]($y + 22))

        $dateBase = [datetime]::ParseExact($date, "yyyy-MM-dd", $null)
        [double]$span = 86400.0

        $g.FillRectangle($brInact, $BAR_L, $y, $BAR_W, $BAR_H)

        foreach ($h in @(6, 12, 18)) {
            [int]$xM = $BAR_L + [int](($h * 3600.0 / $span) * $BAR_W)
            $pen = if ($h -eq 12) { $penNoon } else { $penMark }
            $g.DrawLine($pen, $xM, ($y - 1), $xM, ($y + $BAR_H))
        }

        for ([int]$i = 0; $i -lt $evs.Count; $i++) {
            $ev     = $evs[$i]
            $tStart = $ev.DateTime
            $tEnd   = if ($i + 1 -lt $evs.Count) { $evs[$i+1].DateTime } else { $tStart.AddMinutes(15) }
            if ($tEnd -gt $dateBase.AddDays(1)) { $tEnd = $dateBase.AddDays(1) }

            [double]$xFrac = ($tStart - $dateBase).TotalSeconds / $span
            [double]$wFrac = ($tEnd   - $tStart).TotalSeconds   / $span
            [int]$xPx = $BAR_L + [int]($xFrac * $BAR_W)
            [int]$wPx = [int]($wFrac * $BAR_W)
            if ($wPx -lt 3) { $wPx = 3 }

            $clr = [System.Drawing.ColorTranslator]::FromHtml("#333355")
            if     ($ev.State -eq "Suspended")  { $clr = $clrSuspend }
            elseif ($ev.Source -eq "Battery")   { $clr = $clrBatt }
            elseif ($ev.Source -eq "AC")        { $clr = $clrAC }

            $g.FillRectangle((New-Object System.Drawing.SolidBrush($clr)), $xPx, $y, $wPx, $BAR_H)

            [int]$durMin = [math]::Max(1, [int](($tEnd - $tStart).TotalMinutes))
            $durStr = if ($durMin -ge 60) { "$([int]($durMin/60))h $($durMin % 60)min" } else { "${durMin}min" }
            $script:tlHitZones.Add([PSCustomObject]@{
                X=$xPx; Y=$y; W=$wPx; H=$BAR_H
                Tip="$($ev.Time)  —  $($ev.State)`nSource : $($ev.Source)   Durée : $durStr`nCapacité : $($ev.Capacity)"
            })
        }

        [int]$lY = $y + $BAR_H + 4
        $g.DrawString("0h",  $fSmall, $brDim, [float]$BAR_L,                                    [float]$lY)
        $g.DrawString("6h",  $fSmall, $brDim, [float]($BAR_L + [int]($BAR_W * 0.25) - 5),      [float]$lY)
        $g.DrawString("12h", $fSmall, $brDim, [float]($BAR_L + [int]($BAR_W * 0.50) - 7),      [float]$lY)
        $g.DrawString("18h", $fSmall, $brDim, [float]($BAR_L + [int]($BAR_W * 0.75) - 7),      [float]$lY)
        $g.DrawString("24h", $fSmall, $brDim, [float]($BAR_R - 14),                             [float]$lY)

        $rowIdx++
    }

    [int]$legY = $rowIdx * $ROW_H + 8
    $items = @(
        [PSCustomObject]@{ C=$clrAC;      L="AC / Secteur" },
        [PSCustomObject]@{ C=$clrBatt;    L="Batterie" },
        [PSCustomObject]@{ C=$clrSuspend; L="Veille" }
    )
    [int]$lx = $BAR_L
    foreach ($it in $items) {
        $brL = New-Object System.Drawing.SolidBrush($it.C)
        $g.FillRectangle($brL, $lx, ($legY + 2), 13, 13)
        $g.DrawString($it.L, $fLegend, $brDim, [float]($lx + 18), [float]($legY - 1))
        $lx += 150
    }
})

$tlTooltip = New-Object System.Windows.Forms.ToolTip
$tlTooltip.InitialDelay = 60; $tlTooltip.ReshowDelay = 60; $tlTooltip.AutoPopDelay = 6000

$tlPanel.Add_MouseMove({
    param($s, $e)
    $found = $false
    foreach ($z in $script:tlHitZones) {
        if ($e.X -ge $z.X -and $e.X -le ($z.X + $z.W) -and $e.Y -ge $z.Y -and $e.Y -le ($z.Y + $z.H)) {
            $tlTooltip.SetToolTip($tlPanel, $z.Tip); $found = $true; break
        }
    }
    if (-not $found) { $tlTooltip.SetToolTip($tlPanel, "") }
})
$form.Controls.Add($tlPanel)

# ============================================================
# SÉPARATEUR
# ============================================================
$sepPanel = New-Object System.Windows.Forms.Panel
$sepPanel.Size      = New-Object System.Drawing.Size(580, 1)
$sepPanel.BackColor = $cBorder
$form.Controls.Add($sepPanel)

# ============================================================
# BOUTONS  (btn-hud : transparent, bordure colorée, hover = inversion)
# ============================================================
function New-HUDButton {
    param(
        [string]$text,
        [System.Drawing.Color]$border = $cAccent2,
        [System.Drawing.Color]$fore   = $cAccent
    )
    $b = New-Object System.Windows.Forms.Button
    $b.Text      = $text
    $b.Size      = New-Object System.Drawing.Size(285, 32)
    $b.BackColor = $cPanel
    $b.ForeColor = $fore
    $b.FlatStyle = "Flat"
    $b.FlatAppearance.BorderColor = $border
    $b.FlatAppearance.BorderSize  = 1
    $b.Font      = New-Object System.Drawing.Font("Consolas", 9, [System.Drawing.FontStyle]::Bold)
    $b.Cursor    = [System.Windows.Forms.Cursors]::Hand
    $b.Tag       = @{ Border = $border; Fore = $fore }
    # hover = inversion (fond plein couleur bordure, texte foncé)
    $b.Add_MouseEnter({ $this.BackColor = $this.Tag.Border; $this.ForeColor = $cBG })
    $b.Add_MouseLeave({ $this.BackColor = $cPanel;          $this.ForeColor = $this.Tag.Fore })
    return $b
}

$btn1 = New-HUDButton "RAPPORT DÉTAILLÉ"
$btn2 = New-HUDButton "PARAM. BATTERIE"
$btn3 = New-HUDButton "OPTION ALIM."
$btn4 = New-HUDButton "ACTIVER PERF. ÉLEVÉE" $cAmber $cAmber

$btn1.Add_Click({ Start-Process $reportPath })
$btn2.Add_Click({ Start-Process "ms-settings:batterysaver" })
$btn3.Add_Click({ Start-Process "powercfg.cpl" })
$btn4.Add_Click({
    $templGuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"   # modèle Windows « Performances élevées »
    $destGuid  = "11111111-2222-3333-4444-555555555555"   # copie visible dédiée (activation idempotente)
    $r = [System.Windows.Forms.MessageBox]::Show(
        "Activer le mode d'alimentation « Performances élevées » ?`n`nSi le schéma est masqué sur cet appareil, il sera d'abord créé depuis le modèle Windows, puis activé.`n`nContinuer ?",
        "Mode Performances élevées",
        [System.Windows.Forms.MessageBoxButtons]::OKCancel,
        [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($r -ne [System.Windows.Forms.DialogResult]::OK) { return }
    try {
        # 1) tenter d'activer notre copie (si déjà créée lors d'un précédent clic)
        $e = (& powercfg -setactive $destGuid 2>&1 | Out-String).Trim()
        if ($e) {
            # 2) copie absente → la créer depuis le modèle « Performances élevées », puis activer
            $dup = (& powercfg -duplicatescheme $templGuid $destGuid 2>&1 | Out-String).Trim()
            $e2  = (& powercfg -setactive $destGuid 2>&1 | Out-String).Trim()
            if ($e2) { throw "$dup`n$e2" }
        }
        $active = (& powercfg -getactivescheme 2>&1 | Out-String).Trim()
        [System.Windows.Forms.MessageBox]::Show("Mode « Performances élevées » activé.`n`n$active", "powercfg",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Échec de l'activation :`n$($_)", "Erreur powercfg",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

$form.Controls.Add($btn1)
$form.Controls.Add($btn2)
$form.Controls.Add($btn3)
$form.Controls.Add($btn4)

# ============================================================
# SIGNATURE
# ============================================================
$sig = New-Object System.Windows.Forms.Label
$sig.Text      = [char]0x00A9 + " ofbridge_lab"
$sig.Font      = New-Object System.Drawing.Font("Consolas", 7, [System.Drawing.FontStyle]::Italic)
$sig.ForeColor = $cTextMid
$sig.AutoSize  = $true
$form.Controls.Add($sig)

# ============================================================
# LAYOUT DYNAMIQUE  (timeline pliable + placement bas de fenêtre)
# ============================================================
$script:tlExpanded = $false   # repliée par défaut ; clic sur le titre pour déplier
function Update-Layout {
    $tlPanel.Visible = $script:tlExpanded
    $chev = if ($script:tlExpanded) { [char]0x25BC } else { [char]0x25BA }
    $tlTitle.Text = "$chev USAGE TIMELINE  ·  3 DERNIERS JOURS"

    [int]$below = if ($script:tlExpanded) { $Y_TL_PANEL + $panelH } else { $Y_TL_TITLE + 22 }
    [int]$sepY  = $below + 8
    [int]$r1    = $sepY + 10
    [int]$r2    = $r1 + 40
    [int]$sigY  = $r2 + 40

    $sepPanel.Location = New-Object System.Drawing.Point(10, $sepY)
    $btn1.Location = New-Object System.Drawing.Point(10,  $r1)
    $btn2.Location = New-Object System.Drawing.Point(305, $r1)
    $btn3.Location = New-Object System.Drawing.Point(10,  $r2)
    $btn4.Location = New-Object System.Drawing.Point(305, $r2)
    $sig.Location  = New-Object System.Drawing.Point(450, $sigY)
    $form.ClientSize = New-Object System.Drawing.Size(($W + 20), ($sigY + 22))
}
Update-Layout

# ============================================================
# CLOSE
# ============================================================
$form.Add_FormClosing({ $timer.Stop() })
$form.ShowDialog() | Out-Null
