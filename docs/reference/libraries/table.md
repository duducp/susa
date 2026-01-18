# table.sh

Sistema genérico de renderização de tabelas usando `column` para alinhamento automático.

## Descrição

A biblioteca `table.sh` fornece funções para criar e exibir tabelas formatadas de forma consistente em todo o CLI. Usa o comando `column` para alinhamento automático das colunas.

## Carregamento

```bash
source "$LIB_DIR/table.sh"
```

## API

### `table_init()`

Inicializa uma nova tabela, limpando qualquer dado anterior.

**Exemplo:**

```bash
table_init
```

### `table_set_indent(indentação)`

Define a indentação da tabela (padrão: 2 espaços).

**Argumentos:**

- `indentação` - String de indentação (ex: "  ", "    ")

**Exemplo:**

```bash
table_set_indent "    "  # 4 espaços
```

### `table_add_header(col1, col2, ...)`

Adiciona uma linha de cabeçalho com formatação em negrito/cinza.

**Argumentos:**

- `col1, col2, ...` - Valores das colunas do cabeçalho

**Exemplo:**

```bash
table_add_header "Nome" "Idade" "Cidade"
```

### `table_add_row(val1, val2, ...)`

Adiciona uma linha de dados à tabela.

**Argumentos:**

- `val1, val2, ...` - Valores das colunas

**Exemplo:**

```bash
table_add_row "João" "25" "São Paulo"
table_add_row "${CYAN}Maria${NC}" "30" "Rio de Janeiro"
```

### `table_render([--no-clear])`

Renderiza a tabela usando `column` para alinhamento.

**Opções:**

- `--no-clear` - Não limpa a tabela após renderizar (padrão: limpa)

**Exemplo:**

```bash
table_render
# ou
table_render --no-clear
```

### `table_get_data()`

Retorna o conteúdo atual da tabela (útil para debugging).

**Exemplo:**

```bash
local data=$(table_get_data)
echo "Dados da tabela: $data"
```

### `table_count_rows()`

Retorna o número de linhas na tabela.

**Exemplo:**

```bash
local count=$(table_count_rows)
echo "Total de linhas: $count"
```

## Exemplo Completo

```bash
#!/bin/bash
source "$LIB_DIR/table.sh"

# Criar tabela
table_init
table_add_header "Nome" "Tamanho" "Status"

# Adicionar dados
table_add_row "${CYAN}lock${NC}" "8KB" "${GREEN}✓${NC}"
table_add_row "${CYAN}context${NC}" "2KB" "${GREEN}✓${NC}"
table_add_row "${CYAN}temp${NC}" "512B" "${YELLOW}⚠${NC}"

# Renderizar
table_render

# Output:
#   Nome     Tamanho  Status
#   lock     8KB      ✓
#   context  2KB      ✓
#   temp     512B     ⚠
```

## Uso em Plugins

Plugins podem usar a biblioteca da mesma forma:

```bash
#!/bin/bash
# No plugin
source "$LIB_DIR/table.sh"

table_init
table_add_header "ID" "Name" "Version"

for app in "${apps[@]}"; do
    table_add_row "$id" "$name" "$version"
done

table_render
```

## Características

✅ **Alinhamento automático** - `column` ajusta colunas ao conteúdo
✅ **Suporte a cores** - Códigos ANSI são preservados
✅ **Cross-platform** - Funciona em Linux e macOS
✅ **API simples** - Funções intuitivas
✅ **Reutilizável** - Disponível para comandos e plugins
✅ **Consistente** - Mesma formatação em todo o CLI

## Notas

- O separador de colunas é `\t` (tab)
- Indentação padrão é 2 espaços
- A tabela é limpa automaticamente após `table_render()`
- Cores são carregadas de `color.sh` se disponível

## Veja Também

- [color.sh](color.md) - Sistema de cores
- [logger.sh](logger.md) - Sistema de logs
