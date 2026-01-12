# Plugins Directory

Este diretório contém plugins externos instalados.

## Estrutura

Cada plugin deve seguir a estrutura:

```text
plugins/
├── registry.yaml              # Registro de plugins instalados
└── <nome-do-plugin>/
    └── <categoria>/
        └── <comando>/
            ├── config.yaml    # Configuração do comando
            └── main.sh        # Script principal
```

## Exemplo

```text
plugins/
├── registry.yaml
└── backup-tools/
    └── daily/
        └── backup-s3/
            ├── config.yaml
            └── main.sh
```

## Comandos Disponíveis

```bash
# Instalar plugin
cli self plugin install github.com/user/susa-plugin-name

# Listar plugins
cli self plugin list

# Atualizar plugin
cli self plugin update <plugin-name>

# Remover plugin
cli self plugin remove <plugin-name>
```
