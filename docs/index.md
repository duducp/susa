---
icon: material/home
---

# Susa CLI

Sistema modular de CLI em Shell Script para automação de tarefas e gerenciamento de software.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)
![Shell](https://img.shields.io/badge/shell-zsh-orange)
![Platform](https://img.shields.io/badge/platform-linux%20%7C%20macos-lightgrey)

## ✨ Características

- 🔍 **Discovery Automático** - Comandos descobertos da estrutura de diretórios
- 📦 **Sistema de Plugins** - Extensão via repositórios Git externos
- 🎯 **Subcategorias Multi-nível** - Navegação hierárquica ilimitada
- 🌍 **Variáveis de Ambiente** - Configurações isoladas por comando com expansão automática
- 🖥️ **Multi-plataforma** - Suporte para Linux (Debian, Fedora) e macOS
- 🎨 **Interface Rica** - Logs coloridos, agrupamento visual, help customizado
- ⚙️ **Parser JSON Robusto** - jq com instalação automática
- 🔐 **Gestão de Permissões** - Indicadores e verificação de sudo
- 🌐 **Instalação Remota** - Instale com um único comando curl

## 🚀 Instalação

### Linux and macOS

Use `curl` ou `wget` para baixar e executar o script:

```bash
# Com curl (bash ou zsh)
curl -LsSf https://raw.githubusercontent.com/duducp/susa/main/install.sh | bash

# Com wget (bash ou zsh)
wget -qO- https://raw.githubusercontent.com/duducp/susa/main/install.sh | bash
```

> **ℹ️ Nota:** O script funciona com `bash` ou `zsh`. O ZSH será instalado automaticamente se necessário.

Para instruções completas de instalação, desinstalação e verificação, veja o [Guia de Início Rápido](quick-start.md).

## 📖 Uso Básico

```bash
# Listar categorias
susa

# Executar comando
susa setup docker      # Instalar Docker
susa setup poetry      # Instalar Poetry

# Gerenciar plugins
susa self plugin add user/repo
susa self plugin list

# Autocompletar
susa self completion --install

# Ver informações
susa self info
susa self version
```

Para exemplos detalhados e tutoriais práticos, veja o [Guia de Início Rápido](quick-start.md).

## 📖 Estrutura do Projeto

```text
cli/
├── core/                 # Core do CLI
│   ├── susa             # Entrypoint principal
│   ├── cli.json         # Configuração global
│   └── lib/             # Bibliotecas
│       ├── cache.sh     # Sistema de cache
│       ├── cli.sh       # Funções CLI
│       ├── color.sh     # Cores e formatação
│       ├── context.sh   # Contexto de execução
│       ├── github.sh    # Integração GitHub
│       ├── logger.sh    # Sistema de logs
│       ├── os.sh        # Detecção de SO
│       └── internal/    # Bibliotecas internas
│           ├── lock.sh           # Cache do susa.lock
│           ├── registry.sh       # Gestão de plugins
│           └── installations.sh  # Gestão de instalações
│
├── install.sh           # Instalador remoto
├── uninstall.sh         # Desinstalador remoto
│
├── commands/            # Comandos nativos
│   ├── setup/          # Instalação de software
│   │   ├── docker/     # Docker
│   │   ├── podman/     # Podman
│   │   ├── poetry/     # Poetry
│   │   └── ...
│   └── self/           # Gerenciamento do CLI
│       ├── cache/      # Gerenciamento de cache
│       ├── completion/ # Autocompletar
│       ├── info/       # Informações
│       ├── lock/       # Lock file
│       ├── plugin/     # Plugins
│       ├── update/     # Atualizar CLI
│       └── version/    # Versão
│
├── plugins/            # Plugins externos
│   └── registry.json  # Registro de plugins
│
├── config/            # Configurações
│   └── settings.conf
│
└── docs/             # Documentação (MkDocs)
```

## 📚 Documentação

- [Início Rápido](quick-start.md) - Instalação e primeiros passos
- [Configuração](guides/configuration.md) - Configurações globais e variáveis de ambiente
- [Variáveis de Ambiente](guides/envs.md) - Guia completo de variáveis por comando
- [Subcategorias](guides/subcategories.md) - Sistema de navegação multinível
- [Adicionando Comandos](guides/adding-commands.md) - Como criar novos comandos
- [Sistema de Plugins](plugins/overview.md) - Estendendo o Susa CLI
- [Funcionalidades](guides/features.md) - Guia completo de features

## 🔧 Desenvolvimento

### Criar um Comando

Comandos são descobertos automaticamente da estrutura de diretórios:

```bash
mkdir -p commands/setup/docker
# Criar command.json e main.sh
```

Veja o [Guia de Adição de Comandos](guides/adding-commands.md) para instruções completas.

## 🔌 Plugins

Instale plugins externos para adicionar funcionalidades:

```bash
# Instalar plugin
susa self plugin add https://github.com/user/susa-plugin-name

# Listar plugins
susa self plugin list

# Atualizar plugin
susa self plugin update plugin-name

# Remover plugin
susa self plugin remove plugin-name
```

## 🤝 Contribuindo

Contribuições são bem-vindas! Veja o [guia de contribuição](about/contributing.md).

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](about/license.md) para mais detalhes.
