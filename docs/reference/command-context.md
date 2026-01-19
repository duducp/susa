# Sistema de Contexto de Comandos

O SUSA CLI implementa um sistema de contexto que captura e disponibiliza toda a estrutura do comando sendo executado.

## O que é capturado?

Quando você executa um comando, as seguintes informações são automaticamente salvas no contexto:

- **category**: Categoria do comando (ex: `setup`, `self`)
- **name**: Nome do comando (ex: `docker`, `info`)
- **parent**: Categoria pai (se houver subcategorias)
- **current**: Nome do comando atual
- **action**: Ação executada (primeiro argumento não-flag, separado dos args)
- **full**: Comando completo digitado pelo usuário
- **path**: Caminho absoluto para o diretório do comando
- **args**: Lista de argumentos (flags e opções após a action)
- **args_count**: Número de argumentos (excluindo a action)

## Exemplos

### Comando simples

```bash
susa setup docker
```

**Contexto gerado:**

```json
{
  "category": "setup",
  "name": "docker",
  "parent": "",
  "current": "docker",
  "action": "",
  "full": "susa setup docker",
  "path": "/path/to/commands/setup/docker",
  "args": []
}
```

### Comando com argumentos

```bash
susa setup vscode install --force
```

**Contexto gerado:**

```json
{
  "category": "setup",
  "name": "vscode",
  "parent": "",
  "current": "vscode",
  "action": "install",
  "full": "susa setup vscode install --force",
  "path": "/path/to/commands/setup/vscode",
  "args": ["--force"]
}
```

### Comando com subcategoria

```bash
susa self context show --json
```

**Contexto gerado:**

```json
{
  "category": "self/context",
  "name": "show",
  "parent": "context",
  "current": "show",
  "action": "",
  "full": "susa self context show --json",
  "path": "/path/to/commands/self/context/show",
  "args": ["--json"]
}
```

## Como usar no seu comando

As bibliotecas essenciais (`context.sh` incluída) são carregadas automaticamente. Você pode acessar as informações do contexto diretamente:

### Obter informações específicas

```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

main() {
    # Obter categoria do comando
    local category=$(context_get "command.category")

    # Obter nome do comando
    local command_name=$(context_get "command.name")

    # Obter ação (primeiro argumento)
    local action=$(context_get "command.action")

    # Obter comando completo
    local full_command=$(context_get "command.full")

    # Obter caminho do comando
    local command_path=$(context_get "command.path")

    echo "Executando: $full_command"
    echo "Categoria: $category"
    echo "Comando: $command_name"
    echo "Ação: $action"
}

main "$@"
```

### Obter argumentos

```bash
# Obter todos os argumentos (um por linha)
local args=$(context_get "command.args")

# Obter número de argumentos
local args_count=$(context_get "command.args_count")

# Obter argumento específico por índice
local first_arg=$(context_get "command.arg.0")
local second_arg=$(context_get "command.arg.1")

# Iterar sobre todos os argumentos
for ((i=0; i<args_count; i++)); do
    local arg=$(context_get "command.arg.$i")
    echo "Argumento $i: $arg"
done
```

### Obter contexto completo

```bash
# Obter todo o contexto como JSON
context_get_all

# Ou acessar campos individuais
context_get "command.category"
context_get "command.name"
context_get "command.action"
```

## Funções disponíveis

### Campos do Comando Disponíveis

Todos acessados via `context_get "command.<campo>"`:

- `command.category` - Categoria raiz do comando
- `command.full_category` - Categoria completa (com subcategorias)
- `command.name` - Nome do comando
- `command.parent` - Categoria pai (se subcategoria)
- `command.current` - Comando atual
- `command.action` - Primeira ação/argumento não-flag (separado de args)
- `command.full` - Comando completo digitado
- `command.path` - Caminho absoluto do comando
- `command.args` - Todos os argumentos (um por linha)
- `command.args_count` - Número de argumentos (excluindo action)
- `command.arg.0`, `command.arg.1`, etc - Argumentos individuais por índice

### Funções de Contexto Genéricas

| Função | Descrição |
|--------|-----------|
| `context_set "key" "value"` | Define valor no contexto |
| `context_get "key"` | Obtém valor do contexto |
| `context_has "key"` | Verifica se chave existe |
| `context_remove "key"` | Remove chave do contexto |
| `context_get_all` | Obtém todo o contexto como JSON |
| `context_clear` | Limpa o contexto |

## Testar o contexto

Você pode adicionar código de debug em seus comandos:

```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

main() {
    # Debug: ver todo o contexto
    if [ "${DEBUG:-}" = "1" ]; then
        log_debug "Contexto completo:"
        context_get_all | jq .
    fi

    # Sua lógica aqui...
}

main "$@"
```

## Caso de uso: Detectar modo de execução

```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

main() {
    local action=$(context_get "command.action")

    case "$action" in
        install)
            echo "Executando instalação..."
            # Lógica de instalação
            ;;
        update)
            echo "Executando atualização..."
            # Lógica de atualização
            ;;
        remove)
            echo "Executando remoção..."
            # Lógica de remoção
            ;;
        *)
            echo "Ação não reconhecida: $action"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
```

## Caso de uso: Log contextual

```bash
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

main() {
    local full_command=$(context_get "command.full")
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Log com contexto
    echo "[$timestamp] Executando: $full_command" >> /var/log/susa.log

    # Lógica do comando...

    log_success "Comando executado com sucesso"
}

main "$@"
```

## Notas importantes

1. **Inicialização automática**: O contexto é inicializado automaticamente pelo executor antes de chamar seu comando
2. **Limpeza automática**: O contexto é limpo automaticamente após a execução
3. **Isolamento**: Cada execução de comando tem seu próprio contexto isolado
4. **Performance**: Usa o sistema de cache nomeado para acesso rápido em memória

## Veja também

- [Sistema de Cache](../cache.md)
- [Bibliotecas Internas](../../libraries/internal/README.md)
- [Criando Comandos](../../../guides/adding-commands.md)
