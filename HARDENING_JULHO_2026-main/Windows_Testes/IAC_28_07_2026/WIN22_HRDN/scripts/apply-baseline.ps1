param(
    [Parameter(Mandatory)]
    [string]$InfPath
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $InfPath)) {
    throw "INF nao encontrado: $InfPath"
}

$workDir = Join-Path $env:ProgramData 'ClaroBaseline'
$cfgPath = Join-Path $workDir 'baseline.inf'
$dbPath = Join-Path $workDir 'baseline.sdb'
$logPath = Join-Path $workDir 'secedit.log'
$backupPath = Join-Path $workDir 'before.inf'
$hashPath = Join-Path $workDir 'applied.sha256'
$warningPath = Join-Path $workDir 'warnings.log'
$warnings = @()

New-Item -ItemType Directory -Path $workDir -Force | Out-Null

$encoding = [Text.Encoding]::GetEncoding(1252)
$content = [IO.File]::ReadAllText($InfPath, $encoding)
$start = $content.IndexOf('[Unicode]', [StringComparison]::OrdinalIgnoreCase)

if ($start -lt 0) {
    throw 'Secao [Unicode] nao encontrada no INF.'
}

$content = $content.Substring($start)
$content = $content.Replace(
    'D:PAR(ACIKA;;;SY)(ACIKA;;;BA)',
    'D:PAR(A;CI;KA;;;SY)(A;CI;KA;;;BA)'
)

$admin = Get-CimInstance Win32_UserAccount -Filter 'LocalAccount=True' |
    Where-Object { $_.SID -match '-500$' } |
    Select-Object -First 1
if (-not $admin) {
    throw 'Conta administrativa interna (SID -500) nao encontrada.'
}

$content = $content.Replace(',Administrator', ",*$($admin.SID)")

$serviceBlock = [regex]::Match(
    $content,
    '(?ms)^\[Service General Setting\]\s*(?<body>.*?)(?=^\[|\z)'
)
$services = $serviceBlock.Groups['body'].Value |
    ConvertFrom-Csv -Header Name, Start, Sddl

$content = [regex]::Replace(
    $content,
    '(?ms)^\[Service General Setting\]\s*.*?(?=^\[|\z)',
    ''
)

[IO.File]::WriteAllText($cfgPath, $content, [Text.Encoding]::Unicode)

$hash = (Get-FileHash -LiteralPath $InfPath -Algorithm SHA256).Hash + '-v7'
if ((Test-Path -LiteralPath $hashPath) -and
    ((Get-Content -LiteralPath $hashPath -Raw).Trim() -eq $hash)) {
    Write-Host 'Baseline ja aplicado; nenhuma alteracao necessaria.'
    exit 0
}

& secedit.exe /export /cfg $backupPath /quiet
if ($LASTEXITCODE -ne 0) {
    throw "Falha ao exportar a politica atual: codigo $LASTEXITCODE."
}

& secedit.exe /configure /db $dbPath /cfg $cfgPath /overwrite `
    /areas SECURITYPOLICY USER_RIGHTS REGKEYS /log $logPath /quiet
if ($LASTEXITCODE -ne 0) {
    throw "Falha ao aplicar o baseline: codigo $LASTEXITCODE. Log: $logPath"
}

foreach ($service in $services) {
    $name = $service.Name.Trim()
    $path = "Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\$name"
    if (-not (Test-Path -LiteralPath $path) -or
        -not (Get-Service -Name $name -ErrorAction SilentlyContinue)) {
        Write-Host "Servico ausente, ignorado: $name"
        continue
    }

    $startMode = switch ([int]$service.Start) {
        2 { 'auto' }
        3 { 'demand' }
        4 { 'disabled' }
        default { throw "StartType invalido para $name." }
    }

    $currentStart = [int](Get-ItemProperty -LiteralPath $path -Name Start).Start
    if ($currentStart -ne [int]$service.Start) {
        & sc.exe config $name start= $startMode | Out-Host
        if ($LASTEXITCODE -ne 0) {
            $warnings += "Nao foi possivel configurar Start de $name."
        }
    }

    $sddl = $service.Sddl.Trim().Replace(
        'S:(AUFACCDCLCSWRPWPDTLOCRSDRCWDWO;;;WD)',
        'S:(AU;FA;CCDCLCSWRPWPDTLOCRSDRCWDWO;;;WD)'
    )
    if ($sddl) {
        $current = & sc.exe sdshow $name 2>$null | Select-Object -Last 1
        if (-not $current) {
            $warnings += "Nao foi possivel consultar ACL de $name."
            continue
        }
        $current = $current.Trim()
        $currentAcl = [Security.AccessControl.RawSecurityDescriptor]::new($current)
        $expectedAcl = [Security.AccessControl.RawSecurityDescriptor]::new($sddl)
        $current = $currentAcl.GetSddlForm(
            [Security.AccessControl.AccessControlSections]::All
        )
        $sddl = $expectedAcl.GetSddlForm(
            [Security.AccessControl.AccessControlSections]::All
        )

        if ($current -cne $sddl) {
            & sc.exe sdset $name $sddl | Out-Host
            if ($LASTEXITCODE -ne 0) {
                $warnings += "Nao foi possivel aplicar ACL de $name."
            }
        }
    }
}

Set-Content -LiteralPath $warningPath -Value $warnings -Encoding ASCII
foreach ($warning in $warnings) {
    Write-Warning $warning
}

Set-Content -LiteralPath $hashPath -Value $hash -Encoding ASCII
gpupdate.exe /force | Out-Host
Write-Host "Baseline aplicado. Backup: $backupPath"
