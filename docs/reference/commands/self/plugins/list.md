# Self Plugin List

Lista todos os plugins instalados no Susa CLI em formato de tabela compacta.

## Como usar

```bash
# Listar todos os plugins
susa self plugin list

# Ver detalhes de um plugin específico
susa self plugin list --detail <nome>
```

## Como funciona

O comando lê as informações diretamente do arquivo `registry.json`, evitando varredura de diretórios:

- **Metadados em cache**: Quantidade de comandos e categorias são calculados durante a instalação
- **Performance**: Resposta instantânea mesmo com muitos plugins
- **Fallback**: Se um plugin não tiver metadados, faz varredura sob demanda
- **Dev mode**: Plugins em desenvolvimento são marcados com `[DEV]`

## O que mostra?

### Listagem geral

Exibe uma tabela com todos os plugins instalados:

- **#** - Número sequencial
- **Nome** - Nome do plugin (com indicador `[DEV]` se for local)
- **Versão** - Versão instalada
- **Comandos** - Quantidade de comandos disponíveis
- **Categorias** - Quantidade de categorias
- **Origem** - "Local" (dev) ou "Remoto" (GitHub)

### Detalhes de um plugin

Ao usar `--detail <nome>`, mostra informações completas:

- Descrição do plugin
- Versão instalada
- URL de origem completa
- Tipo (Local/Remoto)
- Quantidade de comandos
- Lista completa de categorias
- Data de instalação

## Exemplo de saída

### Listagem geral

```text
Plugins Instalados

  #  Nome           Versão  Comandos  Categorias  Origem
  1  backup-tools   1.2.0   4         2           Remoto
  2  dev-plugin     0.1.0   2         1           Local

Total: 2 plugin(s)
```

### Detalhes de um plugin

```text
📦 backup-tools

Descrição: Ferramentas de backup e restore
Versão: 1.2.0
Origem: https://github.com/usuario/susa-backup-tools
Tipo: Remoto
Comandos: 4
Categorias: backup, restore
Instalado em: 2026-01-10T14:30:00Z
```

## Se não houver plugins

```text
ℹ Nenhum plugin instalado

Para instalar plugins, use: susa self plugin add <url>
```

## Opções

| Opção | O que faz |
|-------|-----------|
| `--detail <plugin>` | Exibe detalhes completos de um plugin específico |
| `-v, --verbose` | Modo verbose (exibe logs de debug) |
| `-q, --quiet` | Modo silencioso (mínimo de output) |
| `-h, --help` | Mostra ajuda |

## Exemplos

```bash
# Listar todos os plugins
susa self plugin list

# Ver detalhes do plugin "backup-tools"
susa self plugin list --detail backup-tools

# Modo verbose
susa self plugin list --verbose
```

## Veja também

- [susa self plugin add](add.md) - Instalar novo plugin
- [susa self plugin update](update.md) - Atualizar plugin
- [susa self plugin remove](remove.md) - Remover plugin
