# Setup VS Code

Instala o Visual Studio Code, um editor de código-fonte desenvolvido pela Microsoft, gratuito e open-source, com depuração integrada, controle Git, IntelliSense e extenso marketplace de extensões.

## O que é VS Code?

Visual Studio Code (VS Code) é um editor de código leve mas poderoso que combina simplicidade com funcionalidades avançadas de desenvolvimento:

- **IntelliSense**: Autocompletar inteligente com informações de tipo e parâmetros
- **Depurador Integrado**: Debug direto no editor com breakpoints, call stack e console
- **Controle Git**: Interface visual para Git com diff, staging, commits e merge
- **Terminal Integrado**: Execute comandos sem sair do editor
- **Extensões**: Marketplace com milhares de extensões para linguagens e ferramentas
- **Remote Development**: Desenvolva em containers, SSH ou WSL

**Por exemplo:**

```typescript
// IntelliSense em ação
function calculateTotal(items: Item[]): number {
    return items
        .filter(item => item.active)  // ← Autocomplete sugere propriedades
        .reduce((sum, item) => sum + item.price, 0);
}
```

## Como usar

### Instalar

```bash
susa setup vscode
```

O comando vai:

**No macOS:**

- Verificar se o Homebrew está instalado
- Instalar o VS Code via `brew install --cask visual-studio-code`
- Configurar o comando `code` no PATH

**No Linux:**

- Detectar sua distribuição (Debian/Ubuntu, RHEL/Fedora, Arch)
- Adicionar a chave GPG oficial da Microsoft
- Configurar o repositório apropriado
- Instalar via gerenciador de pacotes nativo
- Configurar o comando `code`

Depois de instalar, você pode abrir o VS Code:

```bash
code                  # Abre o editor
code arquivo.txt      # Abre arquivo específico
code pasta/           # Abre pasta como workspace
code -r arquivo.txt   # Reutiliza janela existente
```

### Atualizar

```bash
susa setup vscode --upgrade
```

Atualiza o VS Code para a versão mais recente disponível. O comando usa:

- **macOS**: `brew upgrade --cask visual-studio-code`
- **Debian/Ubuntu**: `apt-get install --only-upgrade code`
- **RHEL/Fedora**: `dnf upgrade code`
- **Arch**: `yay -Syu visual-studio-code-bin`

Todas as suas configurações, extensões e temas serão preservados.

### Desinstalar

```bash
susa setup vscode --uninstall
```

Remove o VS Code do sistema. O comando vai:

1. Remover o binário e pacote
2. Remover repositórios configurados
3. Perguntar se deseja remover configurações e extensões:
   - `~/.config/Code` (Linux)
   - `~/Library/Application Support/Code` (macOS)
   - `~/.vscode`

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `-u, --upgrade` | Atualiza o VS Code para a versão mais recente |
| `--uninstall` | Remove o VS Code do sistema |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída, desabilita mensagens de depuração |

## Guia Rápido de Uso

### Atalhos Essenciais

**Navegação**

```text
Ctrl/Cmd+P         - Quick Open (busca rápida de arquivos)
Ctrl/Cmd+Shift+P   - Command Palette
Ctrl/Cmd+T         - Ir para símbolo no workspace
F12                - Ir para definição
Alt+F12            - Peek definition
Ctrl/Cmd+G         - Ir para linha
```

**Edição**

```text
Ctrl/Cmd+D         - Selecionar próxima ocorrência
Ctrl/Cmd+Shift+L   - Selecionar todas as ocorrências
Alt+Click          - Adicionar cursor
Ctrl/Cmd+/         - Toggle comentário
Shift+Alt+F        - Formatar documento
Ctrl/Cmd+.         - Quick fix
```

**Busca e Refatoração**

```text
Ctrl/Cmd+F         - Buscar no arquivo
Ctrl/Cmd+H         - Buscar e substituir
Ctrl/Cmd+Shift+F   - Buscar em arquivos
F2                 - Renomear símbolo
Ctrl/Cmd+Shift+O   - Ir para símbolo no arquivo
```

**Depuração**

```text
F5                 - Iniciar/Continuar debug
F9                 - Toggle breakpoint
F10                - Step over
F11                - Step into
Shift+F11          - Step out
Shift+F5           - Parar debug
```

**Terminal e Git**

```text
Ctrl/Cmd+`         - Toggle terminal
Ctrl/Cmd+Shift+`   - Novo terminal
Ctrl/Cmd+Shift+G   - Abrir controle Git
Ctrl/Cmd+K Ctrl+Cmd+S - Git: Stage changes
```

### Extensões Essenciais

**Linguagens e Frameworks**

```bash
# Instalar via Command Palette (Ctrl/Cmd+Shift+P → Extensions: Install Extensions)
Python                     # Python IntelliSense e debug
Pylance                    # Type checking Python
ESLint                     # JavaScript/TypeScript linting
Prettier                   # Formatador de código
vscode-icons              # Ícones de arquivos
GitLens                    # Git supercharged
```

**Desenvolvimento**

```bash
Docker                     # Suporte a Docker
Remote - SSH              # Desenvolva via SSH
Remote - Containers       # Desenvolva em containers
Live Share                # Pair programming
Thunder Client            # API testing (alternativa ao Postman)
REST Client               # Testar APIs HTTP
```

**Produtividade**

```bash
Path Intellisense         # Autocomplete de paths
Auto Rename Tag           # Rename HTML tags
Bracket Pair Colorizer    # Colore pares de colchetes
TODO Highlight            # Destaca TODOs e FIXMEs
Error Lens                # Mostra erros inline
```

**Linguagens Específicas**

```bash
# Python
Jupyter                   # Notebooks Jupyter
autoDocstring            # Gera docstrings

# JavaScript/TypeScript
Quokka.js                # Live scratchpad
Import Cost              # Mostra tamanho de imports

# Go
Go                       # Go language support

# Rust
rust-analyzer            # Rust language server

# Java
Extension Pack for Java  # Pack completo Java
```

### Instalando Extensões via CLI

```bash
# Listar extensões instaladas
code --list-extensions

# Instalar extensão
code --install-extension ms-python.python
code --install-extension esbenp.prettier-vscode
code --install-extension dbaeumer.vscode-eslint

# Desinstalar extensão
code --uninstall-extension extensao.id
```

### Configurações Recomendadas

Abra as configurações: `Ctrl/Cmd+,` ou `File → Preferences → Settings`

```json
{
    // Editor
    "editor.fontSize": 14,
    "editor.fontFamily": "'JetBrains Mono', 'Fira Code', Consolas, monospace",
    "editor.fontLigatures": true,
    "editor.lineHeight": 1.6,
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "editor.formatOnSave": true,
    "editor.formatOnPaste": true,
    "editor.rulers": [80, 120],
    "editor.minimap.enabled": true,
    "editor.suggestSelection": "first",
    "editor.inlineSuggest.enabled": true,
    "editor.bracketPairColorization.enabled": true,

    // Arquivos
    "files.autoSave": "onFocusChange",
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "files.exclude": {
        "**/.git": true,
        "**/.DS_Store": true,
        "**/node_modules": true,
        "**/__pycache__": true,
        "**/*.pyc": true
    },

    // Terminal
    "terminal.integrated.fontSize": 13,
    "terminal.integrated.fontFamily": "MesloLGS NF",
    "terminal.integrated.cursorBlinking": true,

    // Git
    "git.autofetch": true,
    "git.confirmSync": false,
    "git.enableSmartCommit": true,

    // Workbench
    "workbench.colorTheme": "One Dark Pro",
    "workbench.iconTheme": "vscode-icons",
    "workbench.startupEditor": "none",
    "workbench.editor.enablePreview": false,

    // IntelliSense
    "editor.quickSuggestions": {
        "other": true,
        "comments": false,
        "strings": true
    },

    // Python (se instalado)
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black",

    // JavaScript/TypeScript
    "[javascript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[typescript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    },
    "[json]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode"
    }
}
```

### Workspaces e Projetos

**Criar um Workspace:**

1. Abra uma pasta: `File → Open Folder`
2. Adicione mais pastas: `File → Add Folder to Workspace`
3. Salve o workspace: `File → Save Workspace As`

**Exemplo de `.vscode/settings.json` por projeto:**

```json
{
    "python.defaultInterpreterPath": ".venv/bin/python",
    "python.terminal.activateEnvironment": true,
    "python.testing.pytestEnabled": true,
    "python.testing.pytestArgs": [
        "tests"
    ],
    "files.exclude": {
        "**/__pycache__": true,
        "**/.pytest_cache": true,
        "**/.venv": true
    }
}
```

### Depuração

**Configurar launch.json:**

Pressione `F5` ou crie `.vscode/launch.json`:

**Python:**

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Python: Current File",
            "type": "python",
            "request": "launch",
            "program": "${file}",
            "console": "integratedTerminal",
            "justMyCode": true
        },
        {
            "name": "Python: Flask",
            "type": "python",
            "request": "launch",
            "module": "flask",
            "env": {
                "FLASK_APP": "app.py",
                "FLASK_DEBUG": "1"
            },
            "args": [
                "run",
                "--no-debugger",
                "--no-reload"
            ]
        }
    ]
}
```

**Node.js:**

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Node: Current File",
            "type": "node",
            "request": "launch",
            "program": "${file}",
            "skipFiles": [
                "<node_internals>/**"
            ]
        },
        {
            "name": "Node: Attach",
            "type": "node",
            "request": "attach",
            "port": 9229
        }
    ]
}
```

### Tasks (Automação)

Crie `.vscode/tasks.json` para automatizar tarefas:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Run Tests",
            "type": "shell",
            "command": "pytest",
            "group": {
                "kind": "test",
                "isDefault": true
            },
            "presentation": {
                "reveal": "always",
                "panel": "new"
            }
        },
        {
            "label": "Build",
            "type": "shell",
            "command": "npm run build",
            "group": {
                "kind": "build",
                "isDefault": true
            }
        }
    ]
}
```

Execute com: `Ctrl/Cmd+Shift+B` (build) ou `Ctrl/Cmd+Shift+T` (test)

### Snippets Personalizados

Crie snippets: `File → Preferences → User Snippets`

**Python snippet:**

```json
{
    "Python Main": {
        "prefix": "pymain",
        "body": [
            "#!/usr/bin/env python3",
            "# -*- coding: utf-8 -*-",
            "",
            "def main():",
            "    ${1:pass}",
            "",
            "",
            "if __name__ == '__main__':",
            "    main()"
        ],
        "description": "Python main template"
    }
}
```

### Remote Development

**Desenvolver via SSH:**

1. Instale extensão: `Remote - SSH`
2. Command Palette: `Remote-SSH: Connect to Host`
3. Digite: `user@hostname`
4. Selecione pasta remota

**Desenvolver em Containers:**

1. Instale extensão: `Remote - Containers`
2. Crie `.devcontainer/devcontainer.json`:

```json
{
    "name": "Python Dev",
    "image": "mcr.microsoft.com/vscode/devcontainers/python:3.11",
    "features": {
        "ghcr.io/devcontainers/features/git:1": {}
    },
    "postCreateCommand": "pip install -r requirements.txt",
    "customizations": {
        "vscode": {
            "extensions": [
                "ms-python.python",
                "ms-python.vscode-pylance"
            ]
        }
    }
}
```

3. Command Palette: `Remote-Containers: Reopen in Container`

## Recursos Avançados

### Keybindings Personalizados

`File → Preferences → Keyboard Shortcuts` ou `keybindings.json`:

```json
[
    {
        "key": "ctrl+shift+d",
        "command": "editor.action.copyLinesDownAction"
    },
    {
        "key": "ctrl+shift+k",
        "command": "editor.action.deleteLines"
    },
    {
        "key": "ctrl+alt+l",
        "command": "editor.action.formatDocument"
    }
]
```

### Multi-root Workspaces

Trabalhe com múltiplos projetos simultaneamente:

```json
{
    "folders": [
        {
            "path": "../frontend"
        },
        {
            "path": "../backend"
        },
        {
            "path": "../shared"
        }
    ],
    "settings": {
        "files.exclude": {
            "**/node_modules": true
        }
    }
}
```

### Live Share

Colaboração em tempo real:

1. Instale: `Live Share Extension Pack`
2. Command Palette: `Live Share: Start Collaboration Session`
3. Compartilhe o link com colegas
4. Colaborem no mesmo código em tempo real

### Profiles

Crie perfis para diferentes workflows:

```bash
# Criar perfil Python
code --profile "Python Dev" --install-extension ms-python.python

# Criar perfil Web
code --profile "Web Dev" --install-extension esbenp.prettier-vscode
```

## Troubleshooting

### VS Code não abre

```bash
# Verificar se está instalado
which code
code --version

# Reinstalar se necessário
susa setup vscode --uninstall
susa setup vscode
```

### Extensões não carregam

```bash
# Limpar cache de extensões
rm -rf ~/.vscode/extensions/*

# Reinstalar extensões
code --list-extensions | xargs -L 1 code --install-extension
```

### IntelliSense não funciona

```bash
# Python
code --install-extension ms-python.vscode-pylance

# JavaScript/TypeScript
# Reinstale node_modules
rm -rf node_modules package-lock.json
npm install
```

### Terminal não abre

```bash
# Verificar shell padrão
echo $SHELL

# Configurar shell em settings.json
"terminal.integrated.defaultProfile.linux": "bash"
```

## Dicas de Produtividade

1. **Use Command Palette** (`Ctrl/Cmd+Shift+P`) - Acesso rápido a tudo
2. **Domine múltiplos cursores** (`Alt+Click`) - Edição em massa
3. **Quick Open** (`Ctrl/Cmd+P`) - Navegação instantânea
4. **Atalhos de refatoração** (`F2`, `Ctrl/Cmd+.`) - Refatore com segurança
5. **Zen Mode** (`Ctrl/Cmd+K Z`) - Foco total no código
6. **Split Editor** (`Ctrl/Cmd+\`) - Visualize múltiplos arquivos
7. **Breadcrumbs** - Navegue pela estrutura do arquivo
8. **Peek Definition** (`Alt+F12`) - Veja definições sem sair do contexto
9. **Git Lens** - Entenda histórico de mudanças
10. **Snippets** - Crie templates para código repetitivo

## Comparação: VS Code vs Outros Editores

| Recurso | VS Code | Sublime Text | Vim/Neovim |
|---------|---------|--------------|------------|
| Gratuito | ✅ | Avaliação | ✅ |
| Open Source | ✅ | ❌ | ✅ |
| IntelliSense | ✅✅✅ | ✅ | ✅✅ |
| Debug Integrado | ✅✅✅ | ❌ | ✅ |
| Git Integrado | ✅✅✅ | Plugin | Plugin |
| Extensões | ✅✅✅ | ✅✅ | ✅✅✅ |
| Velocidade | ✅✅ | ✅✅✅ | ✅✅✅ |
| Curva de Aprendizado | Fácil | Fácil | Difícil |
| Remote Dev | ✅✅✅ | ❌ | ✅✅ |

## Recursos Adicionais

- **Documentação oficial**: <https://code.visualstudio.com/docs>
- **Marketplace**: <https://marketplace.visualstudio.com>
- **Blog oficial**: <https://code.visualstudio.com/blogs>
- **Tips and Tricks**: <https://code.visualstudio.com/docs/getstarted/tips-and-tricks>
- **Awesome VS Code**: <https://github.com/viatsko/awesome-vscode>
- **VS Code Can Do That**: <https://vscodecandothat.com>

## Variáveis de Ambiente

O comando usa as seguintes variáveis configuráveis em `command.json`:

```json
{
  "VSCODE_HOMEBREW_CASK": "visual-studio-code",
  "VSCODE_APT_KEY_URL": "https://packages.microsoft.com/keys/microsoft.asc",
  "VSCODE_APT_REPO": "https://packages.microsoft.com/repos/code",
  "VSCODE_RPM_KEY_URL": "https://packages.microsoft.com/keys/microsoft.asc",
  "VSCODE_RPM_REPO_URL": "https://packages.microsoft.com/yumrepos/vscode"
}
```

## Sistemas Operacionais Suportados

- ✅ **macOS**: Via Homebrew Cask
- ✅ **Linux - Debian/Ubuntu**: Via repositório apt da Microsoft
- ✅ **Linux - Fedora/RHEL/CentOS**: Via repositório RPM da Microsoft
- ✅ **Linux - Arch/Manjaro**: Via AUR (visual-studio-code-bin)
- ❌ **Windows**: Não suportado por este comando

## Exemplos Práticos

### Workflow Completo - Projeto Python

```bash
# 1. Instalar VS Code
susa setup vscode

# 2. Criar projeto
mkdir meu-projeto && cd meu-projeto
python -m venv .venv
source .venv/bin/activate

# 3. Abrir no VS Code
code .

# 4. Instalar extensões Python
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-python.black-formatter

# 5. Criar .vscode/settings.json
cat > .vscode/settings.json << 'EOF'
{
    "python.defaultInterpreterPath": ".venv/bin/python",
    "python.linting.enabled": true,
    "python.linting.pylintEnabled": false,
    "python.linting.flake8Enabled": true,
    "python.formatting.provider": "black",
    "editor.formatOnSave": true
}
EOF

# 6. Começar a codar!
```

### Workflow Completo - Projeto Node.js

```bash
# 1. Criar projeto
mkdir app && cd app
npm init -y

# 2. Abrir no VS Code
code .

# 3. Instalar extensões
code --install-extension esbenp.prettier-vscode
code --install-extension dbaeumer.vscode-eslint

# 4. Configurar .vscode/settings.json
cat > .vscode/settings.json << 'EOF'
{
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "eslint.validate": ["javascript", "typescript"]
}
EOF

# 5. Desenvolvimento!
```

## Próximos Passos

Depois de instalar o VS Code:

1. ✅ Instale extensões para suas linguagens principais
2. ✅ Configure settings.json com suas preferências
3. ✅ Aprenda atalhos essenciais (Command Palette, Quick Open)
4. ✅ Configure snippets para código repetitivo
5. ✅ Explore o marketplace de extensões
6. ✅ Configure depuração para seus projetos
7. ✅ Experimente Remote Development
8. ✅ Personalize keybindings
9. ✅ Use Git integrado para controle de versão
10. ✅ Explore Live Share para pair programming
