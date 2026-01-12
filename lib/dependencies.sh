#!/bin/bash

# Obtém o diretório da lib
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/logger.sh"

# --- Dependencies Installer Functions ---

# --- Curl Helper Function ---

# Garante que o curl está instalado. Se não estiver, tenta instalar.
ensure_curl_installed() {
  if command -v curl &>/dev/null; then
    return 0
  fi

  log_warning "curl não encontrado. Tentando instalar curl..."

  case "$OS_TYPE" in
    debian)
      sudo apt-get update && sudo apt-get install -y curl
      ;;
    fedora)
      if command -v dnf &>/dev/null; then
        sudo dnf install -y curl
      else
        sudo yum install -y curl
      fi
      ;;
    macos)
      if command -v brew &>/dev/null; then
        brew install curl
      else
        log_error "Homebrew não encontrado. Instale o Homebrew ou o curl manualmente: https://brew.sh/"
        return 1
      fi
      ;;
    *)
      log_error "Sistema operacional não suportado para instalação automática do curl. Instale manualmente."
      return 1
      ;;
  esac

  if ! command -v curl &>/dev/null; then
    log_error "Falha ao instalar o curl. Instale manualmente."
    return 1
  fi

  log_success "curl instalado com sucesso."
  return 0
}

# --- JQ Helper Function ---

# Garante que o jq está instalado. Se não estiver, tenta instalar.
ensure_jq_installed() {
  if command -v jq &>/dev/null; then
    return 0
  fi

  log_warning "jq não encontrado. Tentando instalar jq..."

  case "$OS_TYPE" in
    debian)
      sudo apt-get update && sudo apt-get install -y jq
      ;;
    fedora)
      if command -v dnf &>/dev/null; then
        sudo dnf install -y jq
      else
        sudo yum install -y jq
      fi
      ;;
    macos)
      if command -v brew &>/dev/null; then
        brew install jq
      else
        log_error "Homebrew não encontrado. Instale o Homebrew ou o jq manualmente: https://brew.sh/"
        return 1
      fi
      ;;
    *)
      log_error "Sistema operacional não suportado para instalação automática do jq. Instale manualmente."
      return 1
      ;;
  esac

  if ! command -v jq &>/dev/null; then
    log_error "Falha ao instalar o jq. Instale manualmente."
    return 1
  fi

  log_success "jq instalado com sucesso."
  return 0
}

# --- YQ Helper Function ---

ensure_yq_installed() {
  if command -v yq &>/dev/null; then
    return 0
  fi

  log_warning "yq não encontrado. Iniciando instalação da versão mais recente..."

  # Garante dependências para descobrir a versão e baixar
  ensure_curl_installed || return 1
  ensure_jq_installed || return 1

  # 1. Descobrir a versão mais recente
  local latest_tag
  latest_tag=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r '.tag_name')
  local version_no_v="${latest_tag#v}"

  # 2. Detectar Plataforma e Arquitetura
  local platform="linux"
  [[ "$OS_TYPE" == "macos" ]] && platform="darwin"

  local arch="amd64"
  local machine_arch
  machine_arch=$(uname -m)
  case "$machine_arch" in
    arm64|aarch64) arch="arm64" ;;
    x86_64)        arch="amd64" ;;
    i386|i686)     arch="386"   ;;
  esac

  # 3. Download e Instalação
  local binary="yq_${platform}_${arch}"
  local download_url="https://github.com/mikefarah/yq/releases/download/${latest_tag}/${binary}"
  local temp_dir
  temp_dir=$(mktemp -d)

  log_info "Baixando yq ${latest_tag} para ${platform}_${arch}..."

  if curl -L "$download_url" -o "${temp_dir}/yq"; then
    log_info "Instalando binário em /usr/local/bin (pode solicitar sudo)..."
    if sudo mv "${temp_dir}/yq" /usr/local/bin/yq; then
      sudo chmod +x /usr/local/bin/yq
      log_success "yq instalado com sucesso: $(yq --version)"
    else
      log_error "Falha ao mover o binário para /usr/local/bin."
      rm -rf "$temp_dir"
      return 1
    fi
  else
    log_error "Erro ao baixar o yq do GitHub. Verifique sua conexão."
    rm -rf "$temp_dir"
    return 1
  fi

  rm -rf "$temp_dir"
  return 0
}

# --- FZF Helper Function ---

# Verifica se o fzf está instalado. Se não estiver, instala a versão mais recente do GitHub.
ensure_fzf_installed() {
  if command -v fzf &>/dev/null; then
    return 0
  fi

  log_warning "fzf não encontrado. Iniciando instalação da versão mais recente..."

  # Garante dependências para descobrir a versão e baixar
  ensure_curl_installed || return 1
  ensure_jq_installed || return 1

  # 1. Descobrir a versão mais recente e preparar variáveis
  local latest_tag
  latest_tag=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest | jq -r '.tag_name')
  local version_no_v="${latest_tag#v}"

  # 2. Detetar Plataforma e Arquitetura
  local platform="linux"
  [[ "$OS_TYPE" == "macos" ]] && platform="darwin"

  local arch="amd64"
  local machine_arch
  machine_arch=$(uname -m)
  case "$machine_arch" in
    arm64|aarch64) arch="arm64" ;;
    x86_64)        arch="amd64" ;;
    i386|i686)     arch="386"   ;;
  esac

  # 3. Download e Instalação
  local tarball="fzf-${version_no_v}-${platform}_${arch}.tar.gz"
  local download_url="https://github.com/junegunn/fzf/releases/download/${latest_tag}/${tarball}"
  local temp_dir
  temp_dir=$(mktemp -d)

  log_info "A baixar fzf ${latest_tag} para ${platform}_${arch}..."

  if curl -L "$download_url" -o "${temp_dir}/${tarball}"; then
    tar -xzf "${temp_dir}/${tarball}" -C "${temp_dir}"
    
    log_info "A instalar binário em /usr/local/bin (pode solicitar sudo)..."
    if sudo mv "${temp_dir}/fzf" /usr/local/bin/fzf; then
      sudo chmod +x /usr/local/bin/fzf
      log_success "fzf instalado com sucesso: $(fzf --version)"
    else
      log_error "Falha ao mover o binário para /usr/local/bin."
      rm -rf "$temp_dir"
      return 1
    fi
  else
    log_error "Erro ao descarregar o fzf do GitHub. Verifique a sua ligação."
    rm -rf "$temp_dir"
    return 1
  fi

  rm -rf "$temp_dir"
  return 0
}
