# flatpak.sh

Biblioteca para gerenciamento de aplicativos via Flatpak.

## O que faz?

Fornece funções para instalar, atualizar, remover e consultar aplicativos distribuídos via Flatpak no repositório Flathub. A biblioteca cuida automaticamente da configuração do Flathub, atualização de metadados e gerenciamento de instalações em nível de usuário.

Todas as operações são feitas com `--user`, não requerendo privilégios de administrador.

## Como usar

```bash
source "$LIB_DIR/flatpak.sh"
```

## Funções

### flatpak_is_available

Verifica se Flatpak está instalado no sistema.

**Retorno:**
- `0` - Flatpak está disponível
- `1` - Flatpak não está instalado

**Exemplo:**
```bash
if flatpak_is_available; then
    log_info "Flatpak está disponível"
fi
```

### flatpak_ensure_flathub

Garante que o repositório Flathub está configurado. Adiciona automaticamente se não estiver.

**Retorno:**
- `0` - Flathub está configurado ou foi adicionado com sucesso
- `1` - Erro ao configurar Flathub

**Exemplo:**
```bash
if ! flatpak_ensure_flathub; then
    log_error "Não foi possível configurar o Flathub"
    return 1
fi
```

### flatpak_update_metadata

Atualiza os metadados do repositório Flathub.

Útil para garantir que as informações mais recentes de versões estão disponíveis antes de consultar ou instalar aplicativos.

**Retorno:**
- `0` - Sempre (atualização não é crítica)

**Exemplo:**
```bash
flatpak_update_metadata
```

### flatpak_is_installed

Verifica se um aplicativo está instalado.

**Parâmetros:**
- `$1` - ID do aplicativo (ex: `io.podman_desktop.PodmanDesktop`)

**Retorno:**
- `0` - Aplicativo está instalado
- `1` - Aplicativo não está instalado

**Exemplo:**
```bash
if flatpak_is_installed "io.podman_desktop.PodmanDesktop"; then
    log_info "Podman Desktop está instalado"
fi
```

### flatpak_get_installed_version

Obtém a versão instalada de um aplicativo.

**Parâmetros:**
- `$1` - ID do aplicativo

**Saída:**
- Versão instalada ou `"desconhecida"` se não instalado

**Retorno:**
- `0` - Sempre

**Exemplo:**
```bash
version=$(flatpak_get_installed_version "io.podman_desktop.PodmanDesktop")
log_info "Versão instalada: $version"
```

### flatpak_get_latest_version

Obtém a versão mais recente disponível no Flathub.

**Parâmetros:**
- `$1` - ID do aplicativo

**Saída:**
- Versão mais recente ou `"desconhecida"` se não encontrado

**Retorno:**
- `0` - Versão foi encontrada
- `1` - Erro ao obter versão

**Exemplo:**
```bash
latest=$(flatpak_get_latest_version "io.podman_desktop.PodmanDesktop")
if [ $? -eq 0 ]; then
    log_info "Versão mais recente: $latest"
fi
```

### flatpak_install

Instala um aplicativo do Flathub.

Cuida automaticamente da configuração do Flathub e atualização de metadados.

**Parâmetros:**
- `$1` - ID do aplicativo
- `$2` - (Opcional) Nome amigável para logs (padrão: usar ID)

**Retorno:**
- `0` - Instalação bem-sucedida
- `1` - Erro na instalação

**Exemplo:**
```bash
if flatpak_install "io.podman_desktop.PodmanDesktop" "Podman Desktop"; then
    log_success "Instalado com sucesso!"
fi
```

### flatpak_update

Atualiza um aplicativo instalado.

**Parâmetros:**
- `$1` - ID do aplicativo
- `$2` - (Opcional) Nome amigável para logs (padrão: usar ID)

**Retorno:**
- `0` - Atualização bem-sucedida ou já atualizado
- `1` - Erro na atualização

**Exemplo:**
```bash
if flatpak_update "io.podman_desktop.PodmanDesktop" "Podman Desktop"; then
    log_success "Atualizado com sucesso!"
fi
```

### flatpak_uninstall

Remove um aplicativo instalado.

**Parâmetros:**
- `$1` - ID do aplicativo
- `$2` - (Opcional) Nome amigável para logs (padrão: usar ID)

**Retorno:**
- `0` - Remoção bem-sucedida ou app não estava instalado
- `1` - Erro na remoção

**Exemplo:**
```bash
if flatpak_uninstall "io.podman_desktop.PodmanDesktop" "Podman Desktop"; then
    log_success "Removido com sucesso!"
fi
```

## Exemplo Completo

```bash
#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

source "$LIB_DIR/flatpak.sh"

APP_ID="io.podman_desktop.PodmanDesktop"
APP_NAME="Podman Desktop"

# Verificar se está instalado
if flatpak_is_installed "$APP_ID"; then
    version=$(flatpak_get_installed_version "$APP_ID")
    log_info "$APP_NAME $version já está instalado"

    # Atualizar
    flatpak_update "$APP_ID" "$APP_NAME"
else
    # Instalar
    flatpak_install "$APP_ID" "$APP_NAME"
fi

# Verificar versão mais recente
latest=$(flatpak_get_latest_version "$APP_ID")
log_info "Versão disponível no Flathub: $latest"
```

## Notas

- Todas as operações usam `--user` (instalação em nível de usuário)
- Não requer privilégios de administrador
- O Flathub é configurado automaticamente se necessário
- Logs são gerados usando funções de `logger.sh`
- Versões retornam `"desconhecida"` em caso de erro

## Veja também

- [github.sh](github.md) - Download de releases do GitHub
- [installations.sh](installations.md) - Registro de instalações no lock file
