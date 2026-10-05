#!/usr/bin/env python3
# audit_syntax_validator.py (v2)
# Autor: M365 Copilot para Renato
# Objetivo: Validar SINTAXE de arquivos .audit (Unix + CMD_EXEC).
# Novidades v2: normalização Unicode/espacos, tolerância ao ":" e modo --debug.

import re
import sys
import csv
from pathlib import Path
from typing import Dict, List, Optional

# ------------------------- Flags/CLI -------------------------
DEBUG = False

def parse_args():
    global DEBUG
    if len(sys.argv) < 2:
        print("Uso: python audit_syntax_validator.py <pasta_ou_arquivo.audit> [saida_findings.csv] [--debug]")
        sys.exit(1)
    input_path = Path(sys.argv[1])
    csv_out = None
    if len(sys.argv) >= 3 and not sys.argv[2].startswith('-'):
        csv_out = Path(sys.argv[2])
    if '--debug' in sys.argv:
        DEBUG = True
    return input_path, csv_out

# ------------------------- Regras baseadas em documentação -------------------------
GENERIC_KEYS = {
    'description', 'info', 'solution', 'see_also', 'reference'
}
CMD_EXEC_REQUIRED = {'type', 'cmd', 'expect'}
CMD_EXEC_ALLOWED_EXTRA = {
    'dont_echo_cmd', 'nosudo', 'timeout', 'quiet'
}
TOLERATED_EXTRA = {'compliance_check_id'}

# ------------------------- Regex utilitárias -------------------------
CUSTOM_ITEM_OPEN = re.compile(r"<\s*(custom_item|item)\s*>", re.IGNORECASE)
CUSTOM_ITEM_CLOSE = re.compile(r"</\s*(custom_item|item)\s*>", re.IGNORECASE)
CHECK_TYPE_OPEN = re.compile(r"<\s*check_type\s*:\s*\"?\s*Unix\s*\"?\s*>", re.IGNORECASE)
CHECK_TYPE_CLOSE = re.compile(r"</\s*check_type\s*>", re.IGNORECASE)

# Chaves: letras, números, underscore, hífen (permitir espaços esparsos)
# Valor: resto da linha
KV_RE = re.compile(r"^\s*([A-Za-z0-9_\-]+)\s*:\s*(.*?)\s*$")

# ------------------------- Normalização -------------------------
def normalize_line(s: str) -> str:
    """Remove caracteres invisíveis e normaliza espaço ao redor de ':'."""
    if not s:
        return s
    # Remove BOM e invisíveis comuns
    s = s.replace('\ufeff', '')   # BOM
    s = s.replace('\u200b', '')   # ZWSP
    # Normaliza NBSP para espaço
    s = s.replace('\xa0', ' ').replace('\u202f', ' ')
    # Reduz mistura estranha antes/depois de ':'
    # (ex.: 'type    :    CMD_EXEC' -> 'type : CMD_EXEC')
    s = re.sub(r"^\s*([A-Za-z0-9_\-]+)\s*:\s*", r"\1 : ", s)
    return s

def strip_outer_quotes(val: str) -> str:
    """Remove aspas externas mesmo se houver espaços finais."""
    v = val.rstrip()
    if len(v) >= 2:
        if (v[0] == '"' and v[-1] == '"') or (v[0] == "'" and v[-1] == "'"):
            return v[1:-1]
    return val

# ------------------------- Parser -------------------------
def split_scopes(text: str) -> List[str]:
    scopes: List[str] = []
    pos = 0
    found = False
    while True:
        m_open = CHECK_TYPE_OPEN.search(text, pos)
        if not m_open:
            break
        found = True
        m_close = CHECK_TYPE_CLOSE.search(text, m_open.end())
        if not m_close:
            scopes.append(text[m_open.end():])
            pos = len(text)
        else:
            scopes.append(text[m_open.end():m_close.start()])
            pos = m_close.end()
    if not found:
        scopes = [text]
    return scopes

def iter_custom_blocks(scope: str) -> List[str]:
    blocks = []
    pos = 0
    while True:
        m_open = CUSTOM_ITEM_OPEN.search(scope, pos)
        if not m_open:
            break
        m_close = CUSTOM_ITEM_CLOSE.search(scope, m_open.end())
        if not m_close:
            blocks.append(scope[m_open.end():])
            pos = len(scope)
        else:
            blocks.append(scope[m_open.end():m_close.start()])
            pos = m_close.end()
    return blocks

def parse_block(block: str) -> Dict[str, List[str]]:
    d: Dict[str, List[str]] = {}
    unmatched_lines: List[str] = []
    for raw in block.splitlines():
        # Normaliza linha para evitar NBSP/ZWSP/BOM
        line = normalize_line(raw)
        m = KV_RE.match(line)
        if not m:
            # Se for linha em branco, ignore; senão, guarde para debug
            if line.strip():
                unmatched_lines.append(raw)
            continue
        key = m.group(1).strip()
        val = m.group(2).strip()
        # remove aspas externas e converte entidades HTML
        val = strip_outer_quotes(val)
        val = val.replace('&gt;', '>').replace('&lt;', '<').replace('&amp;', '&')
        d.setdefault(key, []).append(val)
    if DEBUG and unmatched_lines:
        print("    [debug] Linhas não casadas dentro do custom_item:")
        for l in unmatched_lines:
            # Mostra caracteres não imprimíveis escapados
            print("           ·", repr(l))
    return d

# ------------------------- Validação -------------------------
def validate_cmd_exec(item: Dict[str, List[str]]) -> List[str]:
    issues: List[str] = []
    keys_lower = {k.lower(): k for k in item.keys()}  # map lower->orig

    # 1) Obrigatórios
    missing = [k for k in CMD_EXEC_REQUIRED if k not in keys_lower]
    if missing:
        issues.append(f"Faltando campos obrigatórios em CMD_EXEC: {', '.join(missing)}")

    # 2) Tipo correto
    t = item.get(keys_lower.get('type',''), [''])[0].strip().upper() if 'type' in keys_lower else ''
    if t != 'CMD_EXEC':
        issues.append(f"type esperado CMD_EXEC, encontrado: '{t or 'vazio'}'")

    # 3) Campos desconhecidos
    allowed = set(k.lower() for k in GENERIC_KEYS) | set(k.lower() for k in CMD_EXEC_ALLOWED_EXTRA) | CMD_EXEC_REQUIRED | set(k.lower() for k in TOLERATED_EXTRA)
    unknown = [orig for lower, orig in keys_lower.items() if lower not in allowed]
    if unknown:
        issues.append(f"Chaves não reconhecidas para CMD_EXEC: {', '.join(sorted(unknown))}")

    # 4) Tipagem/valores esperados
    if 'expect' in keys_lower:
        for val in item[keys_lower['expect']]:
            try:
                re.compile(val)
            except re.error as e:
                issues.append(f"expect regex inválido: {val!r} -> {e}")

    if 'timeout' in keys_lower:
        for val in item[keys_lower['timeout']]:
            if not val.isdigit():
                issues.append(f"timeout deve ser numérico (segundos), recebido: {val!r}")

    for flag in ('dont_echo_cmd', 'nosudo', 'quiet'):
        if flag in keys_lower:
            for v in item[keys_lower[flag]]:
                if v.upper() not in ('YES', 'NO'):
                    issues.append(f"{flag} deve ser YES ou NO, recebido: {v!r}")

    if 'cmd' in keys_lower:
        if not any(item[keys_lower['cmd']]):
            issues.append("cmd está vazio")

    return issues

def validate_custom_item(item: Dict[str, List[str]]) -> List[str]:
    t = item.get('type', [''])[-1].strip().upper() if 'type' in item else ''
    if t == 'CMD_EXEC' or not t:
        return validate_cmd_exec(item)
    else:
        issues: List[str] = [f"Tipo não suportado pelo validador: {t}"]
        keys_lower = {k.lower(): k for k in item.keys()}
        allowed = set(k.lower() for k in GENERIC_KEYS) | {'type'} | set(k.lower() for k in TOLERATED_EXTRA)
        unknown = [orig for lower, orig in keys_lower.items() if lower not in allowed]
        if unknown:
            issues.append(f"Chaves potencialmente desconhecidas para tipo {t}: {', '.join(sorted(unknown))}")
        return issues

# ------------------------- Execução -------------------------
def main():
    input_path, csv_out = parse_args()

    if input_path.is_dir():
        files = sorted(input_path.rglob('*.audit'))
    elif input_path.is_file():
        files = [input_path]
    else:
        print(f"Caminho inválido: {input_path}")
        sys.exit(2)

    findings_rows = []
    total_items = 0
    total_issues = 0

    for f in files:
        text = f.read_text(encoding='utf-8', errors='ignore')
        scopes = split_scopes(text)
        if not scopes:
            print(f"[WARN] {f}: nenhum escopo analisado (check_type Unix ausente e arquivo vazio?)")
            continue
        for sidx, scope in enumerate(scopes, start=1):
            blocks = iter_custom_blocks(scope)
            if not blocks:
                print(f"[WARN] {f} (scope {sidx}): nenhum <custom_item> encontrado")
                continue
            for cidx, block in enumerate(blocks, start=1):
                if DEBUG:
                    print(f"[debug] Validando {f}::scope{sidx}::item{cidx}")
                item = parse_block(block)
                issues = validate_custom_item(item)
                total_items += 1
                if issues:
                    total_issues += len(issues)
                    for msg in issues:
                        print(f"[FAIL] {f}::scope{sidx}::item{cidx}: {msg}")
                        findings_rows.append({
                            'file': str(f), 'scope_index': sidx, 'item_index': cidx,
                            'type': item.get('type', [''])[0], 'description': item.get('description', [''])[0],
                            'issue': msg
                        })
                else:
                    print(f"[OK]   {f}::scope{sidx}::item{cidx}: válido")

    print("\nResumo:")
    print(f"  Arquivos: {len(files)}")
    print(f"  Itens verificados: {total_items}")
    print(f"  Problemas encontrados: {total_issues}")

    if csv_out is not None:
        csv_out.parent.mkdir(parents=True, exist_ok=True)
        with csv_out.open('w', encoding='utf-8', newline='') as fh:
            w = csv.DictWriter(fh, fieldnames=['file','scope_index','item_index','type','description','issue'])
            w.writeheader()
            for r in findings_rows:
                w.writerow(r)
        print(f"Relatório salvo em: {csv_out}")

if __name__ == '__main__':
    main()
