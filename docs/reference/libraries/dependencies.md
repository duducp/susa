# dependencies.sh

Gerenciamento automático de dependências externas.

## Funções

### `ensure_curl_installed()`

Garante que curl está instalado, tentando instalar automaticamente se necessário.

**Retorno:**

- `0` - curl disponível
- `1` - Falha na instalação

**Suporte:**

- Debian/Ubuntu: `apt-get install curl`
- Fedora/RHEL: `dnf/yum install curl`
- macOS: `brew install curl`

**Uso:**

```bash
ensure_curl_installed || exit 1
curl -O https://example.com/file.zip
```

### `ensure_jq_installed()`

Garante que jq está instalado, tentando instalar automaticamente se necessário.

**Retorno:**

- `0` - jq disponível
- `1` - Falha na instalação

**Suporte:**

- Debian/Ubuntu: `apt-get install jq`
- Fedora/RHEL: `dnf/yum install jq`
- macOS: `brew install jq`

**Uso:**

```bash
ensure_jq_installed || exit 1

version=$(curl -s https://api.github.com/repos/owner/repo/releases/latest | jq -r '.tag_name')
```

### `ensure_yq_installed()`

Garante que yq está instalado, baixando da última release do GitHub se necessário.

**Retorno:**

- `0` - yq disponível
- `1` - Falha na instalação

**Comportamento:**

1. Verifica se `yq` já está disponível
2. Se não, descobre a versão mais recente do GitHub
3. Detecta plataforma (linux/darwin) e arquitetura (amd64/arm64/386)
4. Baixa binário correto
5. Instala em `/usr/local/bin/yq` (requer sudo)

**Dependências:** Requer `curl` e `jq` (instala automaticamente)

**Uso:**

```bash
ensure_yq_installed || exit 1

name=$(yq eval '.name' config.yaml)
```

### `ensure_fzf_installed()`

Garante que fzf está instalado, baixando da última release do GitHub se necessário.

**Retorno:**

- `0` - fzf disponível
- `1` - Falha na instalação

**Comportamento:**

1. Verifica se `fzf` já está disponível
2. Se não, descobre a versão mais recente do GitHub
3. Detecta plataforma e arquitetura
4. Baixa e extrai tarball correto
5. Instala em `/usr/local/bin/fzf` (requer sudo)

**Dependências:** Requer `curl` e `jq` (instala automaticamente)

**Uso:**

```bash
ensure_fzf_installed || exit 1

selected=$(echo -e "option1\noption2\noption3" | fzf)
```

## Exemplo Completo

```bash
#!/bin/bash
source "$CLI_DIR/lib/dependencies.sh"
source "$CLI_DIR/lib/logger.sh"

log_info "Verificando dependências..."

# Garante todas as dependências
ensure_curl_installed || exit 1
ensure_jq_installed || exit 1
ensure_yq_installed || exit 1
ensure_fzf_installed || exit 1

log_success "Todas as dependências instaladas!"

# Usa as dependências
config_name=$(yq eval '.name' cli.yaml)
selected_env=$(echo -e "dev\nstaging\nprod" | fzf --prompt="Ambiente: ")

log_info "CLI: $config_name"
log_info "Ambiente selecionado: $selected_env"
```

## Boas Práticas

1. Sempre verifique dependências no início do script
2. Use `|| exit 1` para falhar rápido se dependência não instalar
3. Informe o usuário sobre instalações automáticas
