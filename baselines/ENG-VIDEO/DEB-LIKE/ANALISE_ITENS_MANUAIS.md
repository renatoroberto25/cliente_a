16 - MANUAL porque habilitar NX/XD depende do suporte da CPU, firmware/BIOS e configuração do kernel ou boot, podendo exigir intervenção fora do sistema e reinicialização.
23 - MANUAL porque criar uma partição dedicada para /tmp exige conhecer discos, LVM, capacidade, dados em uso e janela de manutenção, além de validar fstab e boot com rollback.
24 - MANUAL porque separar /dev/shm exige definir tamanho e opções do tmpfs conforme a carga de IPC das aplicações, e uma alteração genérica pode interromper processos.
25 - MANUAL porque migrar /var para partição própria movimenta dados essenciais do sistema e serviços, exigindo planejamento de armazenamento, parada, console e validação de boot.
26 - MANUAL porque migrar /var/tmp exige preservar arquivos persistentes e processos que os utilizam, além de definir armazenamento e montagem específicos do servidor.
27 - MANUAL porque separar /var/log envolve dados ativos de logging, dimensionamento e continuidade dos serviços, não sendo seguro mover ou remontar genericamente.
28 - MANUAL porque separar /var/log/audit afeta diretamente o auditd e a cadeia de evidências, exigindo dimensionamento, preservação dos logs e janela controlada.
29 - MANUAL porque migrar /home envolve dados, ownerships, quotas e sessões de usuários, exigindo escolha de volume, cópia validada e plano de retorno.
30 - MANUAL porque /historico é um ponto de montagem específico do ambiente e o script não pode decidir dispositivo, filesystem, capacidade ou conteúdo a migrar.
31 - MANUAL porque /crash depende da estratégia de crash dump, do espaço necessário e do dispositivo disponível, podendo afetar a captura de diagnóstico após falhas.
32 - MANUAL porque /UNIX é um caminho específico do ambiente e suas dependências de aplicação, volume, filesystem e migração precisam ser conhecidas antes da montagem.
33 - MANUAL porque aplicar nodev em mídias removíveis exige inventariar quais montagens e dispositivos são autorizados; uma regra genérica pode bloquear uso legítimo.
34 - MANUAL porque aplicar nodev em partições críticas depende do layout real e da necessidade de arquivos de dispositivo pelas aplicações, além de envolver risco de remontagem e boot.
35 - MANUAL porque endurecer a montagem de /var/log exige validar o layout e a compatibilidade das opções com agentes e serviços que gravam logs.
36 - MANUAL porque endurecer /var/log/audit exige preservar o funcionamento do auditd e a coleta de evidências, com alteração de montagem validada em janela controlada.
37 - MANUAL porque endurecer /home exige avaliar aplicações e usuários que possam depender de opções de montagem incompatíveis com a política proposta.
38 - MANUAL porque diretórios world-writable precisam ser revisados individualmente antes da aplicação do sticky bit; a ação é automatizável após uma allowlist, mas pode alterar diretórios compartilhados de aplicações.
43 - MANUAL porque a senha do bootloader exige definição e custódia de credencial, geração segura do hash e teste de boot e recuperação por console.
45 - MANUAL porque exigir autenticação no modo single-user altera o fluxo de recuperação e varia conforme GRUB, systemd e políticas locais, podendo eliminar o acesso emergencial.
49 - MANUAL porque o script não pode escolher quais fontes NTP são confiáveis nem qual daemon deve prevalecer sem a política de rede e os endpoints aprovados pelo cliente.
65 - MANUAL porque restringir o MTA ao modo local depende do software instalado, dos relays e das aplicações que enviam e-mail, podendo interromper notificações legítimas.
76 - MANUAL porque regras locais do PolicyKit precisam de análise semântica de ações, sujeitos e necessidade funcional; remover concessões automaticamente pode bloquear administração ou serviços.
77 - MANUAL porque corrigir assinaturas APT exige decidir quais repositórios e chaves são confiáveis, migrar keyrings e preservar fontes corporativas aprovadas.
78 - MANUAL porque a instalação é tecnicamente automatizável, mas atualizações de segurança podem alterar dependências, reiniciar serviços ou exigir reboot e, portanto, precisam de aprovação, janela e testes.
105 - MANUAL porque alterar a pilha PAM e a política de complexidade varia conforme módulos e integrações de identidade, e um ajuste genérico pode bloquear login, SSH e sudo.
120 - MANUAL porque corrigir datas de senha exige avaliar cada conta, inclusive contas técnicas, antes de usar chage ou alterar shadow para não causar expiração ou bloqueio indevido.
121 - MANUAL porque remover UID 0 de outra conta exige identificar sua finalidade, definir novo UID e corrigir ownerships associados sem perder acesso administrativo.
122 - MANUAL porque remover GID 0 de outro grupo exige investigar membros e arquivos associados, escolher novo GID e ajustar ownerships sem quebrar permissões.
123 - MANUAL porque trocar ou bloquear o shell de contas de sistema exige confirmar como cada serviço executa comandos e se há dependência de login interativo.
125 - MANUAL porque sanear o PATH do root exige localizar a origem das entradas, validar scripts e ferramentas administrativas e evitar remover caminhos necessários ao ambiente.
