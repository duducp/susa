# snap.sh

Biblioteca para gerenciamento de aplicativos via Snap.

## O que faz?

Fornece funções para instalar, atualizar, remover e consultar aplicativos distribuídos via Snap no Snap Store. A biblioteca cuida automaticamente da verificação de disponibilidade do Snap, atualização de metadados e gerenciamento de instalações.

**Importante:** Diferente do Flatpak, operações Snap requerem privilégios de administrador (`sudo`).

## Como usar

```bash
source "$LIB_DIR/snap.sh"
```

## Funções

### snap_is_available

Verifica se Snap está instalado no sistema.

**Retorno:**

- `0` - Snap está disponível
- `1` - Snap não está instalado

**Exemplo:**

```bash
if snap_is_available; then
    log_info "Snap está disponível"
fi
```

### snap_refresh_metadata

Atualiza os metadados do Snap Store.

Útil para garantir que as informações mais recentes de versões estão disponíveis antes de consultar ou instalar aplicativos.

**Retorno:**

- `0` - Sempre (atualização não é crítica)

**Exemplo:**

```bash
snap_refresh_metadata
```

### snap_is_installed

Verifica se um aplicativo está instalado.

**Parâmetros:**

- `$1` - Nome do aplicativo (ex: `podman-desktop`)

**Retorno:**

- `0` - Aplicativo está instalado
- `1` - Aplicativo não está instalado

**Exemplo:**

```bash
if snap_is_installed "podman-desktop"; then
    log_info "Podman Desktop está instalado"
fi
```

### snap_get_installed_version

Obtém a versão instalada de um aplicativo.

**Parâmetros:**

- `$1` - Nome do aplicativo

**Saída:**

- Versão instalada ou `"unknown"` se não instalado

**Retorno:**

- `0` - Sempre

**Exemplo:**

```bash
version=$(snap_get_installed_version "podman-desktop")
log_info "Versão instalada: $version"
```

### snap_get_latest_version

Obtém a versão mais recente disponível no Snap Store.

**Parâmetros:**

- `$1` - Nome do aplicativo

**Saída:**

- Versão mais recente ou `"unknown"` se não encontrado

**Retorno:**

- `0` - Versão foi encontrada
- `1` - Erro ao obter versão

**Exemplo:**

```bash
latest=$(snap_get_latest_version "podman-desktop")
if [ $? -eq 0 ]; then
    log_info "Versão mais recente: $latest"
fi
```

### snap_install

Instala um aplicativo do Snap Store.

Cuida automaticamente da verificação de disponibilidade do Snap e atualização de metadados. **Requer sudo.**

**Parâmetros:**

- `$1` - Nome do aplicativo
- `$2` - (Opcional) Nome amigável para logs (padrão: usar nome)
- `$3` - (Opcional) Canal (padrão: `stable`)
- `$4` - (Opcional) Modo classic (`true`/`false`, padrão: `false`)

**Retorno:**

- `0` - Instalação bem-sucedida
- `1` - Erro na instalação

**Exemplo:**

```bash
# Instalação padrão (canal stable)
if snap_install "podman-desktop" "Podman Desktop"; then
    log_success "Instalado com sucesso!"
fi

# Instalação com modo classic (requerido por alguns apps)
snap_install "code" "VS Code" "stable" "true"

# Instalação de canal específico
snap_install "docker" "Docker" "edge"
```

### snap_update

Atualiza um aplicativo instalado.

**Requer sudo.**

**Parâmetros:**

- `$1` - Nome do aplicativo
- `$2` - (Opcional) Nome amigável para logs (padrão: usar nome)
- `$3` - (Opcional) Canal (padrão: `stable`)

**Retorno:**

- `0` - Atualização bem-sucedida ou já atualizado
- `1` - Erro na atualização

**Exemplo:**

```bash
if snap_update "podman-desktop" "Podman Desktop"; then
    log_success "Atualizado com sucesso!"
fi

# Atualizar para canal específico
snap_update "docker" "Docker" "edge"
```

### snap_uninstall

Remove um aplicativo instalado.

**Requer sudo.**

**Parâmetros:**

- `$1` - Nome do aplicativo
- `$2` - (Opcional) Nome amigável para logs (padrão: usar nome)

**Retorno:**

- `0` - Remoção bem-sucedida ou app não estava instalado
- `1` - Erro na remoção

**Exemplo:**

```bash
if snap_uninstall "podman-desktop" "Podman Desktop"; then
    log_success "Removido com sucesso!"
fi
```

### snap_info

Obtém informações detalhadas sobre um pacote Snap.

**Parâmetros:**

- `$1` - Nome do aplicativo

**Saída:**

- Informações detalhadas do `snap info`

**Retorno:**

- `0` - Informações obtidas com sucesso
- `1` - Erro ao obter informações

**Exemplo:**

```bash
snap_info "podman-desktop"
```

### snap_list_installed

Lista todos os pacotes Snap instalados.

**Saída:**

- Lista de pacotes instalados com versões

**Retorno:**

- `0` - Lista obtida com sucesso
- `1` - Erro ao obter lista

**Exemplo:**

```bash
snap_list_installed
```

## Canais do Snap

O Snap usa um sistema de canais para distribuição de versões:

| Canal | Descrição |
|-------|-----------|
| `stable` | Versão estável (padrão) |
| `candidate` | Versão candidata a estável |
| `beta` | Versão beta |
| `edge` | Versão de desenvolvimento |

**Exemplo:**

```bash
# Instalar versão estável (padrão)
snap_install "docker" "Docker"

# Instalar versão edge (desenvolvimento)
snap_install "docker" "Docker" "edge"
```

## Modo Classic

Alguns snaps requerem confinamento clássico (`--classic`) para acesso total ao sistema.

**Exemplos de apps que requerem classic:**

- VS Code (`code`)
- Alguns IDEs e ferramentas de desenvolvimento

```bash
# Instalar com modo classic
snap_install "code" "VS Code" "stable" "true"
```

## Exemplo Completo

```bash
#!/usr/bin/env zsh
set -euo pipefail
IFS=$'\n\t'

source "$LIB_DIR/snap.sh"

APP_NAME="podman-desktop"
FRIENDLY_NAME="Podman Desktop"

# Verificar se Snap está disponível
if ! snap_is_available; then
    log_error "Snap não está instalado"
    exit 1
fi

# Verificar se está instalado
if snap_is_installed "$APP_NAME"; then
    version=$(snap_get_installed_version "$APP_NAME")
    log_info "$FRIENDLY_NAME $version já está instalado"

    # Atualizar
    snap_update "$APP_NAME" "$FRIENDLY_NAME"
else
    # Instalar
    snap_install "$APP_NAME" "$FRIENDLY_NAME"
fi

# Verificar versão mais recente
latest=$(snap_get_latest_version "$APP_NAME")
log_info "Versão disponível no Snap Store: $latest"
```

## Diferenças entre Snap e Flatpak

| Aspecto | Snap | Flatpak |
|---------|------|---------|
| **Permissões** | Requer `sudo` | Instalação com `--user` |
| **Identificador** | Nome simples (`docker`) | ID reverso (`org.docker.Docker`) |
| **Canais** | stable/beta/edge/candidate | Branches do repositório |
| **Confinamento** | Classic/strict | Sandbox |
| **Repositório** | Snap Store (Canonical) | Flathub (Freedesktop) |

## Notas

- **Requer sudo:** Todas as operações de instalação/atualização/remoção requerem privilégios de administrador
- Logs são gerados usando funções de `logger.sh`
- Versões retornam `"unknown"` em caso de erro
- O canal padrão é `stable`
- Alguns pacotes requerem modo `--classic` para funcionar

## Veja também

- [flatpak.sh](flatpak.md) - Gerenciamento via Flatpak
- [github.sh](github.md) - Download de releases do GitHub
- [installations.sh](installations.md) - Registro de instalações no lock file
