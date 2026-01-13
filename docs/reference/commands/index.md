# Comandos

Referência completa de todos os comandos disponíveis no Susa CLI.

## Visão Geral

O Susa CLI organiza seus comandos em categorias hierárquicas, facilitando a navegação e descoberta de funcionalidades. Os comandos são descobertos automaticamente a partir da estrutura de diretórios em `commands/`.

## Categorias Principais

### [Self](self/index.md)

Comandos para gerenciamento e manutenção do próprio CLI, incluindo atualizações, informações do sistema, configuração de auto-complete e gerenciamento de plugins.

### [Setup](setup/index.md)

Comandos para configuração e instalação de ferramentas e ambientes de desenvolvimento, facilitando a preparação do ambiente de trabalho.

## Como Usar

Todos os comandos seguem a sintaxe:

```bash
susa [categoria] [subcategoria] [comando] [opções]
```

### Exemplos

```bash
# Ver informações do CLI
susa self info

# Atualizar o CLI
susa self update

# Instalar ASDF
susa setup asdf

# Gerenciar plugins
susa self plugin list
```

## Descoberta de Comandos

O sistema utiliza **discovery automático**, onde novos comandos são reconhecidos automaticamente ao serem adicionados na estrutura de diretórios. Cada comando pode ter:

- ✅ **Configuração YAML** - Define metadados, descrição e opções
- ✅ **Script de Execução** - Implementa a lógica do comando
- ✅ **Subcategorias** - Organização hierárquica ilimitada

## Navegação

Explore as seções abaixo para conhecer todos os comandos disponíveis e suas funcionalidades detalhadas.
