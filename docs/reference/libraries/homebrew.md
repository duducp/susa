# homebrew.sh

Biblioteca para gerenciamento de aplicativos via Homebrew.

## O que faz?

Fornece funções para instalar, atualizar, remover e consultar aplicativos (casks) distribuídos via Homebrew no macOS. A biblioteca simplifica o gerenciamento de instalações através de uma interface consistente e padronizada.

Todas as operações trabalham com casks do Homebrew, ideais para aplicativos com interface gráfica.

## Como usar

```bash
source "$LIB_DIR/homebrew.sh"
```

## Funções

### homebrew_is_available

Verifica se Homebrew está instalado no sistema.

**Retorno:**

- `0` - Homebrew está disponível
- `1` - Homebrew não está instalado

**Exemplo:**

```bash
if homebrew_is_available; then
    log_info "Homebrew está disponível"
fi
```

### homebrew_update_metadata

Atualiza os formulae do Homebrew.

Útil para garantir que as informações mais recentes de versões estão disponíveis antes de consultar ou instalar aplicativos.

**Retorno:**

- `0` - Atualização bem-sucedida
- `1` - Erro na atualização

**Exemplo:**

```bash
homebrew_update_metadata
```

### homebrew_is_installed

Verifica se um cask está instalado.

**Parâmetros:**

- `$1` - Nome do cask (ex: `visual-studio-code`)

**Retorno:**

- `0` - Cask está instalado
- `1` - Cask não está instalado

**Exemplo:**

```bash
if homebrew_is_installed "visual-studio-code"; then
    log_info "VS Code está instalado"
fi
```

### homebrew_get_installed_version

Obtém a versão instalada de um cask.

**Parâmetros:**

- `$1` - Nome do cask

**Saída:**

- Versão instalada ou `"unknown"` se não instalado

**Retorno:**

- `0` - Sempre

**Exemplo:**

```bash
version=$(homebrew_get_installed_version "visual-studio-code")
log_info "Versão instalada: $version"
```

### homebrew_get_latest_version

Obtém a versão mais recente disponível no Homebrew.

**Parâmetros:**

- `$1` - Nome do cask

**Saída:**

- Versão mais recente ou `"unknown"` se não encontrado

**Retorno:**

- `0` - Versão foi encontrada
- `1` - Erro ao obter versão

**Exemplo:**

```bash
latest=$(homebrew_get_latest_version "visual-studio-code")
if [ $? -eq 0 ]; then
    log_info "Versão mais recente: $latest"
fi
```

### homebrew_install

Instala um cask do Homebrew.

Verifica se Homebrew está instalado e se o cask já não está presente antes de instalar.

**Parâmetros:**

- `$1` - Nome do cask
- `$2` - (Opcional) Nome amigável para logs (padrão: usar nome do cask)

**Retorno:**

- `0` - Instalação bem-sucedida
- `1` - Erro na instalação

**Exemplo:**

```bash
if homebrew_install "visual-studio-code" "VS Code"; then
    log_success "Instalado com sucesso!"
fi
```

### homebrew_update

Atualiza um cask instalado.

**Parâmetros:**

- `$1` - Nome do cask
- `$2` - (Opcional) Nome amigável para logs (padrão: usar nome do cask)

**Retorno:**

- `0` - Atualização bem-sucedida ou já atualizado
- `1` - Erro na atualização

**Exemplo:**

```bash
if homebrew_update "visual-studio-code" "VS Code"; then
    log_success "Atualizado com sucesso!"
fi
```

### homebrew_uninstall

Remove um cask instalado.

**Parâmetros:**

- `$1` - Nome do cask
- `$2` - (Opcional) Nome amigável para logs (padrão: usar nome do cask)

**Retorno:**

- `0` - Remoção bem-sucedida ou cask não estava instalado
- `1` - Erro na remoção

**Exemplo:**

```bash
if homebrew_uninstall "visual-studio-code" "VS Code"; then
    log_success "Removido com sucesso!"
fi
```

## Exemplo Completo

```bash
#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

source "$LIB_DIR/homebrew.sh"

CASK_NAME="dbeaver-community"
APP_NAME="DBeaver"

# Verificar se está instalado
if homebrew_is_installed "$CASK_NAME"; then
    version=$(homebrew_get_installed_version "$CASK_NAME")
    log_info "$APP_NAME $version já está instalado"

    # Atualizar
    homebrew_update "$CASK_NAME" "$APP_NAME"
else
    # Instalar
    homebrew_install "$CASK_NAME" "$APP_NAME"
fi

# Verificar versão mais recente
latest=$(homebrew_get_latest_version "$CASK_NAME")
log_info "Versão disponível no Homebrew: $latest"
```

## Notas

- Trabalha exclusivamente com casks (aplicativos gráficos)
- Exibe mensagem de erro com instruções se Homebrew não estiver instalado
- Logs são gerados usando funções de `logger.sh`
- Versões retornam `"unknown"` em caso de erro
- Gerencia automaticamente casks que já estão na versão mais recente

## Diferenças entre Formula e Cask

- **Formula:** Pacotes de linha de comando (`brew install`)
- **Cask:** Aplicativos gráficos (`brew install --cask`) - usado por esta biblioteca

## Veja também

- [flatpak.sh](flatpak.md) - Gerenciamento via Flatpak (Linux)
- [github.sh](github.md) - Download de releases do GitHub
- [installations.sh](installations.md) - Registro de instalações no lock file
