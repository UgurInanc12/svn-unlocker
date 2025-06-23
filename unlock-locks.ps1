<#
  unlock-locks.ps1        –  sweep SVN locks that belong to a user

  Modes
    1) Full : scan every version-controlled file        (slower)
    2) UE   : scan only Unreal Engine assets            (faster)

  Usage
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
    .\unlock-locks.ps1
#>

function Ask-Choice($title, $opts) {
    Write-Host $title
    for ($i = 0; $i -lt $opts.Count; $i++) {
        Write-Host " [$($i+1)] $($opts[$i])"
    }
    do {
        $sel = Read-Host "Select 1..$($opts.Count)"
    } until ([int]::TryParse($sel, [ref]$null) -and
             $sel -ge 1 -and $sel -le $opts.Count)
    return [int]$sel - 1          # zero-based
}

Write-Host "`n=== SVN LOCK SWEEPER ===`n"

# ---------- INPUTS --------------------------------------------------------
$wc = Read-Host "Working-copy path (blank = current dir)"
if ([string]::IsNullOrWhiteSpace($wc)) { $wc = Get-Location }
$wc = (Resolve-Path $wc).Path

$user = Read-Host "SVN username whose locks will be removed"

$m = Ask-Choice "Scan mode" @(
        "Full  - check every version-controlled file",
        "UE    - Unreal Engine assets only"
     )
$ueOnly = ($m -eq 1)   # index 1 = UE line

Write-Host ""

# ---------- BUILD FILE LIST ----------------------------------------------
if ($ueOnly) {
    $pat = '*.uasset','*.umap','*.utexture','*.uplugin'
    $files = Get-ChildItem $wc -Recurse -Include $pat -File
} else {
    $files = Get-ChildItem $wc -Recurse -File
}

# ---------- FIND LOCKS ----------------------------------------------------
$hits = @()
$total = $files.Count
$i = 0

foreach ($f in $files) {
    $i++
    Write-Progress -Activity "svn info" -Status "$i / $total" `
                   -PercentComplete (($i/$total)*100)

    $info = & svn info --non-interactive -- "$($f.FullName)" 2>$null
    if ($LASTEXITCODE -ne 0) { continue }   # unversioned

    if ($info -match 'Lock Owner:\s*(.+)') {
        if ($Matches[1].Trim() -eq $user) {
            $hits += $f
            Write-Host "[locked] $($f.FullName)"
        }
    }
}

Write-Host "`nFound $($hits.Count) file(s) locked by '$user'."
if ($hits.Count -eq 0) { exit }

$go = Read-Host "Break these locks on the repository? (y/N)"
if ($go -notmatch '^(y|yes)$') { Write-Host "Cancelled."; exit }

# ---------- UNLOCK --------------------------------------------------------
foreach ($f in $hits) {
    $url = (& svn info --show-item url --non-interactive -- "$($f.FullName)").Trim()
    if ($url) {
        Write-Host "unlock  $url"
        & svn unlock --force "$url"
    }
}

Write-Host "Done.  All matching locks have been removed."
