#!/usr/bin/env python3
"""Monta um audit Tenable com blocos condicionais EL7-9 e EL6."""

import ast
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent
MODERN = ROOT / "COMPLIANCE_CLARO-TI-JIRA_RHEL7-9_FULL_PRE_V1.3.5_120820261055.audit"
LEGACY = ROOT / "COMPLIANCE_CLARO_RHEL6_LEGADO_CUSTOM.audit"
OUTPUT = ROOT / "COMPLIANCE_CLARO-TI_RHEL6-9_FULLV1.3.5_280820261435.audit"


def blocks(path):
    return re.findall(r'<custom_item>\n.*?</custom_item>', path.read_text(encoding='utf-8'), re.S)


def value(block, field):
    match = re.search(rf'^\s*{field}\s*:\s*("(?:\\.|[^"\\])*")', block, re.M)
    if not match:
        raise ValueError(f'campo {field} ausente')
    return ast.literal_eval(match.group(1))


def item_id(block):
    match = re.match(r'(\d+),', value(block, 'description'))
    if not match:
        raise ValueError('description sem ID')
    return int(match.group(1))


def quoted(text):
    return '"' + text.replace('\\', '\\\\').replace('"', '\\"') + '"'


def replace_field(block, field, new_value):
    return re.sub(rf'^(\s*{field}\s*:\s*).+$', lambda m: m.group(1) + quoted(new_value), block, count=1, flags=re.M)


modern = blocks(MODERN)
legacy = {
    int(re.match(r'RHEL6-(\d+)', value(block, 'description')).group(1)): block
    for block in blocks(LEGACY)
}


def normalize_operational_description(block):
    """Completa criticidade ausente nos controles operacionais para o parser."""
    if item_id(block) not in (999, 1000, 1001):
        return block
    description = value(block, 'description')
    return replace_field(block, 'description', description + ', Não informada')


modern = [normalize_operational_description(block) for block in modern]

# Correspondência semântica: ID principal -> ID do comando EL6 legado.
# Os metadados e IDs continuam sendo sempre os do audit principal.
LEGACY_MAP = {
    **{i: i for i in range(1, 14)},
    14:16, 16:17, 17:15, 19:18, 20:19, 22:20, 23:21, 24:14,
    25:22, 26:23, 27:24, 28:25, 29:26, 30:27, 31:28,
    37:29, 38:30, 39:31, 40:32, 41:33, 42:34,
    44:35, 45:36, 46:37, 47:38, 48:39, 49:40, 50:41, 51:42,
    56:43, 57:44, 58:45, 61:49, 62:50, 63:51,
    64:52, 65:53, 66:54, 67:55, 68:56, 69:57, 70:58, 71:59,
    72:60, 73:61, 74:62, 75:63, 76:64, 77:65, 78:66, 79:67,
    80:68, 81:69, 82:70, 83:71, 84:72, 85:73, 87:74, 88:75,
    89:48, 91:78, 92:79, 93:80, 94:81, 95:82, 96:83, 97:84,
    98:85, 99:86, 102:87,
    109:93, 110:95, 111:97, 112:98, 113:99, 114:100, 115:101,
    116:102, 117:103, 118:104, 119:105, 120:106, 121:107,
    122:108, 123:109, 124:110, 125:111, 126:112, 127:113,
    130:114, 131:115, 132:116, 134:117, 139:118, 140:117,
    141:116, 142:116, 143:119, 144:120, 145:121, 146:122,
    148:124, 149:125, 150:126, 151:127, 152:128, 153:129,
    154:130, 155:131, 156:132, 157:133, 158:134, 159:135, 160:136,
    161:137, 162:138, 164:139, 165:140, 166:141, 167:144, 168:145,
    169:146, 170:147, 171:148, 173:150, 174:151, 175:151,
    176:152, 177:153, 178:154, 179:155, 180:156, 181:157,
    182:158, 183:159, 184:160, 185:161, 186:162, 187:163,
    188:164, 189:166, 190:165, 191:167, 192:168, 193:126,
    194:169, 195:170, 197:171, 198:172, 199:173, 200:174,
    201:175, 202:176, 203:177,
}

# Sem equivalente seguro no EL6: saída explícita não casa com expect, logo o
# Nessus registra falha com evidência, nunca falso PASS.
EL6_UNSUPPORTED = {
    15: 'kernel.yama.ptrace_scope pode não existir no kernel EL6',
    21: 'user namespaces não possuem interface uniforme no EL6',
    32: 'ponto /historico depende do desenho local e não consta da baseline EL6',
    33: 'ponto /crash depende do desenho local e não consta da baseline EL6',
    34: 'ponto /UNIX depende do desenho local e não consta da baseline EL6',
    35: 'política agregada de mídias removíveis não possui equivalente único EL6',
    36: 'política agregada de partições críticas foi desmembrada no EL6',
    43: 'descoberta uniforme de mídias removíveis requer utilitário ausente no EL6',
    86: 'PolicyKit do EL6 não oferece a mesma política do EL7-9',
    90: 'controle conjunto cron/at precisa ser avaliado pelos controles EL6 específicos',
    108: 'update-crypto-policies não existe no EL6',
    128: 'preferência criptográfica moderna não é suportada pelo OpenSSH 5.3 do EL6',
    129: 'ForceCommand/Chroot depende da função e da versão do OpenSSH EL6',
    133: 'no EL6 pam_tally2 é esperado, portanto sua ausência não é aplicável',
    135: 'pwquality.conf não é o mecanismo nativo de complexidade do EL6',
    136: 'minclass em pwquality.conf não é o mecanismo nativo do EL6',
    137: 'maxrepeat/maxsequence não possuem equivalência segura no pam_cracklib EL6',
    138: 'dictcheck de pwquality não possui equivalência uniforme no EL6',
}


def el6_clone(block):
    ident = item_id(block)
    if ident in LEGACY_MAP:
        command = value(legacy[LEGACY_MAP[ident]], 'cmd')
    elif ident in EL6_UNSUPPORTED:
        command = f'echo "ERROR | EL6 | ID {ident:03d} | {EL6_UNSUPPORTED[ident]}"'
    else:
        # POSIX/rpm/awk/find sem incompatibilidade conhecida: preserva a lógica.
        command = value(block, 'cmd').replace('grep -P', 'grep -E').replace('\\h', '[[:space:]]')
    return replace_field(block, 'cmd', command)


BASE_RELEASE = (
    "rel=$(cat /etc/redhat-release 2>/dev/null); rhel=$(rpm -E '%{rhel}' 2>/dev/null); "
    "major=$(echo \"$rel\" | grep -oE '[0-9]+(\\.[0-9]+)+' | head -1 | cut -d. -f1); "
    "[ -n \"$major\" ] || major=$rhel; "
    "{ echo \"$rhel\" | grep -Eq '^[0-9]+$' || echo \"$rel\" | grep -Eiq "
    "'(Red Hat Enterprise Linux|Oracle Linux|AlmaLinux|Rocky Linux|CentOS)'; }"
)
EL6_RELEASE = BASE_RELEASE + " && [ \"$major\" = 6 ] && echo PASS || echo FAIL"
EL79_RELEASE = BASE_RELEASE + " && echo \"$major\" | grep -Eq '^(7|8|9)$' && echo PASS || echo FAIL"


def condition(command, description):
    return '\n'.join([
        '<condition type:"and">', '<custom_item>',
        '  type        : CMD_EXEC', f'  description : "{description}"',
        '  info        : "Seleciona o bloco de auditoria pela versão real do sistema operacional."',
        '  solution    : "Executar o bloco correspondente à versão detectada."',
        '  reference   : "Seleção de plataforma RHEL family"',
        '  see_also    : "CDB-XPTO"',
        f'  cmd         : {quoted(command)}',
        '  expect      : "(?i)^\\\\s*PASS\\\\s*$"',
        '</custom_item>', '</condition>',
    ])


parts = [
    '<check_type:"Unix">', '',
    '# Seleção de bloco feita uma única vez pela estrutura if/then/else Tenable.',
    '# EL7-9 executa o audit original; EL6 executa clone com CMD adaptado.', '',
    '<if>', condition(EL79_RELEASE, 'Detectar sistema da família RHEL versão 7, 8 ou 9'),
    '<then>', '\n\n'.join(modern), '</then>', '<else>', '<if>',
    condition(EL6_RELEASE, 'Detectar sistema da família RHEL versão 6'),
    '<then>', '\n\n'.join(el6_clone(block) for block in modern), '</then>', '<else>',
    '<custom_item>',
    '  type        : CMD_EXEC',
    '  description : "000, Sistema operacional fora do escopo RHEL family 6-9, Alta"',
    '  info        : "O sistema operacional não foi identificado como RHEL family versão 6, 7, 8 ou 9."',
    '  solution    : "Aplicar este audit somente aos sistemas operacionais suportados."',
    '  reference   : "Seleção de plataforma RHEL family"',
    '  see_also    : "CDB-XPTO"',
    '  cmd         : "echo \\"FAIL | SO_NAO_SUPORTADO | $(cat /etc/redhat-release 2>/dev/null || uname -sr)\\""',
    '  expect      : "(?i)^\\\\s*PASS\\\\s*$"',
    '</custom_item>', '</else>', '</if>', '</else>', '</if>', '', '</check_type>', '',
]
OUTPUT.write_text('\n'.join(parts), encoding='utf-8')
print(f'{OUTPUT.name}: {len(modern)} itens EL7-9 + {len(modern)} clones EL6')
