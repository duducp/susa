# Self Plugin List

Lista todos os plugins instalados no Susa CLI, mostrando suas informações e estatísticas.

## Como usar

```bash
susa self plugin list
```

## Como funciona

O comando lê as informações diretamente do arquivo `registry.json`, evitando varredura de diretórios:

- **Metadados em cache**: Quantidade de comandos e categorias são calculados durante a instalação
- **Performance**: Resposta instantânea mesmo com muitos plugins
- **Fallback**: Se um plugin não tiver metadados, faz varredura sob demanda
- **Dev mode**: Plugins em desenvolvimento são marcados com `[DEV]`

## O que mostra?

Para cada plugin instalado, exibe:

- **Nome** do plugin
- **Origem** (URL do repositório Git)
- **Versão** instalada
- **Número de comandos** disponíveis
- **Categorias** de comandos
- **Data de instalação**

## Exemplo de saída

```text
Plugins Instalados

📦 backup-tools
   Origem: https://github.com/usuario/susa-backup-tools
   Versão: 1.2.0
   Comandos: 4
   Categorias: backup, restore
   Instalado: 2026-01-10 14:30:00

📦 deploy-helpers
   Origem: https://github.com/usuario/susa-deploy-helpers
   Versão: 2.0.1
   Comandos: 6
   Categorias: deploy, rollback, status
   Instalado: 2026-01-08 09:15:30

Total: 2 plugins instalados
```

## Se não houver plugins

```text
ℹ Nenhum plugin instalado

Para instalar um plugin, use:
  susa self plugin add <git-url>

Exemplos:
  susa self plugin add https://github.com/usuario/plugin-name
  susa self plugin add usuario/plugin-name
```

## Opções

| Opção | O que faz |
|-------|-----------|
| `-v, --verbose` | Modo verbose (exibe logs de debug) |
| `-q, --quiet` | Modo silencioso (mínimo de output) |
| `-h, --help` | Mostra ajuda |

## Veja também

- [susa self plugin add](add.md) - Instalar novo plugin
- [susa self plugin update](update.md) - Atualizar plugin
- [susa self plugin remove](remove.md) - Remover plugin
