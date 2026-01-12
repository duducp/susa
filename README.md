# Susa CLI

Sistema modular de CLI em Shell Script para automação de tarefas e gerenciamento de ferramentas no Linux e macOS.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## ✨ Características

- 🔍 **Discovery Automático** - Comandos descobertos da estrutura de diretórios
- 📦 **Sistema de Plugins** - Extensão via repositórios Git
- 🎯 **Subcategorias Multi-nível** - Navegação hierárquica ilimitada
- 🖥️ **Multi-plataforma** - Suporte para Linux (Debian, Fedora) e macOS
- 📚 **12 Bibliotecas Úteis** - Logger, detecção de SO, gerenciamento de dependências
- 🎨 **Interface Rica** - Logs coloridos, agrupamento visual, help customizado
- ⚙️ **Parser YAML Robusto** - yq v4+ com instalação automática

## 🚀 Instalação Rápida

### Instalação

```bash
# macOS e Linux
curl -LsSf https://raw.githubusercontent.com/carlosdorneles-mb/susa/main/install-remote.sh | sh
```

## 📖 Uso Básico

```bash
# Listar categorias
susa

# Listar comandos de uma categoria
susa setup

# Executar comando
susa setup docker

# Navegar subcategorias
susa setup python tools pip

# Help de comando
susa setup docker --help

# Versão do Susa CLI
susa --version
```

## 📁 Estrutura

```text
susa/
├── susa                     # Executável principal
├── cli.yaml                 # Configuração global
├── install.sh               # Instalador local
├── install-remote.sh        # Instalador remoto (curl | sh)
├── uninstall.sh            # Desinstalador
├── Makefile                 # Automação
│
├── commands/                # Comandos nativos
│   ├── setup/
│   │   ├── config.yaml     # Config da categoria
│   │   ├── docker/
│   │   │   ├── config.yaml # Config do comando
│   │   │   └── main.sh     # Script executável
│   │   └── python/         # Subcategoria
│   │       └── tools/      # Sub-subcategoria
│   └── self/               # Comandos do próprio CLI
│       ├── version/
│       └── plugin/
│
├── plugins/                 # Plugins externos (Git)
│   └── registry.yaml       # Registry de plugins
│
├── lib/                     # 12 bibliotecas compartilhadas
│   ├── yaml.sh             # Parser YAML (yq)
│   ├── dependencies.sh     # Gestão de dependências
│   ├── logger.sh           # Sistema de logs
│   ├── color.sh            # Cores ANSI
│   ├── os.sh               # Detecção de SO
│   ├── sudo.sh             # Gestão sudo
│   ├── string.sh           # Manipulação strings
│   ├── shell.sh            # Detecção shell
│   ├── kubernetes.sh       # Funções K8s
│   ├── plugin.sh           # Gestão plugins
│   ├── registry.sh         # Gestão registry
│   ├── cli.sh              # Funções CLI
│   └── utils.sh            # Agregador
│
├── config/                  # Configurações opcionais
│   └── settings.conf
│
└── docs/                    # Documentação MkDocs
    ├── index.md
    ├── quick-start.md
    ├── guides/
    ├── plugins/
    ├── reference/
    └── about/
```

## 🎯 Principais Funcionalidades

### Discovery Automático

Comandos são descobertos automaticamente da estrutura de diretórios. Adicione uma pasta em `commands/` com `config.yaml` e pronto!

### Sistema de Plugins

Estenda o Susa CLI sem modificar o código principal:

```bash
susa self plugin install user/repo
susa self plugin list
```

### Subcategorias Multi-nível

Organize comandos em hierarquias:

```bash
susa setup python tools pip
#   └─┬─┘ └──┬──┘ └─┬─┘ └┬┘
#  cat  subcat1  subcat2 cmd
```

### Bibliotecas Reutilizáveis

12 bibliotecas prontas para uso em seus comandos:

- **logger.sh** - Logs com níveis e timestamps
- **os.sh** - Detecção de sistema operacional
- **dependencies.sh** - Instalação automática de deps
- **yaml.sh** - Parser YAML com yq
- E mais 8 bibliotecas úteis!

## 🛠️ Desenvolvimento

### Adicionar Novo Comando

```bash
# 1. Criar estrutura
mkdir -p commands/setup/meuapp

# 2. Criar config.yaml
cat > commands/setup/meuapp/config.yaml << EOF
name: "Meu App"
description: "Instala Meu App"
script: "main.sh"
sudo: false
os: ["linux", "mac"]
EOF

# 3. Criar script
cat > commands/setup/meuapp/main.sh << 'EOF'
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUSA_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$SUSA_DIR/lib/logger.sh"

log_info "Instalando Meu App..."
# Sua lógica aqui
log_success "Instalado com sucesso!"
EOF

# 4. Dar permissão
chmod +x commands/setup/meuapp/main.sh

# 5. Testar
susa setup meuapp
```

Pronto! O comando aparece automaticamente.

## 📚 Documentação

- **[Documentação Completa](https://cdorneles.github.io/scripts/)** - GitHub Pages
- **[Quick Start](docs/quick-start.md)** - Instalação e primeiros passos
- **[Guia de Funcionalidades](docs/guides/features.md)** - Recursos completos
- **[Adicionar Comandos](docs/guides/adding-commands.md)** - Passo-a-passo
- **[Referência de Bibliotecas](docs/reference/libraries.md)** - API das libs
- **[Sistema de Plugins](docs/plugins/overview.md)** - Extensão via Git

## 🤝 Contribuindo

Contribuições são bem-vindas! Veja [CONTRIBUTING.md](docs/about/contributing.md) para detalhes.

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja [LICENSE](docs/about/license.md) para detalhes.

---

## 💡 Exemplos de Uso

### Gerenciar Plugins

```bash
# Instalar plugin
susa self plugin install cdorneles/devops-tools

# Listar plugins
susa self plugin list

# Atualizar plugin
susa self plugin update devops-tools

# Remover plugin
susa self plugin remove devops-tools
```

### Comandos do Sistema

```bash
# Instalar ferramentas
susa setup docker
susa setup nodejs
susa setup python

# Atualizar sistema
susa update system
```

### Desenvolvimento Local

```bash
# Instalar Susa CLI localmente
make cli-install

# Desinstalar
make cli-uninstall

# Testar
make test

# Servir documentação
make serve
```

---

**Feito com ❤️ por [Carlos Dorneles](https://github.com/cdorneles)**
