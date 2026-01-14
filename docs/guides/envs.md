# Variáveis de Ambiente

Referência rápida sobre o sistema de variáveis de ambiente do Susa CLI.

> **📖 Para documentação completa**, veja [Guia de Configuração](configuration.md#variaveis-de-ambiente-por-comando).

## 📋 Tipos de Variáveis

### 1. Variáveis por Comando (Isoladas)

Definidas no `config.yaml` do comando, disponíveis apenas durante sua execução.

**Definição:**

```yaml
# commands/setup/docker/config.yaml
name: "Docker"
description: "Instala Docker"
entrypoint: "main.sh"
sudo: true
os: ["linux"]
envs:
  DOCKER_REPO_URL: "https://download.docker.com"
  DOCKER_TIMEOUT: "300"
  DOCKER_INSTALL_DIR: "$HOME/.docker"
```

**Uso no script:**

```bash
#!/bin/bash
setup_command_env

# Variáveis automaticamente disponíveis
repo="${DOCKER_REPO_URL:-https://default.com}"
timeout="${DOCKER_TIMEOUT:-300}"
install_dir="${DOCKER_INSTALL_DIR:-$HOME/.docker}"
```

**Características:**

- ✅ Carregamento automático
- ✅ Expansão de variáveis (`$HOME`, `$USER`)
- ✅ Isolamento total (não vazam entre comandos)
- ✅ Sobrescrita por variáveis de sistema

### 2. Variáveis Globais (Compartilhadas)

Definidas em `config/settings.conf`, disponíveis para todos os comandos.

**Definição:**

```bash
# config/settings.conf
API_ENDPOINT="https://api.example.com"
API_TOKEN="secret-token"
HTTP_TIMEOUT="30"
DEBUG_MODE="false"
```

**Uso:**

```bash
#!/bin/bash
setup_command_env

# Disponíveis em todos os comandos
echo "API: ${API_ENDPOINT}"
echo "Timeout: ${HTTP_TIMEOUT}"
```

### 3. Variáveis de Sistema (Override)

Definidas na linha de comando, sobrescrevem todas as outras.

```bash
# Override temporário
DOCKER_TIMEOUT=600 susa setup docker

# Export permanente (sessão)
export DEBUG=true
susa setup docker
```

## 🎯 Precedência

Ordem de precedência (maior → menor):

```text
1. Variáveis de Sistema    → export VAR=value ou VAR=value comando
2. Envs do Comando         → config.yaml → envs:
3. Variáveis Globais       → config/settings.conf
4. Valores Padrão          → ${VAR:-default}
```

**Exemplo prático:**

```yaml
# config.yaml
envs:
  TIMEOUT: "60"
```

```bash
# config/settings.conf
TIMEOUT="30"
```

```bash
# No script
timeout="${TIMEOUT:-10}"

# Resultados:
./susa comando                    # → 60 (do comando)
TIMEOUT=90 ./susa comando        # → 90 (do sistema)
```

## 📝 Sintaxe YAML

### Tipos de Valores

```yaml
envs:
  # String simples
  VAR_STRING: "valor"

  # Número (sempre como string)
  VAR_NUMBER: "42"

  # Boolean (sempre como string)
  VAR_BOOL: "true"

  # URL
  VAR_URL: "https://example.com/path"

  # Path com variável
  VAR_PATH: "$HOME/.config/app"

  # Path com múltiplas variáveis
  VAR_COMPLEX: "$HOME/backups/$USER"
```

### Expansão de Variáveis

Variáveis suportadas para expansão:

- `$HOME` - Diretório home do usuário
- `$USER` - Nome do usuário
- `$PWD` - Diretório atual
- `$HOSTNAME` - Nome do host
- Qualquer variável de ambiente existente

**Exemplo:**

```yaml
envs:
  CONFIG_DIR: "$HOME/.config/myapp"        # → /home/user/.config/myapp
  BACKUP_DIR: "$HOME/backups/$USER"        # → /home/user/backups/user
  LOG_FILE: "$PWD/logs/app.log"           # → /current/dir/logs/app.log
```

## 🛠️ Uso no Script

### Padrão Recomendado

Sempre use valores de fallback com a sintaxe `${VAR:-default}`:

```bash
#!/bin/bash
set -euo pipefail

setup_command_env

# ✅ Bom: funciona com ou sem env
local timeout="${TIMEOUT:-30}"
local url="${API_URL:-https://default.com}"
local dir="${INSTALL_DIR:-$HOME/.app}"

# ❌ Ruim: quebra se env não existir
local timeout="$TIMEOUT"
```

**Como funciona `${VAR:-default}`:**

- Se `VAR` estiver definida e não vazia → usa o valor de `VAR`
- Se `VAR` não estiver definida ou estiver vazia → usa `default`

**Exemplos:**

```bash
# Variável definida no config.yaml
TIMEOUT="60"
timeout="${TIMEOUT:-30}"        # → 60 (usa o valor da env)

# Variável não definida
# TIMEOUT não existe
timeout="${TIMEOUT:-30}"        # → 30 (usa o valor padrão)

# Override via sistema
TIMEOUT=90 susa comando
timeout="${TIMEOUT:-30}"        # → 90 (usa o valor do sistema)
```

**Sintaxes alternativas:**

```bash
# ${VAR:-default} - Mais comum, usa default se VAR vazia ou indefinida
url="${API_URL:-https://default.com}"

# ${VAR-default} - Usa default apenas se VAR indefinida (não se vazia)
url="${API_URL-https://default.com}"

# ${VAR:=default} - Define VAR como default se vazia ou indefinida
: "${TIMEOUT:=30}"              # TIMEOUT agora tem valor 30 se estava vazia

# Recomendamos usar ${VAR:-default} por ser mais seguro
```

### Validação de Variáveis

```bash
# Verificar se variável obrigatória existe
if [ -z "${API_TOKEN:-}" ]; then
    log_error "API_TOKEN não configurado"
    exit 1
fi

# Usar variável
curl -H "Authorization: Bearer $API_TOKEN" "$API_URL"
```

### Documentação Inline

```bash
# URLs e endpoints
local api_url="${API_URL:-https://api.example.com}"  # URL da API principal
local timeout="${API_TIMEOUT:-30}"                    # Timeout em segundos (padrão: 30)

# Diretórios
local install_dir="${INSTALL_DIR:-$HOME/.app}"        # Diretório de instalação
local backup_dir="${BACKUP_DIR:-/var/backups}"        # Diretório de backup
```

## 📊 Comparação

| Característica | Envs por Comando | Envs Globais | Variáveis de Sistema |
| -------------- | ---------------- | ------------ | -------------------- |
| **Escopo** | Apenas o comando | Todos os comandos | Override temporário |
| **Arquivo** | `config.yaml` | `config/settings.conf` | Linha de comando |
| **Isolamento** | ✅ Total | ❌ Compartilhado | ✅ Por execução |
| **Expansão** | ✅ Automática | ❌ Manual | ❌ Manual |
| **Precedência** | Média | Baixa | Alta |
| **Uso** | Configs específicas | Configs globais | Testing/Debug |

## ✅ Boas Práticas

### 1. Prefixos Únicos

```yaml
# ✅ Bom: prefixo único por comando
envs:
  DOCKER_REPO_URL: "..."
  DOCKER_TIMEOUT: "..."

# ❌ Ruim: muito genérico
envs:
  REPO_URL: "..."
  TIMEOUT: "..."
```

### 2. Documentação

```yaml
envs:
  # URL do repositório Docker (padrão: https://download.docker.com)
  DOCKER_REPO_URL: "https://download.docker.com"

  # Timeout máximo para download em segundos (padrão: 300)
  # Aumentar se conexão for lenta
  DOCKER_DOWNLOAD_TIMEOUT: "300"

  # Diretório de instalação (padrão: /var/lib/docker)
  # Deve ter pelo menos 20GB livres
  DOCKER_DATA_ROOT: "/var/lib/docker"
```

### 3. Valores Padrão Sensatos

Configure valores padrão no `config.yaml` e **sempre** forneça fallback no script:

```yaml
# config.yaml
envs:
  # Timeouts razoáveis
  HTTP_TIMEOUT: "30"           # 30 segundos
  DOWNLOAD_TIMEOUT: "300"      # 5 minutos

  # Retries apropriados
  HTTP_RETRY: "3"              # 3 tentativas

  # Paths seguros
  INSTALL_DIR: "$HOME/.app"    # No home do usuário
```

```bash
# main.sh - Sempre com fallback
timeout="${HTTP_TIMEOUT:-30}"
download_timeout="${DOWNLOAD_TIMEOUT:-300}"
retry="${HTTP_RETRY:-3}"
install_dir="${INSTALL_DIR:-$HOME/.app}"
```

**Por que usar fallback no script?**

- ✅ Script funciona mesmo se `config.yaml` não tiver `envs`
- ✅ Valores padrão visíveis no código
- ✅ Facilita manutenção e testes
- ✅ Documentação inline dos valores esperados

### 4. Tipos Consistentes

```yaml
envs:
  # Números sempre como strings
  PORT: "8080"                 # ✅
  MAX_CONNECTIONS: "100"       # ✅

  # Booleanos sempre como strings
  ENABLE_CACHE: "true"         # ✅
  DEBUG_MODE: "false"          # ✅

  # Não use tipos nativos YAML
  PORT: 8080                   # ❌
  ENABLE_CACHE: true           # ❌
```

## 🔍 Debugging

### Ver Variáveis Carregadas

```bash
# No script, adicione temporariamente:
echo "=== Variáveis Carregadas ==="
echo "DOCKER_REPO_URL: ${DOCKER_REPO_URL:-não definida}"
echo "DOCKER_TIMEOUT: ${DOCKER_TIMEOUT:-não definida}"
echo "============================="
```

### Testar com Diferentes Valores

```bash
# Usar valor padrão
$ susa setup docker

# Override via sistema
$ DOCKER_TIMEOUT=600 susa setup docker

# Debug completo
$ DEBUG=true DOCKER_TIMEOUT=600 susa setup docker
```

### Verificar Expansão

```bash
# No script:
local dir="${INSTALL_DIR:-$HOME/.app}"
log_debug "Diretório expandido: $dir"

# Executar com debug:
$ DEBUG=true susa setup myapp
[DEBUG] Diretório expandido: /home/user/.app
```

## 📚 Recursos Adicionais

- **[Guia de Configuração](configuration.md)** - Documentação completa
- **[Como Adicionar Comandos](adding-commands.md)** - Criar comandos com envs
- **[Exemplos Práticos](adding-commands.md#exemplo-com-variaveis-de-ambiente)** - Código completo

## 🎯 Exemplo Mínimo

**config.yaml:**

```yaml
name: "My Command"
description: "Meu comando"
entrypoint: "main.sh"
sudo: false
os: ["linux"]
envs:
  MY_URL: "https://example.com"
  MY_TIMEOUT: "30"
```

**main.sh:**

```bash
#!/bin/bash
set -euo pipefail

setup_command_env

url="${MY_URL:-https://default.com}"
timeout="${MY_TIMEOUT:-30}"

curl --max-time "$timeout" "$url"
```

**Execução:**

```bash
# Usar valores do config.yaml
$ susa my command

# Override temporário
$ MY_TIMEOUT=60 susa my command
```
