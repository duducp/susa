# Setup

Comandos para configuração e instalação de ferramentas e ambientes de desenvolvimento.

## Opções da Categoria

O comando `susa setup` oferece opções especiais para gerenciar todos os softwares instalados:

### Listar Instalações

```bash
susa setup --list
```

Lista todos os softwares instalados através do Susa, mostrando:

- Nome do software
- Versão instalada

**Exemplo de saída:**

```text
⏳ Sincronizando instalações...

✓ Softwares instalados (10):

  asdf                 v0.18.0
  docker               29.1.4
  mise                 2026.1.2
  poetry               2.2.1
  vscode               1.107.1
```

### Verificar Atualizações

```bash
susa setup --check-updates
```

Lista todos os softwares instalados e verifica se há atualizações disponíveis:

- Nome do software
- Versão atual
- Versão mais recente (se disponível)
- Indicador visual para atualizações pendentes

**Exemplo de saída:**

```text
⏳ Sincronizando instalações...

✓ Softwares instalados (10) - Verificando atualizações...

  asdf                 v0.18.0
  docker               29.1.4 → 29.2.0 ⚠
  mise                 2026.1.2 → 2026.1.5 ⚠
  poetry               2.2.1
  vscode               1.107.1
```

O ícone ⚠ em amarelo indica que há uma atualização disponível.

### Atualizar Todos os Softwares

```bash
susa setup --upgrade
```

ou

```bash
susa setup -u
```

Atualiza automaticamente todos os softwares instalados para suas versões mais recentes.

**Características:**

- Solicita permissões de sudo no início
- Atualiza cada software sequencialmente
- Mostra progresso em tempo real
- Exibe resumo final com sucessos e falhas

**Exemplo de saída:**

```text
🔄 Iniciando atualização de 10 software(s)...

[1/10] Atualizando asdf...
  ✓ asdf atualizado com sucesso

[2/10] Atualizando docker...
  ✓ docker atualizado com sucesso

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✓ Atualização concluída!

  Total processado: 10
  ✓ Sucesso: 9
  ✗ Falhas: 1
    Softwares com falha: podman
```

### Atualizar Sistema Operacional

```bash
susa setup --upgrade --update-system
```

ou

```bash
susa setup -u -us
```

Atualiza primeiro as dependências do sistema operacional e depois todos os softwares instalados.

**Gerenciadores de Pacotes Suportados:**

- **Linux**: APT (Ubuntu/Debian), DNF (Fedora), YUM (CentOS/RHEL), Pacman (Arch)
- **macOS**: Homebrew

**Características:**

- Detecta automaticamente o gerenciador de pacotes
- Atualiza repositórios e pacotes do sistema
- Continua mesmo se a atualização do sistema falhar
- Mostra output indentado para melhor legibilidade

**Exemplo de saída:**

```text
📦 Atualizando dependências do sistema operacional...

Atualizando pacotes APT...
    Hit:1 http://archive.ubuntu.com/ubuntu jammy InRelease
    Get:2 http://archive.ubuntu.com/ubuntu jammy-updates InRelease
    ...
✓ Pacotes APT atualizados

🔄 Iniciando atualização de 10 software(s)...

[1/10] Atualizando asdf...
  ✓ asdf atualizado com sucesso
...
```

### Combinar Opções

Você pode combinar as opções para diferentes fluxos de trabalho:

```bash
# Verificar atualizações disponíveis
susa setup --check-updates

# Atualizar apenas softwares
susa setup -u

# Atualizar sistema e softwares
susa setup -u -us

# A ordem dos flags não importa
susa setup -us -u
```

## Comandos Disponíveis

### [ASDF](asdf.md)

Instala e configura o ASDF, um gerenciador de versões para múltiplas linguagens de programação.

### [Bruno](bruno.md)

Instala e configura o Bruno, um cliente de API open-source rápido e amigável para Git. Alternativa ao Postman/Insomnia, armazena coleções diretamente em uma pasta no seu sistema de arquivos usando linguagem de marcação própria (Bru). **Disponível para Linux e macOS.**

### [DBeaver](dbeaver.md)

Instala e configura o DBeaver Community, uma ferramenta universal de gerenciamento de banco de dados gratuita e open-source. Suporta mais de 80 tipos diferentes de bancos de dados incluindo MySQL, PostgreSQL, SQLite, Oracle, SQL Server e muitos outros. **Disponível para Linux e macOS.**

### [Docker](docker.md)

Instala e configura o Docker CLI e Engine para gerenciamento de containers. Esta instalação inclui apenas o Docker CLI e Engine, sem o Docker Desktop. **Disponível para Linux e macOS.**

### [Flameshot](flameshot.md)

Instala e configura o Flameshot, uma ferramenta poderosa e simples de captura de tela. Oferece recursos de anotação, edição e compartilhamento de screenshots com interface intuitiva, atalhos de teclado customizáveis e upload direto para Imgur. Ideal para documentação, suporte técnico e comunicação visual. **Disponível para Linux e macOS.**

### [iTerm2](iterm.md)

Instala e configura o iTerm2, um substituto avançado para o Terminal padrão do macOS, com recursos como split panes, busca avançada, autocompletar e muito mais. **Disponível apenas para macOS.**

### [JetBrains Toolbox](jetbrains-toolbox.md)

Instala e configura o JetBrains Toolbox, gerenciador oficial para todas as IDEs da JetBrains (IntelliJ IDEA, PyCharm, WebStorm, GoLand, etc.). Permite instalar, atualizar e gerenciar múltiplas versões das IDEs a partir de uma interface única. **Disponível para Linux e macOS.**

### [Mise](mise.md)

Instala e configura o Mise (anteriormente rtx), um gerenciador de versões polyglot escrito em Rust. Compatível com plugins do ASDF, mas com melhor performance, além de funcionalidades extras como task runner e gerenciamento de variáveis de ambiente. **Disponível para Linux e macOS.**

### [NordPass](nordpass.md)

Instala e configura o NordPass, um gerenciador de senhas seguro e intuitivo. Oferece armazenamento criptografado de senhas, cartões de crédito e notas seguras, com sincronização entre dispositivos e gerador de senhas fortes. **Disponível para Linux e macOS.**

### [Podman](podman.md)

Instala e configura o Podman, um motor de container open-source para desenvolvimento, gerenciamento e execução de containers OCI. É uma alternativa daemon-less e rootless ao Docker.

### [Poetry](poetry.md)

Instala e configura o Poetry, um gerenciador de dependências e empacotamento para Python. Facilita o gerenciamento de bibliotecas, criação de ambientes virtuais e publicação de pacotes Python. **Disponível para Linux e macOS.**

### [Postman](postman.md)

Instala e configura o Postman, uma plataforma completa para desenvolvimento de APIs. Permite criar, testar, documentar e monitorar APIs de forma colaborativa, com suporte a REST, SOAP, GraphQL e WebSocket. **Disponível para Linux e macOS.**

### [Sublime Text](sublime-text.md)

Instala e configura o Sublime Text, um editor de texto sofisticado para código, markup e prosa. Conhecido por sua velocidade, interface limpa e recursos poderosos como múltiplos cursores, busca avançada e extensa biblioteca de plugins. **Disponível para Linux e macOS.**

### [Visual Studio Code](vscode.md)

Instala e configura o Visual Studio Code, editor de código-fonte desenvolvido pela Microsoft. Gratuito e open-source, oferece depuração integrada, controle Git, IntelliSense, extensões e Remote Development. **Disponível para Linux e macOS.**

### [Tilix](tilix.md)

Instala e configura o Tilix, um emulador de terminal avançado para Linux usando GTK+ 3, com suporte a tiles (painéis lado a lado), notificações, transparência e temas personalizáveis. **Disponível apenas para Linux.**

### [UV](uv.md)

Instala e configura o UV (by Astral), um gerenciador de pacotes e projetos Python extremamente rápido, escrito em Rust. Substitui pip, pip-tools, pipx, poetry, pyenv, virtualenv e muito mais, com velocidade 10-100x superior. **Disponível para Linux e macOS.**
