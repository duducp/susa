# completion.sh

Funções auxiliares para gerenciamento de autocompletar (tab completion) em shells.

## Descrição

A biblioteca `completion.sh` fornece funções para verificar, instalar e gerenciar scripts de autocompletar para Bash, Zsh e Fish. Usada principalmente pelo comando `susa self completion` e `susa self info`.

## Funções

### `get_completion_file_path()`

Retorna o caminho do arquivo de completion para um shell específico.

**Parâmetros:**

- `$1` - Tipo de shell (`bash`, `zsh`, `fish`)

**Retorno:**

- Caminho completo do arquivo de completion
- String vazia se shell não suportado

**Uso:**

```bash
file_path=$(get_completion_file_path "bash")
```

**Exemplo:**

```bash
#!/bin/bash
source "$LIB_DIR/internal/completion.sh"

# Obter caminho do completion para bash
bash_comp=$(get_completion_file_path "bash")
echo "Bash completion: $bash_comp"
# Output: /home/user/.local/share/bash-completion/completions/susa

# Obter caminho do completion para zsh
zsh_comp=$(get_completion_file_path "zsh")
echo "Zsh completion: $zsh_comp"
# Output: /home/user/.local/share/zsh/site-functions/_susa
```

**Caminhos retornados:**

| Shell | Caminho |
|-------|---------|
| bash  | `$HOME/.local/share/bash-completion/completions/susa` |
| zsh   | `$HOME/.local/share/zsh/site-functions/_susa` |
| fish  | *(não implementado)* |

---

### `get_completion_dir_path()`

Retorna o diretório onde arquivos de completion devem ser instalados.

**Parâmetros:**

- `$1` - Tipo de shell (`bash`, `zsh`, `fish`)

**Retorno:**

- Caminho do diretório de completion
- String vazia se shell não suportado

**Uso:**

```bash
dir_path=$(get_completion_dir_path "bash")
```

**Exemplo:**

```bash
#!/bin/bash
source "$LIB_DIR/internal/completion.sh"

# Obter diretório para criar completion
comp_dir=$(get_completion_dir_path "zsh")
mkdir -p "$comp_dir"
```

---

### `is_completion_installed()`

Verifica se o completion está instalado para um shell.

**Parâmetros:**

- `$1` - (Opcional) Tipo de shell. Se omitido, detecta automaticamente

**Retorno:**

- `0` - Completion está instalado
- `1` - Completion não está instalado

**Uso:**

```bash
if is_completion_installed "bash"; then
    echo "Completion já instalado"
fi
```

**Exemplo:**

```bash
#!/bin/bash
source "$LIB_DIR/internal/completion.sh"

# Verificar shell atual
if is_completion_installed; then
    echo "✓ Autocompletar está instalado"
else
    echo "✗ Autocompletar não está instalado"
    echo "Execute: susa self completion --install"
fi

# Verificar shell específico
if is_completion_installed "zsh"; then
    echo "Zsh completion instalado"
fi
```

---

### `get_completion_status()`

Obtém status detalhado da instalação do completion.

**Parâmetros:**

- `$1` - (Opcional) Tipo de shell. Se omitido, detecta automaticamente

**Retorno:**

- String no formato: `status:details:file_path`
  - `status`: `Installed`, `Not installed` ou `Unknown`
  - `details`: Informações adicionais sobre o status
  - `file_path`: Caminho do arquivo de completion

**Uso:**

```bash
status_info=$(get_completion_status)
```

**Exemplo:**

```bash
#!/bin/bash
source "$LIB_DIR/internal/completion.sh"

# Obter status completo
status_info=$(get_completion_status "zsh")

# Parse do resultado
IFS=':' read -r status details file <<< "$status_info"

echo "Status: $status"
echo "Detalhes: $details"
echo "Arquivo: $file"

# Exemplo de output:
# Status: Installed
# Detalhes: carregado no shell atual
# Arquivo: /home/user/.local/share/zsh/site-functions/_susa
```

**Possíveis Status:**

| Status | Detalhes | Situação |
|--------|----------|----------|
| `Installed` | `carregado no shell atual` | Completion ativo no terminal atual |
| `Installed` | `configurado em ~/.zshrc (reinicie o shell)` | Precisa reiniciar terminal |
| `Installed` | `arquivo existe (reinicie o shell)` | Arquivo criado mas não carregado |
| `Not installed` | `Execute: susa self completion --install` | Não instalado |
| `Unknown` | `Shell não suportado` | Shell incompatível |

---

### `is_completion_loaded()`

Verifica se o completion está **carregado** no shell atual (não apenas instalado).

**Parâmetros:**

- `$1` - (Opcional) Tipo de shell. Se omitido, detecta automaticamente

**Retorno:**

- `0` - Completion está carregado e ativo
- `1` - Completion não está carregado

**Uso:**

```bash
if is_completion_loaded; then
    echo "Completion ativo neste terminal"
fi
```

**Exemplo:**

```bash
#!/bin/bash
source "$LIB_DIR/internal/completion.sh"

if is_completion_loaded "bash"; then
    echo "✓ Completion bash ativo"
    echo "Você pode usar TAB para autocompletar"
else
    echo "✗ Completion não carregado"
    echo "Reinicie o terminal ou execute: source ~/.bashrc"
fi
```

**Diferença entre `is_completion_installed` e `is_completion_loaded`:**

- `is_completion_installed`: Verifica se **arquivo existe** no disco
- `is_completion_loaded`: Verifica se está **ativo** no shell atual

---

## Exemplo Completo

### Verificação de Status de Completion

```bash
#!/bin/bash
set -euo pipefail

source "$LIB_DIR/internal/completion.sh"
source "$LIB_DIR/shell.sh"

main() {
    # Detectar shell atual
    current_shell=$(detect_shell_type)
    echo "Shell detectado: $current_shell"
    echo ""

    # Obter status completo
    status_info=$(get_completion_status "$current_shell")
    IFS=':' read -r status details file <<< "$status_info"

    # Exibir informações
    echo "📄 Arquivo: $file"

    if [[ "$status" == "Installed" ]]; then
        echo "✅ Status: Instalado"
        echo "📝 $details"

        if is_completion_loaded "$current_shell"; then
            echo "🎉 Completion está ativo neste terminal!"
        else
            echo "⚠️  Reinicie o terminal para ativar"
        fi
    elif [[ "$status" == "Not installed" ]]; then
        echo "❌ Status: Não instalado"
        echo "💡 $details"
    else
        echo "❓ Status: Desconhecido"
        echo "⚠️  $details"
    fi
}

main
```

### Instalação Condicional

```bash
#!/bin/bash
set -euo pipefail

source "$LIB_DIR/internal/completion.sh"

install_completion() {
    local shell_type="$1"

    # Verificar se já está instalado
    if is_completion_installed "$shell_type"; then
        echo "✓ Completion já está instalado para $shell_type"
        return 0
    fi

    # Obter diretório e arquivo
    local comp_dir=$(get_completion_dir_path "$shell_type")
    local comp_file=$(get_completion_file_path "$shell_type")

    # Criar diretório
    mkdir -p "$comp_dir"

    # Gerar e salvar script
    generate_completion_script "$shell_type" > "$comp_file"

    echo "✓ Completion instalado em: $comp_file"
    echo "  Reinicie o terminal ou execute: source ~/.${shell_type}rc"
}

install_completion "zsh"
```

---

## Comandos que Usam

- `susa self completion` - Gerencia instalação e remoção
- `susa self info` - Exibe status do completion

---

## Dependências

- `shell.sh` - Para detectar tipo de shell atual (`detect_shell_type`)

---

## Shells Suportados

| Shell | Suporte | Notas |
|-------|---------|-------|
| Bash  | ✅ Completo | Usa `bash-completion` |
| Zsh   | ✅ Completo | Usa `site-functions` |
| Fish  | ⚠️ Parcial | Estrutura pronta mas não implementado |

---

## Estrutura de Diretórios

```text
$HOME/
├── .local/share/
│   ├── bash-completion/
│   │   └── completions/
│   │       └── susa              # Bash completion
│   └── zsh/
│       └── site-functions/
│           └── _susa             # Zsh completion
└── .bashrc / .zshrc              # Referência ao completion
```

---

## Localização

```text
core/lib/internal/completion.sh
```

**Importar:**

```bash
source "$LIB_DIR/internal/completion.sh"
```

---

## Veja Também

- [shell.sh](shell.md) - Detecção de tipo de shell
- [cli.sh](cli.md) - Funções principais do CLI
- Comando: `susa self completion`
