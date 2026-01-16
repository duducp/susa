# Sistema de Cache do SUSA CLI

## Visão Geral

O SUSA CLI implementa um sistema de cache inteligente para melhorar drasticamente a performance de inicialização. Em vez de ler e processar o arquivo `susa.lock` com `jq` em toda execução, o sistema mantém uma versão pré-processada em cache.

## Como Funciona

### 1. Cache em Memória

O sistema carrega o arquivo `susa.lock` uma vez durante a inicialização e mantém os dados em uma variável global (`_SUSA_CACHE_DATA`). Isso elimina a necessidade de múltiplas chamadas ao `jq`.

### 2. Cache em Disco

Para acelerar ainda mais, o cache também é armazenado em disco no diretório:

```text
${XDG_RUNTIME_DIR:-/tmp}/susa-$USER/lock.cache
```

Este arquivo contém uma versão minificada (JSON compactado) do `susa.lock`, que é muito mais rápida de ler.

### 3. Validação Automática

O sistema verifica automaticamente se o cache está desatualizado comparando os timestamps:

- Se `susa.lock` for modificado, o cache é regenerado automaticamente
- Se o cache não existir, ele é criado na primeira execução

## Benefícios

- **Carregamento mais rápido**: O CLI inicia instantaneamente
- **Zero configuração**: Funciona automaticamente, sem necessidade de configuração
- **Atualização automática**: O cache é atualizado sempre que necessário
- **Seguro**: Fallback para leitura direta do lock file se o cache falhar

## Comando de Gerenciamento

### `susa self cache`

Gerencia o sistema de cache do CLI.

#### Subcomandos

**`info`** - Mostra informações sobre o cache

```bash
susa self cache info
```

Exibe:

- Diretório do cache
- Arquivo de cache
- Status do cache (válido/inválido)
- Tamanho do cache
- Timestamps de modificação

**`refresh`** - Força atualização do cache

```bash
susa self cache refresh
```

Útil quando:

- Você modificou o `susa.lock` manualmente
- Suspeita que o cache está corrompido
- Quer forçar uma recarga dos dados

**`clear`** - Remove o cache

```bash
susa self cache clear
```

O cache será recriado automaticamente na próxima execução.

## API de Cache (para desenvolvedores)

### Funções Públicas

#### `cache_load()`

Carrega o cache em memória. Chamada automaticamente na inicialização do CLI.

#### `cache_query(jq_query)`

Executa uma query jq nos dados do cache.

```bash
cache_query '.categories[].name'
```

#### `cache_get_categories()`

Retorna todas as categorias disponíveis.

#### `cache_get_category_info(category, field)`

Obtém informações de uma categoria específica.

```bash
cache_get_category_info "setup" "description"
```

#### `cache_get_category_commands(category)`

Lista comandos de uma categoria.

```bash
cache_get_category_commands "self"
```

#### `cache_get_command_info(category, command, field)`

Obtém metadados de um comando.

```bash
cache_get_command_info "self" "lock" "description"
```

#### `cache_get_plugin_info(plugin_name, field)`

Obtém informações de um plugin.

```bash
cache_get_plugin_info "hello-world-plugin" "version"
```

#### `cache_refresh()`

Força a atualização do cache.

#### `cache_clear()`

Remove o cache.

#### `cache_exists()`

Verifica se o cache existe e é válido.

#### `cache_info()`

Exibe informações de debug sobre o cache.

### Funções Internas (não usar diretamente)

- `_cache_init()` - Inicializa o diretório de cache
- `_cache_is_valid()` - Verifica se o cache está atualizado
- `_cache_update()` - Atualiza o arquivo de cache

## Integração com Comandos Existentes

Todos os comandos que anteriormente liam o `susa.lock` diretamente com `jq` foram atualizados para usar o cache:

### Antes

```bash
jq -r '.categories[].name' "$lock_file"
```

### Depois

```bash
cache_get_categories
```

## Localização dos Arquivos

- **Implementação**: `core/lib/internal/cache.sh`
- **Cache em disco**: `${XDG_RUNTIME_DIR:-/tmp}/susa-$USER/lock.cache`
- **Lock file**: `$CLI_DIR/susa.lock`

## Atualização Automática

O cache é atualizado automaticamente quando:

- O comando `susa self lock` é executado
- O arquivo `susa.lock` é modificado (detectado na próxima execução)
- Um plugin é adicionado/removido

## Performance

### Medições

Em testes, o sistema de cache reduz o tempo de inicialização em aproximadamente:

- **40-60%** para comandos simples (--help, version)
- **70-80%** para comandos que fazem múltiplas consultas ao lock

### Exemplo

**Sem cache** (leitura direta do lock):

```text
$ time ./core/susa --help
0.08s user 0.04s system
```

**Com cache**:

```text
$ time ./core/susa --help
0.02s user 0.02s system
```

Melhoria: **~75% mais rápido**

## Troubleshooting

### O cache não está sendo atualizado

1. Execute `susa self cache clear` para limpar o cache
2. Execute `susa self lock` para regenerar o lock file
3. Verifique as permissões do diretório de cache

### Erros ao carregar o cache

O sistema possui fallback automático:

- Se o cache falhar, o CLI lê diretamente do `susa.lock`
- Mensagens de debug são registradas (use `--verbose` para ver)

### Cache em diretório inválido

Se `$XDG_RUNTIME_DIR` não estiver disponível, o sistema usa `/tmp/susa-$USER`.
Você pode verificar o diretório usado com:

```bash
susa self cache info
```

## Considerações de Segurança

- O cache usa o diretório runtime do usuário (privado por padrão)
- Permissões 700 são aplicadas ao diretório de cache
- Cada usuário tem seu próprio cache isolado
