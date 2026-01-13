# Self Plugin Add

Instala um plugin a partir de um repositório Git, adicionando novos comandos ao Susa CLI.

## Como usar

### Usando URL completa do GitHub

```bash
susa self plugin add https://github.com/usuario/susa-plugin-name
```

### Usando formato user/repo

```bash
susa self plugin add usuario/susa-plugin-name
```

## O que acontece?

1. Verifica se o plugin já está instalado
2. Clona o repositório Git do plugin
3. Registra o plugin no sistema
4. Torna os comandos do plugin disponíveis imediatamente

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda |

## Requisitos

- Git instalado no sistema
- Conexão com a internet
- Plugin deve seguir a estrutura do Susa CLI

## Estrutura esperada do plugin

```
susa-plugin-name/
├── commands/
│   └── categoria/
│       ├── config.yaml
│       └── main.sh
```

## Exemplo de uso

```bash
# Instalar plugin de backup
susa self plugin add usuario/susa-backup-tools

# Após instalação, os comandos ficam disponíveis
susa backup criar
susa backup restaurar
```

## Se o plugin já estiver instalado

O comando mostra informações do plugin existente e sugere ações:

```
⚠ Plugin 'backup-tools' já está instalado

  Versão atual: 1.2.0
  Instalado em: 2026-01-10 14:30:00

Opções disponíveis:
  • Atualizar plugin:  susa self plugin update backup-tools
  • Remover plugin:    susa self plugin remove backup-tools
  • Listar plugins:    susa self plugin list
```

## Veja também

- [susa self plugin list](list.md) - Listar plugins instalados
- [susa self plugin update](update.md) - Atualizar um plugin
- [susa self plugin remove](remove.md) - Remover um plugin
- [Visão Geral de Plugins](../../../../plugins/overview.md) - Entenda o sistema de plugins
- [Arquitetura de Plugins](../../../../plugins/architecture.md) - Como funcionam os plugins
