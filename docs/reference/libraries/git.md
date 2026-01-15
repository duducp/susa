# git.sh

Operações Git para gerenciamento de plugins.

## Visão Geral

A biblioteca `git.sh` fornece funções para:

- 🔍 Validação de acesso a repositórios Git
- 📥 Clonagem de repositórios
- 🔄 Atualização de repositórios
- 🔐 Detecção de provedores Git (GitHub, GitLab, Bitbucket)
- 🔑 Verificação de acesso SSH

## Funções de Verificação

### `ensure_git_installed()`

Verifica se o Git está instalado no sistema.

**Retorno:**

- `0` - Git instalado
- `1` - Git não instalado (exibe erro e sai)

**Uso:**

```bash
ensure_git_installed  # Sai se Git não estiver instalado
```

### `has_github_ssh_access()`

Verifica se há acesso SSH ao GitHub.

**Retorno:**

- `0` - Acesso SSH disponível
- `1` - Sem acesso SSH

**Uso:**

```bash
if has_github_ssh_access; then
    log_info "Acesso SSH ao GitHub disponível"
else
    log_warning "Sem acesso SSH ao GitHub"
fi
```

### `has_gitlab_ssh_access()`

Verifica se há acesso SSH ao GitLab.

**Retorno:**

- `0` - Acesso SSH disponível
- `1` - Sem acesso SSH

**Uso:**

```bash
if has_gitlab_ssh_access; then
    log_info "Acesso SSH ao GitLab disponível"
fi
```

### `has_bitbucket_ssh_access()`

Verifica se há acesso SSH ao Bitbucket.

**Retorno:**

- `0` - Acesso SSH disponível
- `1` - Sem acesso SSH

**Uso:**

```bash
if has_bitbucket_ssh_access; then
    log_info "Acesso SSH ao Bitbucket disponível"
fi
```

## Funções de Operação

### `clone_plugin()`

Clona um repositório Git de plugin.

**Parâmetros:**

- `$1` - URL do repositório
- `$2` - Diretório destino

**Comportamento:**

- Clona de forma silenciosa
- Cria diretório destino se não existir
- Exibe erro se falhar

**Retorno:**

- `0` - Clone bem-sucedido
- `1` - Erro no clone

**Uso:**

```bash
if clone_plugin "https://github.com/user/plugin.git" "$PLUGINS_DIR/plugin"; then
    log_success "Plugin clonado com sucesso"
else
    log_error "Falha ao clonar plugin"
fi
```

### `pull_plugin()`

Atualiza um repositório Git de plugin.

**Parâmetros:**

- `$1` - Diretório do plugin

**Comportamento:**

- Faz `git pull` silencioso
- Verifica se é um repositório Git válido
- Exibe erro se falhar

**Retorno:**

- `0` - Atualização bem-sucedida
- `1` - Erro na atualização

**Uso:**

```bash
if pull_plugin "$PLUGINS_DIR/plugin"; then
    log_success "Plugin atualizado"
else
    log_error "Falha ao atualizar plugin"
fi
```

## Funções de Detecção

### `detect_git_provider()`

Detecta o provedor Git de uma URL.

**Parâmetros:**

- `$1` - URL do repositório

**Retorno:** Nome do provedor (github, gitlab, bitbucket) ou string vazia

**Uso:**

```bash
provider=$(detect_git_provider "https://github.com/user/repo.git")
echo "$provider"  # github

provider=$(detect_git_provider "git@gitlab.com:user/repo.git")
echo "$provider"  # gitlab
```

### `validate_repo_access()`

Valida acesso a um repositório Git.

**Parâmetros:**

- `$1` - URL do repositório

**Comportamento:**

- Detecta o provedor Git
- Verifica acesso SSH se URL for SSH
- Verifica conectividade se URL for HTTPS
- Exibe avisos apropriados

**Retorno:**

- `0` - Acesso validado
- `1` - Sem acesso

**Uso:**

```bash
if validate_repo_access "git@github.com:user/repo.git"; then
    log_info "Acesso ao repositório confirmado"
else
    log_warning "Sem acesso ao repositório"
fi
```

## Exemplo Completo

```bash
#!/bin/bash
source "$LIB_DIR/internal/git.sh"
source "$LIB_DIR/logger.sh"

# Verifica instalação do Git
ensure_git_installed

# URL do plugin
repo_url="git@github.com:user/susa-plugin-example.git"
plugin_dir="$PLUGINS_DIR/example"

# Valida acesso
if ! validate_repo_access "$repo_url"; then
    log_error "Sem acesso ao repositório"
    exit 1
fi

# Clona se não existe, atualiza se existe
if [ -d "$plugin_dir" ]; then
    log_info "Atualizando plugin..."
    if pull_plugin "$plugin_dir"; then
        log_success "Plugin atualizado"
    fi
else
    log_info "Clonando plugin..."
    if clone_plugin "$repo_url" "$plugin_dir"; then
        log_success "Plugin instalado"
    fi
fi
```

## Boas Práticas

1. **Sempre verificar Git instalado:**

   ```bash
   ensure_git_installed
   ```

2. **Validar acesso antes de clonar:**

   ```bash
   validate_repo_access "$url" || exit 1
   ```

3. **Verificar existência antes de atualizar:**

   ```bash
   [ -d "$plugin_dir" ] && pull_plugin "$plugin_dir"
   ```

4. **Usar detecção de provedor para lógica específica:**

   ```bash
   provider=$(detect_git_provider "$url")
   case "$provider" in
       github) log_info "GitHub detectado" ;;
       gitlab) log_info "GitLab detectado" ;;
   esac
   ```

## Notas

- Funções são isoladas de plugin.sh para melhor organização
- Suporta GitHub, GitLab e Bitbucket
- Verificações SSH usam teste de conexão real
- Operações Git são silenciosas por padrão
- Erros são tratados e reportados adequadamente
