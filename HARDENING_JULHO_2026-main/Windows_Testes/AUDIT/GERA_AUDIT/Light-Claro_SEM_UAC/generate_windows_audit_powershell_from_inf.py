#!/usr/bin/env python3
"""Converte uma baseline INF em verificacoes PowerShell para Tenable/Nessus.

O INF e a unica fonte de entrada. As descricoes geradas sao tecnicas; titulos,
criticidades e demais metadados documentais devem ser adicionados separadamente.
"""

from __future__ import annotations

import argparse
import base64
import csv
import re
from pathlib import Path


IGNORED_SECTIONS = {"unicode", "version"}
SCALAR_POLICY_SECTIONS = {"system access", "event audit", "kerberos policy"}
LOG_SECTIONS = {"application log", "system log", "security log"}
SUPPORTED_SECTIONS = IGNORED_SECTIONS | SCALAR_POLICY_SECTIONS | LOG_SECTIONS | {
    "serviceinstall",
    "privilege rights",
    "registry values",
    "registry keys",
    "service general setting",
}


def decode_inf(raw: bytes, path: Path) -> str:
    """Decodifica os formatos normalmente produzidos pelo Security Templates."""
    if raw.startswith((b"\xff\xfe", b"\xfe\xff")):
        return raw.decode("utf-16")
    if raw.startswith(b"\xef\xbb\xbf"):
        return raw.decode("utf-8-sig")

    for encoding in ("utf-8", "cp1252"):
        try:
            text = raw.decode(encoding)
            if "\x00" in text:
                continue
            return text
        except UnicodeDecodeError:
            pass
    raise ValueError(f"Nao foi possivel decodificar {path}")


def strip_inf_comment(source_line: str) -> str:
    """Remove comentarios iniciados por ; fora de campos entre aspas."""
    quoted = False
    index = 0
    while index < len(source_line):
        char = source_line[index]
        if char == '"':
            # Aspas duplicadas dentro de um campo CSV representam uma aspa literal.
            if quoted and index + 1 < len(source_line) and source_line[index + 1] == '"':
                index += 2
                continue
            quoted = not quoted
        elif char == ";" and not quoted:
            return source_line[:index]
        index += 1
    return source_line


def read_inf(path: Path) -> dict[str, list[tuple[str, str]]]:
    raw = path.read_bytes()
    text = decode_inf(raw, path)

    sections: dict[str, list[tuple[str, str]]] = {}
    current = ""
    for number, source_line in enumerate(text.splitlines(), 1):
        line = strip_inf_comment(source_line).strip()
        if not line or line.startswith("#"):
            continue
        match = re.fullmatch(r"\[(.+)]", line)
        if match:
            current = match.group(1).strip()
            sections.setdefault(current, [])
            continue
        if not current:
            continue  # Cabecalho humano anterior a [Unicode].
        if current.casefold() in {"registry keys", "service general setting"}:
            sections[current].append((line, ""))
        elif "=" in line:
            key, value = line.split("=", 1)
            sections[current].append((key.strip(), value.strip()))
        else:
            raise ValueError(f"Linha {number} invalida em [{current}]: {source_line}")
    return sections


def validate_sections(sections: dict[str, list[tuple[str, str]]]) -> None:
    unsupported = [name for name, items in sections.items() if items and name.casefold() not in SUPPORTED_SECTIONS]
    if unsupported:
        names = ", ".join(f"[{name}]" for name in unsupported)
        raise ValueError(f"Secoes INF ainda nao suportadas: {names}")


def ps_quote(value: str) -> str:
    return "'" + value.replace("'", "''") + "'"


def ps_array(values: list[str]) -> str:
    return "@(" + ", ".join(ps_quote(value) for value in values) + ")"


def encode_script(script: str) -> str:
    return base64.b64encode(script.encode("utf-16le")).decode("ascii")


def wrap(body: str, finally_body: str = "") -> str:
    result = "$ErrorActionPreference = 'Stop'\ntry {\n"
    result += "\n".join("  " + line if line else "" for line in body.splitlines())
    result += "\n} catch {\n  'FAIL'\n}"
    if finally_body:
        result += " finally {\n"
        result += "\n".join("  " + line if line else "" for line in finally_body.splitlines())
        result += "\n}"
    return result


def scalar_policy_script(key: str, expected: str) -> str:
    body = f"""$path = Join-Path $env:TEMP ('nessus-secpol-' + [guid]::NewGuid().ToString('N') + '.inf')
$null = & secedit.exe /export /cfg $path /areas SECURITYPOLICY /quiet
if ($LASTEXITCODE -ne 0) {{ throw 'secedit export failed' }}
$match = Select-String -LiteralPath $path -Pattern '^{re.escape(key)}\\s*='
$actual = if ($match) {{ (($match.Line -split '=', 2)[1]).Trim().Trim('"') }} else {{ $null }}
if ($null -ne $actual -and $actual -ceq {ps_quote(expected.strip().strip('"'))}) {{ 'PASS' }} else {{ 'FAIL' }}"""
    return wrap(body, "Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue")


def log_script(section: str, key: str, value: str) -> str:
    names = {
        "MaximumLogSize": ("MaxSize", str(int(value) * 1024)),
        "AuditLogRetentionPeriod": ("Retention", value),
        "RestrictGuestAccess": ("RestrictGuestAccess", value),
    }
    registry_name, expected = names[key]
    path = rf"Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\EventLog\{section.removesuffix(' Log')}"
    return wrap(
        f"$actual = Get-ItemPropertyValue -LiteralPath {ps_quote(path)} -Name {ps_quote(registry_name)}\n"
        f"if ([int64]$actual -eq {int(expected)}) {{ 'PASS' }} else {{ 'FAIL' }}"
    )


def service_install_script(items: list[tuple[str, str]]) -> str:
    values = dict(items)
    name = values["ServiceName"]
    display = values["DisplayName"].strip().strip('"')
    start = int(values["StartType"], 0)
    error = int(values["ErrorControl"], 0)
    service_type = int(values["ServiceType"], 0)
    service_path = "Registry::HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Services\\" + name
    body = f"""$cfg = Get-ItemProperty -LiteralPath {ps_quote(service_path)}
$svc = Get-Service -Name {ps_quote(name)}
$ok = ([int64]$cfg.Start -eq {start}) -and ([int64]$cfg.ErrorControl -eq {error}) -and ([int64]$cfg.Type -eq {service_type})
$ok = $ok -and ($svc.DisplayName -ceq {ps_quote(display)})
if ($ok) {{ 'PASS' }} else {{ 'FAIL' }}"""
    return wrap(body)


def privilege_script(key: str, value: str) -> str:
    expected = [part.strip().lstrip("*") for part in value.split(",") if part.strip()]
    expected = ["__BUILTIN_ADMIN__" if item.casefold() == "administrator" else item for item in expected]
    body = f"""$path = Join-Path $env:TEMP ('nessus-secpol-' + [guid]::NewGuid().ToString('N') + '.inf')
$null = & secedit.exe /export /cfg $path /areas USER_RIGHTS /quiet
if ($LASTEXITCODE -ne 0) {{ throw 'secedit export failed' }}
function Convert-ToPolicyIdentity([string]$Name) {{
  $value = $Name.Trim().TrimStart('*')
  if ($value -eq '__BUILTIN_ADMIN__') {{
    $admin = Get-CimInstance Win32_UserAccount -Filter 'LocalAccount=True' |
      Where-Object {{ $_.SID -match '-500$' }} | Select-Object -First 1
    if (-not $admin) {{ throw 'built-in administrator not found' }}
    return $admin.SID.ToUpperInvariant()
  }}
  if ($value -match '^S-\\d-') {{ return $value.ToUpperInvariant() }}
  try {{
    $account = [System.Security.Principal.NTAccount]::new($value)
    return $account.Translate([System.Security.Principal.SecurityIdentifier]).Value.ToUpperInvariant()
  }} catch {{
    return $value.ToUpperInvariant()
  }}
}}
$match = Select-String -LiteralPath $path -Pattern '^{re.escape(key)}\\s*='
if (-not $match) {{ throw 'user right not found' }}
$rawActual = (($match.Line -split '=', 2)[1]).Trim()
$actualTokens = if ($rawActual) {{ @($rawActual -split ',' | ForEach-Object {{ $_.Trim() }} | Where-Object {{ $_ }}) }} else {{ @() }}
$expectedTokens = {ps_array(expected)}
$actual = @($actualTokens | ForEach-Object {{ Convert-ToPolicyIdentity $_ }} | Sort-Object -Unique)
$expected = @($expectedTokens | ForEach-Object {{ Convert-ToPolicyIdentity $_ }} | Sort-Object -Unique)
$actualJoined = [string]::Join([char]0, $actual)
$expectedJoined = [string]::Join([char]0, $expected)
if ($actual.Count -eq $expected.Count -and $actualJoined -ceq $expectedJoined) {{ 'PASS' }} else {{ 'FAIL' }}"""
    return wrap(body, "Remove-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue")


def csv_fields(value: str) -> list[str]:
    return next(csv.reader([value], skipinitialspace=True))


def registry_script(source: str) -> str:
    path_and_name, encoded_value = source.split("=", 1)
    path_and_name = re.sub(r"^MACHINE\\", "", path_and_name, flags=re.IGNORECASE)
    path, name = path_and_name.rsplit("\\", 1)
    fields = csv_fields(encoded_value)
    value_type = int(fields[0])
    values = fields[1:]
    registry_path = "Registry::HKEY_LOCAL_MACHINE\\" + path
    get_value = f"$actual = Get-ItemPropertyValue -LiteralPath {ps_quote(registry_path)} -Name {ps_quote(name)}"
    if value_type == 1:  # REG_SZ
        expected = values[0] if values else ""
        test = f"if ([string]$actual -ceq {ps_quote(expected)}) {{ 'PASS' }} else {{ 'FAIL' }}"
    elif value_type == 3:  # REG_BINARY
        expected = "".join(values).replace(" ", "").lower()
        test = (
            "$hex = -join @($actual | ForEach-Object { $_.ToString('x2') })\n"
            f"if ($hex -ceq {ps_quote(expected)}) {{ 'PASS' }} else {{ 'FAIL' }}"
        )
    elif value_type == 4:  # REG_DWORD
        expected = int(values[0], 0)
        test = f"if ([int64]$actual -eq {expected}) {{ 'PASS' }} else {{ 'FAIL' }}"
    elif value_type == 7:  # REG_MULTI_SZ; o INF guarda a lista em um campo CSV.
        values = [part.strip() for field in values for part in field.split(",") if part.strip()]
        test = f"""$actualValues = @($actual)
if ($actualValues.Count -eq 1 -and [string]::IsNullOrEmpty([string]$actualValues[0])) {{ $actualValues = @() }}
$expectedValues = {ps_array(values)}
$actualJoined = [string]::Join([char]0, $actualValues)
$expectedJoined = [string]::Join([char]0, $expectedValues)
if ($actualValues.Count -eq $expectedValues.Count -and $actualJoined -ceq $expectedJoined) {{ 'PASS' }} else {{ 'FAIL' }}"""
    else:
        raise ValueError(f"Tipo de registro nao suportado ({value_type}): {source}")
    return wrap(get_value + "\n" + test)


def registry_acl_script(source: str) -> str:
    fields = csv_fields(source)
    if len(fields) != 3:
        raise ValueError(f"ACL de registro invalida: {source}")
    path, _flags, sddl = fields
    path = re.sub(r"^machine\\", "", path, flags=re.IGNORECASE)
    registry_path = "Registry::HKEY_LOCAL_MACHINE\\" + path
    body = f"""$actualAcl = Get-Acl -LiteralPath {ps_quote(registry_path)}
$expectedAcl = New-Object System.Security.AccessControl.RegistrySecurity
$expectedAcl.SetSecurityDescriptorSddlForm({ps_quote(sddl)}, [System.Security.AccessControl.AccessControlSections]::Access)
$actualSddl = $actualAcl.GetSecurityDescriptorSddlForm([System.Security.AccessControl.AccessControlSections]::Access)
$expectedSddl = $expectedAcl.GetSecurityDescriptorSddlForm([System.Security.AccessControl.AccessControlSections]::Access)
if ($actualSddl -ceq $expectedSddl) {{ 'PASS' }} else {{ 'FAIL' }}"""
    return wrap(body)


def service_setting_script(source: str) -> str:
    fields = csv_fields(source)
    if len(fields) != 3:
        raise ValueError(f"Configuracao de servico invalida: {source}")
    name, start, sddl = fields
    service_path = rf"Registry::HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\{name}"
    lines = [
        f"$servicePath = {ps_quote(service_path)}",
        "if (-not (Test-Path -LiteralPath $servicePath)) { 'PASS'; return }",
        "$cfg = Get-ItemProperty -LiteralPath $servicePath",
        f"$ok = ([int64]$cfg.Start -eq {int(start, 0)})",
    ]
    if sddl:
        lines.extend([
            f"$sddlOutput = @(& sc.exe sdshow {ps_quote(name)} 2>$null)",
            "$actualSddl = ([string]($sddlOutput | Where-Object { $_ -match '^[OGDS]:' } | Select-Object -Last 1)).Trim()",
            "if (-not $actualSddl) { throw 'service SDDL not returned' }",
            "$actualDescriptor = [System.Security.AccessControl.RawSecurityDescriptor]::new($actualSddl)",
            f"$expectedDescriptor = [System.Security.AccessControl.RawSecurityDescriptor]::new({ps_quote(sddl)})",
            "$actualNormalized = $actualDescriptor.GetSddlForm([System.Security.AccessControl.AccessControlSections]::All)",
            "$expectedNormalized = $expectedDescriptor.GetSddlForm([System.Security.AccessControl.AccessControlSections]::All)",
            "$ok = $ok -and ($actualNormalized -ceq $expectedNormalized)",
        ])
    lines.append("if ($ok) { 'PASS' } else { 'FAIL' }")
    return wrap("\n".join(lines))


def build_controls(sections: dict[str, list[tuple[str, str]]]) -> list[tuple[str, str]]:
    controls: list[tuple[str, str]] = []
    for section, items in sections.items():
        normalized = section.casefold()
        if normalized in IGNORED_SECTIONS or not items:
            continue
        if normalized in SCALAR_POLICY_SECTIONS:
            controls.extend((f"[{section}] {key}", scalar_policy_script(key, value)) for key, value in items)
        elif normalized in LOG_SECTIONS:
            controls.extend((f"[{section}] {key}", log_script(section, key, value)) for key, value in items)
        elif normalized == "serviceinstall":
            name = dict(items).get("ServiceName", "servico")
            controls.append((f"[{section}] {name}", service_install_script(items)))
        elif normalized == "privilege rights":
            controls.extend((f"[{section}] {key}", privilege_script(key, value)) for key, value in items)
        elif normalized == "registry values":
            controls.extend(
                (f"[{section}] {key}", registry_script(f"{key}={value}")) for key, value in items
            )
        elif normalized == "registry keys":
            for source, _ in items:
                path = csv_fields(source)[0]
                controls.append((f"[{section}] {path}", registry_acl_script(source)))
        elif normalized == "service general setting":
            for source, _ in items:
                name = csv_fields(source)[0]
                controls.append((f"[{section}] {name}", service_setting_script(source)))
    if not controls:
        raise ValueError("O INF nao contem nenhum controle tecnico suportado")
    return controls


def render(inf: Path) -> str:
    sections = read_inf(inf)
    validate_sections(sections)
    controls = build_controls(sections)
    lines = [
        f"# Fonte tecnica unica: {inf.name}",
        "# Descricoes tecnicas geradas do INF; metadados documentais devem ser complementados separadamente.",
        "",
        '<check_type:"Windows" version:"2">',
        "",
    ]
    width = max(3, len(str(len(controls))))
    for index, (technical_description, script) in enumerate(controls, 1):
        description = f"{index:0{width}d} {technical_description}".replace('"', "'")
        lines.extend([
            "<custom_item>",
            "  type            : AUDIT_POWERSHELL",
            f'  description     : "{description}"',
            "  value_type      : POLICY_TEXT",
            '  value_data      : "PASS"',
            "  check_type      : CHECK_EQUAL",
            f'  powershell_args : "{encode_script(script)}"',
            "  ps_encoded_args : YES",
            "</custom_item>",
            "",
        ])
    lines.append("</check_type>")
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("inf", type=Path, help="Baseline INF de entrada")
    parser.add_argument("output", type=Path, help="Arquivo .audit de saida")
    args = parser.parse_args()
    content = render(args.inf)
    args.output.write_text(content, encoding="utf-8", newline="\n")
    count = content.count("<custom_item>")
    print(f"Gerado: {args.output} ({count} controles)")


if __name__ == "__main__":
    main()
