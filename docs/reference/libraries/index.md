# 📚 Referência de Bibliotecas

Esta seção documenta todas as bibliotecas disponíveis em `lib/` e suas funções públicas.

## Visão Geral

O Susa CLI fornece um conjunto robusto de bibliotecas reutilizáveis que facilitam o desenvolvimento de comandos. As bibliotecas estão organizadas por funcionalidade e podem ser importadas conforme necessário.

## Bibliotecas Disponíveis

### Interface e Output

#### [color.sh](color.md)

Constantes de cores e estilos para formatação de texto no terminal. Define variáveis como `RED`, `GREEN`, `BOLD`, `NC` para estilização de mensagens.

#### [logger.sh](logger.md)

Sistema de logs estruturado com níveis diferentes (info, success, warning, error, debug) e timestamps automáticos. Essencial para feedback consistente ao usuário.

### Sistema e Ambiente

#### [os.sh](os.md)

Detecção de sistema operacional e distribuições Linux. Fornece a variável `OS_TYPE` e a função `get_simple_os()` para comandos multiplataforma.

#### [shell.sh](shell.md)

Detecção e configuração de shells (bash, zsh, fish). Identifica o shell do usuário e seus arquivos de configuração para instalação automática.

#### [sudo.sh](sudo.md)

Gerenciamento de privilégios de superusuário. Verifica e solicita permissões sudo quando necessário para comandos que requerem elevação.

### Utilitários

#### [string.sh](string.md)

Manipulação de strings e arrays. Inclui funções para conversão de case, limpeza de espaços e parsing de listas separadas por vírgula.

#### [dependencies.sh](dependencies.md)

Gerenciamento automático de dependências externas. Auto-instala ferramentas como `curl`, `jq`, `yq` e `fzf` quando necessário.

#### [kubernetes.sh](kubernetes.md)

Funções auxiliares para trabalhar com Kubernetes. Valida instalação do `kubectl`, verifica namespaces e contextos.

### CLI Core

#### [cli.sh](cli.md)

Funções específicas do framework CLI. Configura ambiente de comandos, exibe versão, uso e descrições formatadas.

#### [args.sh](args.md)

Parsing consistente de argumentos de linha de comando. Valida argumentos obrigatórios, processa flags e elimina código duplicado.

#### [completion.sh](completion.md)

Gerenciamento de autocompletar (tab completion) para Bash e Zsh. Verifica instalação, status e carregamento de scripts de completion.

#### [yaml.sh](yaml.md)

Parser YAML completo para configurações. Descobre categorias, comandos e lê metadados dos arquivos `config.yaml`.

#### [plugin.sh](plugin.md)

Gerenciamento de plugins externos. Clona, detecta versões e conta comandos de plugins Git.

#### [registry.sh](registry.md)

Gerenciamento do arquivo `registry.yaml` de plugins. Adiciona, remove e lista plugins instalados com versionamento.

## Dependências Entre Bibliotecas

```text
cli.sh
├── color.sh
├── args.sh
└── yaml.sh

args.sh
└── logger.sh
    └── color.sh

completion.sh
└── shell.sh

yaml.sh
├── dependencies.sh
└── registry.sh

dependencies.sh
└── logger.sh
    └── color.sh

sudo.sh
└── color.sh

kubernetes.sh
└── color.sh
```

**Nota:** Sempre faça `source` das dependências antes de usar uma biblioteca.

## Padrão de Uso

### Estrutura Típica de um Comando

```bash
#!/bin/bash
set -euo pipefail

# Setup environment
setup_command_env

# Importa bibliotecas necessárias
source "$LIB_DIR/logger.sh"
source "$LIB_DIR/color.sh"
source "$LIB_DIR/os.sh"
source "$LIB_DIR/internal/args.sh"

# Help function
show_help() {
    echo "Uso: susa comando [opções]"
    echo "Descrição do comando"
}

# Parse argumentos
parse_simple_help_only "$@"

# Lógica do comando
log_info "Iniciando..."

simple_os=$(get_simple_os)

case "$simple_os" in
    mac)
        log_info "Instalando para macOS..."
        ;;
    linux)
        log_info "Instalando para Linux..."
        ;;
esac

log_success "Concluído!"
```

## Boas Práticas

1. **Sempre use `set -euo pipefail`** no início dos scripts para tratamento robusto de erros
2. **Importe apenas o necessário** para reduzir overhead e melhorar performance
3. **Use `log_*` ao invés de `echo`** para mensagens consistentes com níveis e timestamps
4. **Detecte SO antes de comandos específicos** usando `get_simple_os()` para compatibilidade
5. **Valide dependências cedo** com `ensure_*_installed` antes de usar ferramentas externas
6. **Use cores para destacar** informações importantes e melhorar UX
7. **Teste compatibilidade de SO** com `is_command_compatible()` antes de executar
8. **Use yq para YAML** ao invés de awk/grep para parsing confiável
9. **Sempre termine cores com `${NC}`** para evitar poluição de estilo no terminal
10. **Configure ambiente com `setup_command_env`** no início para acesso a variáveis padrão

## Recursos Adicionais

- [Guia de Adicionar Comandos](../../guides/adding-commands.md) - Como criar comandos usando as bibliotecas
- [Sistema de Plugins](../../plugins/overview.md) - Como plugins reutilizam bibliotecas
- [Guia de Subcategorias](../../guides/subcategories.md) - Navegação hierárquica de comandos
- [Funcionalidades](../../guides/features.md) - Visão geral completa do sistema
