# Self Plugin Update

Atualiza um plugin instalado para a versão mais recente disponível no repositório de origem.

## Como usar

```bash
susa self plugin update <nome-do-plugin>
```

## Exemplo

```bash
susa self plugin update backup-tools
```

## Como funciona?

1. Verifica se o plugin existe
2. Busca a URL de origem no registry
3. Cria backup da versão atual
4. Clona a nova versão do repositório
5. Substitui os arquivos pelo backup
6. Atualiza o registro no sistema

## Processo de atualização

```
ℹ Atualizando plugin: backup-tools
  Origem: https://github.com/usuario/susa-backup-tools

Deseja continuar? (s/N): s

ℹ Criando backup...
ℹ Baixando atualização...
ℹ Instalando nova versão...

✓ Plugin 'backup-tools' atualizado com sucesso!
  Versão anterior: 1.2.0
  Nova versão: 1.3.0
  Comandos atualizados: 4
```

## Requisitos

- Plugin deve ter sido instalado via `susa self plugin add`
- Git instalado no sistema
- Conexão com a internet

## Se houver erro na atualização

O backup é **automaticamente restaurado** se algo der errado:

```
✗ Erro ao atualizar plugin

↺ Restaurando backup da versão anterior...
✓ Plugin restaurado para versão 1.2.0
```

## Plugins que não podem ser atualizados

Plugins instalados **manualmente** (sem Git) não têm origem registrada:

```
✗ Plugin 'local-plugin' não tem origem registrada ou é local

Apenas plugins instalados via Git podem ser atualizados
```

## Confirmação obrigatória

O comando sempre pede confirmação antes de atualizar. Para cancelar, pressione `N` ou `Enter`.

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda |

## Veja também

- [susa self plugin list](list.md) - Ver versões dos plugins instalados
- [susa self plugin add](add.md) - Instalar novo plugin
- [susa self plugin remove](remove.md) - Remover plugin
