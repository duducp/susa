# Setup iTerm2

Instala o iTerm2, um substituto avançado para o Terminal padrão do macOS, com recursos como split panes, busca avançada, autocompletar e muito mais.

## O que é iTerm2?

iTerm2 é um emulador de terminal moderno para macOS que oferece recursos poderosos para desenvolvedores e usuários avançados:

- **Split Panes**: Divida a janela em múltiplos painéis para trabalhar simultaneamente
- **Busca Avançada**: Pesquise em todo o histórico do terminal instantaneamente
- **Autocompletar**: Complete comandos e caminhos automaticamente
- **Hotkey Window**: Acesse seu terminal com um atalho global
- **Temas e Personalização**: Customize cores, fontes e aparência

**Por exemplo:**

```bash
# Trabalhe com múltiplos painéis ao mesmo tempo:
# ┌─────────────┬─────────────┐
# │  Servidor   │   Logs      │
# ├─────────────┴─────────────┤
# │  Editor de código          │
# └────────────────────────────┘
```

## Como usar

### Instalar

```bash
susa setup iterm
```

O comando vai:

- Verificar se o Homebrew está instalado
- Atualizar o Homebrew
- Instalar o iTerm2 como cask
- Disponibilizar na pasta Aplicativos

Depois de instalar, você encontrará o iTerm2 na pasta Aplicativos. Para configurá-lo como terminal padrão, acesse **Preferências do Sistema > Geral**.

### Atualizar

```bash
susa setup iterm --update
```

Atualiza o iTerm2 para a versão mais recente disponível no Homebrew. Todas as suas configurações e preferências serão preservadas.

### Desinstalar

```bash
susa setup iterm --uninstall
```

Remove o iTerm2 do sistema. Você terá a opção de também remover as configurações e preferências salvas.

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `--update` | Atualiza o iTerm2 para a versão mais recente |
| `--uninstall` | Remove o iTerm2 do sistema |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída, desabilita mensagens de depuração |

## Guia Rápido de Uso

### Atalhos Essenciais

**Gerenciamento de Painéis**

```
⌘D     - Dividir painel verticalmente
⌘⇧D    - Dividir painel horizontalmente
⌘]     - Ir para o próximo painel
⌘[     - Ir para o painel anterior
⌘W     - Fechar painel atual
```

**Navegação e Busca**

```
⌘F     - Buscar no terminal
⌘;     - Autocompletar de comandos
⌘⇧H    - Ver histórico de comandos
⌘K     - Limpar tela
⌥⌘E    - Buscar em todas as abas
```

**Abas e Janelas**

```
⌘T     - Nova aba
⌘N     - Nova janela
⌘1-9   - Alternar entre abas
⌘⇧[/]  - Mover entre abas
```

### Recursos Úteis

**1. Profiles (Perfis)**

Crie perfis diferentes para ambientes específicos:

- Desenvolvimento local
- Servidor de produção
- Testes e staging
- Cada um com suas cores e configurações

**2. Triggers**

Configure ações automáticas quando detectar padrões no output:

```
# Destacar erros em vermelho
Padrão: ERROR|FATAL|FAIL
Ação: Highlight Text com cor vermelha
```

**3. Hotkey Window**

Configure uma janela que aparece/desaparece com um atalho:

1. Preferences → Keys → Hotkey
2. Marque "Show/hide all windows with a system-wide hotkey"
3. Defina: `⌥Space` (Option + Espaço)

**4. Shell Integration**

Habilite a integração com shell para recursos avançados:

```bash
# Para Zsh (adicione ao ~/.zshrc)
source ~/.iterm2_shell_integration.zsh

# Para Bash (adicione ao ~/.bashrc)
source ~/.iterm2_shell_integration.bash
```

Recursos após integração:
- Jump to previous/next command (⌘↑/⌘↓)
- Command history visual
- Download files com drag & drop
- Badges e timestamps

## Temas Populares

O iTerm2 suporta temas customizados. Alguns populares:

| Tema | Estilo | Como baixar |
|------|--------|-------------|
| **Dracula** | Dark, vibrante | [draculatheme.com/iterm](https://draculatheme.com/iterm) |
| **Solarized** | Dark/Light equilibrado | [ethanschoonover.com/solarized](https://ethanschoonover.com/solarized/) |
| **One Dark** | Dark, minimalista | [github.com/one-dark](https://github.com/one-dark/iterm-one-dark-theme) |
| **Nord** | Dark, azul ártico | [nordtheme.com](https://www.nordtheme.com/ports/iterm2) |
| **Monokai** | Dark, colorido | [github.com/mbadolato](https://github.com/mbadolato/iTerm2-Color-Schemes) |

### Importar Tema

1. Baixe o arquivo `.itermcolors`
2. iTerm2 → Preferences → Profiles → Colors
3. Color Presets → Import
4. Selecione o arquivo baixado

## Configurações Recomendadas

### Performance

```
Preferences → Advanced → Terminal
• Disable "Save lines to scrollback in alternate screen mode"
• Enable "Use Metal renderer" para melhor performance
```

### Aparência

```
Preferences → Appearance → General
• Theme: Minimal (para interface limpa)
• Tab bar location: Top
• Status bar location: Bottom

Preferences → Profiles → Text
• Font: Fira Code (com ligatures)
• Font Size: 13-14pt
```

### Comportamento

```
Preferences → Profiles → Terminal
• Scrollback lines: 10000
• Enable "Unlimited scrollback"

Preferences → Profiles → Session
• Enable "Status bar enabled"
• Configure: CPU, Memory, Network, Git branch
```

## Recursos Avançados

### 1. Tmux Integration

O iTerm2 se integra nativamente com tmux:

```bash
# Conectar ao tmux com integração iTerm2
tmux -CC

# Seus panes do tmux viram janelas nativas do iTerm2!
```

### 2. Python API

Automatize o iTerm2 com Python:

```python
#!/usr/bin/env python3
import iterm2

async def main(connection):
    app = await iterm2.async_get_app(connection)
    window = app.current_terminal_window
    await window.async_create_tab()

iterm2.run_until_complete(main)
```

### 3. Smart Selection

Configure seleção inteligente para URLs, emails, caminhos:

```
Preferences → Profiles → Advanced → Smart Selection
• Add Rule: URLs → Open URL
• Add Rule: File paths → Open file
```

## Troubleshooting

### iTerm2 não abre após instalação

```bash
# Verifique se está instalado
brew list --cask iterm2

# Tente abrir via linha de comando
open -a iTerm
```

### Fontes não aparecem corretamente

Instale fontes com suporte a ligatures:

```bash
brew tap homebrew/cask-fonts
brew install --cask font-fira-code
```

### Sincronizar configurações entre Macs

```
Preferences → General → Preferences
• Enable "Load preferences from a custom folder or URL"
• Defina: ~/Dropbox/iTerm2 ou iCloud
```

## Compatibilidade

- **Sistema Operacional**: macOS 10.14 (Mojave) ou superior
- **Instalação**: Via Homebrew Cask
- **Requisitos**: Homebrew instalado no sistema

## Links Úteis

- [Site Oficial](https://iterm2.com/)
- [Documentação](https://iterm2.com/documentation.html)
- [FAQ](https://iterm2.com/faq.html)
- [Temas e Color Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)
- [Shell Integration](https://iterm2.com/documentation-shell-integration.html)
- [Python API](https://iterm2.com/python-api/)

## Próximos Passos

Depois de instalar o iTerm2:

1. ✅ Configure seu tema favorito
2. ✅ Habilite shell integration
3. ✅ Crie perfis para diferentes ambientes
4. ✅ Configure hotkey window
5. ✅ Explore os atalhos de teclado
6. ✅ Personalize a status bar

---

**Dica**: O iTerm2 é extremamente personalizável. Dedique um tempo explorando as preferências para descobrir recursos que melhoram seu fluxo de trabalho! 🚀
