# susa self cache

Gerencia o sistema de cache do CLI para melhorar a performance de inicialização.

## Uso

```bash
susa self cache <comando>
```

## Comandos Disponíveis

### info

Exibe informações detalhadas sobre o estado do cache.

```bash
susa self cache info
```

**Saída:**

- Diretório do cache
- Arquivo de cache
- Status de carregamento em memória
- Existência do cache
- Tamanho do arquivo de cache
- Data de modificação do cache
- Data de modificação do lock file
- Status de validade (Valid/Invalid)

**Exemplo:**

```bash
$ susa self cache info
[INFO] Informações do Cache:

Cache Directory: /run/user/1002/susa-user
Cache File: /run/user/1002/susa-user/lock.cache
Lock File: /home/user/.susa/susa.lock
Cache Loaded: 1
Cache Exists: Yes
Cache Size: 8.0K
Cache Modified: 2026-01-15 23:35:15 -0300
Lock File Exists: Yes
Lock File Modified: 2026-01-15 23:35:15 -0300
Cache Status: Valid
```

### refresh

Força a atualização do cache, regenerando-o a partir do arquivo `susa.lock`.

```bash
susa self cache refresh
```

**Quando usar:**

- Após modificar manualmente o arquivo `susa.lock`
- Quando suspeitar que o cache está corrompido
- Para forçar uma recarga dos dados

**Exemplo:**

```bash
$ susa self cache refresh
[INFO] 2026-01-16 16:15:27 - Atualizando cache...
[SUCCESS] 2026-01-16 16:15:27 - Cache atualizado com sucesso!
```

### clear

Remove o arquivo de cache. O cache será recriado automaticamente na próxima execução do CLI.

```bash
susa self cache clear
```

**Quando usar:**

- Para liberar espaço (embora o cache seja pequeno)
- Para resolver problemas de cache corrompido
- Durante troubleshooting

**Exemplo:**

```bash
$ susa self cache clear
[INFO] 2026-01-16 16:15:45 - Limpando cache...
[SUCCESS] 2026-01-16 16:15:45 - Cache removido com sucesso!
```

## Opções

- `-h, --help` - Mostra a mensagem de ajuda

## Descrição

O sistema de cache do SUSA CLI mantém uma cópia otimizada do arquivo `susa.lock` em memória e em disco para acelerar drasticamente o tempo de inicialização do CLI.

### Como Funciona

1. **Primeira execução**: O CLI lê o `susa.lock` e cria um cache em disco
2. **Execuções subsequentes**: O CLI carrega o cache pré-processado, que é muito mais rápido
3. **Atualização automática**: Se o `susa.lock` for modificado, o cache é regenerado automaticamente

### Localização do Cache

O cache é armazenado em:

```text
${XDG_RUNTIME_DIR:-/tmp}/susa-$USER/lock.cache
```

Este diretório é:

- Específico para cada usuário
- Temporário (limpo ao fazer logout em sistemas Linux)
- Protegido com permissões 700 (acesso apenas pelo usuário)

### Benefícios

- ⚡ **Inicialização instantânea**: Reduz o tempo de startup em ~75%
- 🔄 **Atualização automática**: Não requer manutenção manual
- 💾 **Cache inteligente**: Valida automaticamente se está desatualizado
- 🛡️ **Seguro**: Fallback para leitura direta se o cache falhar

## Exemplos

### Verificar o status do cache

```bash
susa self cache info
```

### Limpar e recriar o cache

```bash
susa self cache clear
susa self cache refresh
```

### Troubleshooting de problemas

```bash
# Se o CLI estiver lento ou com comportamento estranho
susa self cache clear
susa self lock  # Regenera o lock e o cache
```

## Atualização Automática

O cache é atualizado automaticamente quando:

- O comando `susa self lock` é executado
- O arquivo `susa.lock` é modificado (detectado automaticamente)
- Plugins são adicionados/removidos

Na maioria dos casos, você **não precisa** executar `susa self cache` manualmente.

## Notas

- O cache é totalmente transparente para o usuário
- Não há necessidade de configuração
- O sistema funciona tanto em Linux quanto em macOS
- Se o cache falhar, o CLI automaticamente usa o método tradicional (jq + lock file)

## Veja Também

- [susa self lock](lock.md) - Regenera o arquivo lock
- [Sistema de Cache](../../libraries/cache.md) - Documentação técnica do sistema de cache
