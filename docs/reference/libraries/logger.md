# logger.sh

Sistema de logs com níveis diferentes e timestamps automáticos.

## Funções

### `log()`

Log básico sem nível específico.

```bash
log "Mensagem informativa"
# Output: [MESSAGE] 2026-01-12 14:30:45 - Mensagem informativa
```

### `log_info()`

Log de informação (azul ciano).

```bash
log_info "Iniciando processo..."
# Output: [INFO] 2026-01-12 14:30:45 - Iniciando processo...
```

### `log_success()`

Log de sucesso (verde).

```bash
log_success "Instalação concluída com sucesso!"
# Output: [SUCCESS] 2026-01-12 14:30:45 - Instalação concluída com sucesso!
```

### `log_warning()`

Log de aviso (amarelo).

```bash
log_warning "Recurso em versão experimental"
# Output: [WARNING] 2026-01-12 14:30:45 - Recurso em versão experimental
```

### `log_error()`

Log de erro (vermelho, escreve para stderr).

```bash
log_error "Falha ao conectar ao servidor"
# Output (stderr): [ERROR] 2026-01-12 14:30:45 - Falha ao conectar ao servidor
```

### `log_debug()`

Log de debug (cinza, só aparece se `DEBUG=true`).

```bash
DEBUG=true
log_debug "Variável X = $X"
# Output: [DEBUG] 2026-01-12 14:30:45 - Variável X = 42
```

**Ativação do debug:**

```bash
# Ativa debug com qualquer um dos valores:
DEBUG=true
DEBUG=1
DEBUG=on
```

## Exemplo Completo

```bash
#!/bin/bash
source "$CLI_DIR/lib/logger.sh"

log_info "Verificando dependências..."

if command -v docker &>/dev/null; then
    log_success "Docker encontrado"
else
    log_error "Docker não está instalado"
    exit 1
fi

log_warning "Usando configuração padrão"
DEBUG=true log_debug "PATH=$PATH"
```

## Boas Práticas

1. Use `log_info` para progresso normal
2. Use `log_success` para confirmações importantes
3. Use `log_warning` para avisos não-críticos
4. Use `log_error` antes de `exit 1`
5. Use `log_debug` para desenvolvimento e troubleshooting
