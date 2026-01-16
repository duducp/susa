# Setup Sublime Text

Instala o Sublime Text, um editor de texto sofisticado para código, markup e prosa, conhecido por sua velocidade, interface limpa e recursos poderosos.

## O que é Sublime Text?

Sublime Text é um editor de texto e código multiplataforma que combina simplicidade com funcionalidades avançadas:

- **Múltiplos Cursores**: Edite várias linhas simultaneamente
- **Command Palette**: Acesso rápido a todas as funcionalidades (Ctrl/Cmd+Shift+P)
- **Goto Anything**: Navegação instantânea por arquivos e símbolos (Ctrl/Cmd+P)
- **Distraction Free Mode**: Modo de edição fullscreen sem distrações
- **Syntax Highlighting**: Suporte a centenas de linguagens de programação
- **Package Control**: Ecossistema extenso de plugins e temas

**Por exemplo:**

```python
# Edite múltiplas linhas ao mesmo tempo com Alt+Click
def process_item1():    # Cursor 1
    return item1        # Cursor 1

def process_item2():    # Cursor 2
    return item2        # Cursor 2

def process_item3():    # Cursor 3
    return item3        # Cursor 3
```

## Como usar

### Instalar

```bash
susa setup sublime-text
```

O comando vai:

**No macOS:**

- Verificar se o Homebrew está instalado
- Instalar o Sublime Text via `brew install --cask sublime-text`
- Configurar o comando `subl` no PATH

**No Linux:**

- Detectar sua distribuição (Debian/Ubuntu, RHEL/Fedora, Arch)
- Adicionar a chave GPG oficial do Sublime Text
- Configurar o repositório apropriado
- Instalar via gerenciador de pacotes nativo
- Configurar o comando `subl`

Depois de instalar, você pode abrir o Sublime Text:

```bash
subl                  # Abre o editor
subl arquivo.txt      # Abre arquivo específico
subl pasta/           # Abre pasta como projeto
```

### Atualizar

```bash
susa setup sublime-text --upgrade
```

Atualiza o Sublime Text para a versão mais recente disponível. O comando usa:

- **macOS**: `brew upgrade --cask sublime-text`
- **Debian/Ubuntu**: `apt-get install --only-upgrade sublime-text`
- **RHEL/Fedora**: `dnf upgrade sublime-text`
- **Arch**: `yay -Syu sublime-text-4`

Todas as suas configurações, plugins e temas serão preservados.

### Desinstalar

```bash
susa setup sublime-text --uninstall
```

Remove o Sublime Text do sistema. O comando vai:

1. Remover o binário e pacote
2. Remover repositórios configurados
3. Perguntar se deseja remover configurações pessoais:
   - `~/.config/sublime-text` (Linux)
   - `~/Library/Application Support/Sublime Text` (macOS)

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `-u, --upgrade` | Atualiza o Sublime Text para a versão mais recente |
| `--uninstall` | Remove o Sublime Text do sistema |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída, desabilita mensagens de depuração |

## Guia Rápido de Uso

### Atalhos Essenciais

**Navegação**

```
Ctrl/Cmd+P         - Goto Anything (busca rápida de arquivos)
Ctrl/Cmd+R         - Goto Symbol (busca funções/classes)
Ctrl/Cmd+G         - Goto Line (ir para linha específica)
Ctrl/Cmd+;         - Goto Word (busca palavra no projeto)
Ctrl/Cmd+Shift+P   - Command Palette
```

**Edição Múltipla**

```
Ctrl/Cmd+D         - Selecionar próxima ocorrência da palavra
Ctrl/Cmd+Click     - Adicionar cursor
Alt+Shift+↑/↓      - Expandir seleção para cima/baixo
Ctrl/Cmd+Shift+L   - Dividir seleção em linhas
Ctrl/Cmd+J         - Juntar linhas
```

**Busca e Substituição**

```
Ctrl/Cmd+F         - Buscar no arquivo
Ctrl/Cmd+H         - Buscar e substituir
Ctrl/Cmd+Shift+F   - Buscar em arquivos
F3                 - Próxima ocorrência
Shift+F3           - Ocorrência anterior
```

**Projetos e Arquivos**

```
Ctrl/Cmd+N         - Novo arquivo
Ctrl/Cmd+S         - Salvar
Ctrl/Cmd+Shift+S   - Salvar como
Ctrl/Cmd+W         - Fechar aba
Ctrl/Cmd+Shift+T   - Reabrir última aba fechada
Ctrl/Cmd+K, B      - Toggle sidebar
```

### Instalando Package Control

O Package Control é o gerenciador de plugins do Sublime Text. Para instalar:

1. Abra o Command Palette: `Ctrl/Cmd+Shift+P`
2. Digite: `Install Package Control`
3. Pressione Enter
4. Aguarde a instalação

Depois de instalar:

```
Ctrl/Cmd+Shift+P → Package Control: Install Package
```

### Plugins Recomendados

**Desenvolvimento**

```bash
# Via Package Control (Ctrl/Cmd+Shift+P → Install Package)
LSP                    # Language Server Protocol
GitGutter              # Diff do Git na gutter
SideBarEnhancements    # Mais opções no sidebar
BracketHighlighter     # Destaca pares de colchetes
Emmet                  # Snippets HTML/CSS
```

**Linguagens**

```bash
Python Improved        # Melhor syntax para Python
TypeScript Syntax      # Suporte TypeScript
Rust Enhanced          # Syntax Rust
Vue Syntax Highlight   # Syntax Vue.js
Docker                 # Syntax Dockerfile
```

**Temas e Aparência**

```bash
Material Theme         # Material Design theme
Dracula Color Scheme   # Tema Dracula
One Dark Color Scheme  # Tema One Dark
A File Icon            # Ícones de arquivos
```

### Configurações Úteis

Abra as configurações do usuário: `Preferences → Settings` ou `Ctrl/Cmd+,`

```json
{
    // Editor
    "font_size": 12,
    "font_face": "JetBrains Mono",
    "line_padding_top": 2,
    "line_padding_bottom": 2,
    "tab_size": 4,
    "translate_tabs_to_spaces": true,
    "trim_trailing_white_space_on_save": true,
    "ensure_newline_at_eof_on_save": true,

    // Visual
    "theme": "Adaptive.sublime-theme",
    "color_scheme": "Mariana.sublime-color-scheme",
    "highlight_line": true,
    "highlight_modified_tabs": true,
    "show_encoding": true,
    "draw_white_space": "selection",

    // Comportamento
    "save_on_focus_lost": true,
    "hot_exit": true,
    "remember_open_files": true,
    "auto_complete_commit_on_tab": true,
    "shift_tab_unindent": true,

    // Performance
    "index_files": true,
    "index_workers": 4
}
```

### Projetos

Sublime Text permite salvar configurações por projeto:

**Criar um projeto:**

1. Abra uma pasta: `File → Open Folder`
2. Configure o projeto: `Project → Edit Project`
3. Salve o projeto: `Project → Save Project As`

**Exemplo de configuração de projeto:**

```json
{
    "folders": [
        {
            "path": ".",
            "folder_exclude_patterns": [
                "node_modules",
                "__pycache__",
                ".git",
                "dist",
                "build"
            ],
            "file_exclude_patterns": [
                "*.pyc",
                "*.log",
                ".DS_Store"
            ]
        }
    ],
    "settings": {
        "tab_size": 2,
        "translate_tabs_to_spaces": true
    }
}
```

### Build Systems

Configure build systems para compilar/executar código diretamente:

**Python Build (Tools → Build System → New Build System):**

```json
{
    "cmd": ["python3", "-u", "$file"],
    "file_regex": "^[ ]*File \"(...*?)\", line ([0-9]*)",
    "selector": "source.python",
    "env": {"PYTHONIOENCODING": "utf-8"}
}
```

**Node.js Build:**

```json
{
    "cmd": ["node", "$file"],
    "selector": "source.js",
    "shell": true
}
```

Execute com: `Ctrl/Cmd+B`

### Snippets Personalizados

Crie snippets reutilizáveis: `Tools → Developer → New Snippet`

**Exemplo de snippet:**

```xml
<snippet>
    <content><![CDATA[
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

def ${1:function_name}($2):
    """${3:Description}"""
    ${4:pass}
]]></content>
    <tabTrigger>pydef</tabTrigger>
    <scope>source.python</scope>
    <description>Python function template</description>
</snippet>
```

Salve como `python-function.sublime-snippet` e use digitando `pydef` + Tab.

## Recursos Avançados

### Goto Definition

Com o plugin LSP instalado, você pode:

```
F12 ou Ctrl/Cmd+Click  - Ir para definição
Ctrl/Cmd+Shift+[       - Voltar
Ctrl/Cmd+Shift+]       - Avançar
```

### Macros

Grave sequências de comandos:

1. `Tools → Record Macro`
2. Execute suas ações
3. `Tools → Stop Recording Macro`
4. `Tools → Save Macro`
5. Atribua um atalho em `Preferences → Key Bindings`

### Vintage Mode (Vim)

Habilite modo Vim nas configurações:

```json
{
    "ignored_packages": []  // Remova "Vintage" da lista
}
```

### Integração com Terminal

Adicione o comando `subl` ao PATH:

**macOS:**

```bash
# Já configurado automaticamente
subl .
```

**Linux:**

```bash
# Já configurado durante instalação
subl .
```

### Git Integration

Com GitGutter instalado:

- Veja modificações na gutter (lado esquerdo)
- Navegue entre mudanças: `Ctrl/Cmd+Shift+Alt+Up/Down`
- Reverta hunks: Command Palette → "GitGutter: Revert"

## Troubleshooting

### Sublime Text não abre

```bash
# Verificar se está instalado
which subl
subl --version

# Reinstalar se necessário
susa setup sublime-text --uninstall
susa setup sublime-text
```

### Package Control não funciona

```bash
# Remover e reinstalar
rm -rf ~/.config/sublime-text/Installed\ Packages/Package\ Control.sublime-package
# Abra Sublime Text e reinstale via Command Palette
```

### Licença

Sublime Text é um software comercial mas pode ser avaliado gratuitamente. Para remover o popup de avaliação, adquira uma licença em:

<https://www.sublimetext.com/buy>

## Dicas de Produtividade

1. **Use Goto Anything** (`Ctrl/Cmd+P`) para tudo - é mais rápido que usar o mouse
2. **Aprenda múltiplos cursores** - economiza muito tempo em edições repetitivas
3. **Configure snippets** para código que você escreve frequentemente
4. **Use projetos** para cada workspace - mantém configurações separadas
5. **Explore o Command Palette** - descubra funcionalidades escondidas
6. **Customize atalhos** em `Preferences → Key Bindings` para seu workflow
7. **Use Split View** (`Alt+Shift+2/3/4/5`) para ver múltiplos arquivos
8. **Configure build systems** para compilar/testar sem sair do editor

## Recursos Adicionais

- **Documentação oficial**: <https://www.sublimetext.com/docs/>
- **Package Control**: <https://packagecontrol.io/>
- **Forum**: <https://forum.sublimetext.com/>
- **Discord**: Comunidade ativa no Discord oficial
- **Plugins populares**: <https://packagecontrol.io/browse/popular>

## Variáveis de Ambiente

O comando usa as seguintes variáveis configuráveis em `command.json`:

```json
{
  "SUBLIME_HOMEBREW_CASK": "sublime-text",
  "SUBLIME_APT_KEY_URL": "https://download.sublimetext.com/sublimehq-pub.gpg",
  "SUBLIME_APT_REPO": "https://download.sublimetext.com/",
  "SUBLIME_RPM_KEY_URL": "https://download.sublimetext.com/sublimehq-rpm-pub.gpg",
  "SUBLIME_RPM_REPO_URL": "https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo"
}
```

Essas variáveis permitem customizar URLs e repositórios se necessário.

## Sistemas Operacionais Suportados

- ✅ **macOS**: Via Homebrew Cask
- ✅ **Linux - Debian/Ubuntu**: Via repositório apt oficial
- ✅ **Linux - Fedora/RHEL/CentOS**: Via repositório RPM oficial
- ✅ **Linux - Arch/Manjaro**: Via AUR (sublime-text-4)
- ❌ **Windows**: Não suportado por este comando

## Exemplos Práticos

### Workflow Completo

```bash
# 1. Instalar Sublime Text
susa setup sublime-text

# 2. Abrir um projeto
subl ~/meu-projeto

# 3. Instalar Package Control
# Ctrl/Cmd+Shift+P → Install Package Control

# 4. Instalar plugins essenciais
# Ctrl/Cmd+Shift+P → Package Control: Install Package
# → LSP, GitGutter, BracketHighlighter

# 5. Configurar para Python
# Instalar: LSP-pyright, Python Improved
# Configurar: .sublime-project

# 6. Começar a codar!
```

### Edição Rápida de Múltiplos Arquivos

```bash
# Buscar e substituir em todos os arquivos
# 1. Ctrl/Cmd+Shift+F
# 2. Digite o padrão de busca
# 3. Digite o texto de substituição
# 4. Preview → Replace All
```

### Criar Comando Personalizado

Adicione em `Preferences → Key Bindings`:

```json
[
    {
        "keys": ["ctrl+shift+c"],
        "command": "toggle_comment",
        "args": { "block": false }
    },
    {
        "keys": ["ctrl+shift+d"],
        "command": "duplicate_line"
    }
]
```

## Próximos Passos

Depois de instalar o Sublime Text:

1. ✅ Instale o Package Control
2. ✅ Configure o tema e color scheme favoritos
3. ✅ Instale plugins para suas linguagens principais
4. ✅ Configure atalhos personalizados
5. ✅ Crie snippets para código repetitivo
6. ✅ Explore o Command Palette (`Ctrl/Cmd+Shift+P`)
7. ✅ Leia a documentação oficial
8. ✅ Considere adquirir uma licença se usar profissionalmente
