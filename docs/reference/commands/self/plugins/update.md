# Self Plugin Update

Atualiza um plugin instalado para a versão mais recente disponível no repositório de origem.

Suporta **GitHub**, **GitLab** e **Bitbucket**. O provedor é detectado automaticamente da URL registrada.

## Como usar

```bash
susa self plugin update <nome-do-plugin> [opções]
```

## Exemplos

```bash
# Plugin público
susa self plugin update backup-tools

# Atualizar sem confirmação (modo automático)
susa self plugin update backup-tools -y

# Plugin privado (força SSH)
susa self plugin update private-plugin --ssh

# Combinar opções: auto-confirmar + SSH
susa self plugin update private-plugin -y --ssh
```

### Detecção automática do diretório atual

Se você estiver dentro do diretório de um **plugin em modo desenvolvimento** e não passar o nome do plugin, o comando **automaticamente** detecta qual plugin atualizar:

```bash
# Dentro do diretório do plugin dev
cd ~/projetos/meu-plugin
susa self plugin update
# Detecta automaticamente 'meu-plugin'

# Funciona com flags
susa self plugin update -y
susa self plugin update --verbose
```

**Nota:** Para plugins dev, "atualizar" significa regenerar o arquivo susa.lock para refletir mudanças nas categorias/comandos.

## Como funciona?

1. Verifica se o plugin existe
2. Busca a URL de origem no registry
3. Valida acesso ao repositório
4. Cria backup da versão atual
5. Clona a nova versão do repositório
6. Valida estrutura do plugin (inclui suporte ao campo `directory`)
7. Substitui os arquivos antigos pela nova versão
8. Atualiza o registro no sistema com metadados atualizados
9. Regenera o arquivo `susa.lock` para refletir mudanças

**Nota:** O sistema detecta automaticamente se o plugin usa o campo `directory` no `plugin.json` e busca os comandos no local correto.

## Processo de atualização

```text
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

```text
✗ Erro ao atualizar plugin

↺ Restaurando backup da versão anterior...
✓ Plugin restaurado para versão 1.2.0
```

## Plugins que não podem ser atualizados

### Plugins Manuais (Sem Git)

Plugins instalados **manualmente** (sem Git) não têm origem registrada:

```text
✗ Plugin 'local-plugin' não tem origem registrada ou é local

Apenas plugins instalados via Git podem ser atualizados
```

### Plugins em Modo Desenvolvimento

Plugins instalados com caminho local (modo dev) **não precisam** ser atualizados, pois as alterações no código já refletem automaticamente:

```text
✗ Plugin 'meu-plugin' está em modo desenvolvimento

Plugins em modo desenvolvimento não podem ser atualizados.
As alterações no código já refletem imediatamente!

Local do plugin: /home/usuario/projetos/meu-plugin
```

**Por quê?**

Plugins dev apontam para o diretório local. Qualquer alteração nos arquivos é refletida instantaneamente sem necessidade de atualização.

**Como funciona?**

```bash
# Plugin instalado em modo dev
cd ~/projetos/meu-plugin
susa self plugin add .

# Editar código
vim tools/hello/main.sh

# Testar - mudanças já estão ativas!
susa tools hello
```

## Confirmação

Por padrão, o comando pede confirmação antes de atualizar. Para cancelar, pressione `N` ou `Enter`.

Para **pular a confirmação** e atualizar automaticamente, use `-y` ou `--yes`:

```bash
# Atualiza automaticamente sem pedir confirmação
susa self plugin update backup-tools -y
```

Útil para scripts e automações.

## Opções

| Opção | O que faz |
|-------|-----------|
| `-y, --yes` | Pula confirmação e atualiza automaticamente |
| `--ssh` | Força uso de SSH (recomendado para repos privados) |
| `-v, --verbose` | Modo verbose (exibe logs de debug) |
| `-q, --quiet` | Modo silencioso (mínimo de output) |
| `-h, --help` | Mostra ajuda |

## Repositórios Privados

### Validação de Acesso

Antes de atualizar, o comando valida se você ainda tem acesso ao repositório:

```text
[ERROR] Não foi possível acessar o repositório

Possíveis causas:
  • Repositório foi removido ou renomeado
  • Você perdeu acesso ao repositório privado
  • Credenciais Git não estão mais válidas

Soluções:
  • Verifique se o repositório ainda existe
  • Use --ssh se for repositório privado
  • Reconfigure suas credenciais Git
```

### Forçar SSH

Para plugins privados, use `--ssh` para garantir autenticação SSH:

```bash
susa self plugin update organization/private-plugin --ssh
```

### Detecção Automática

O comando detecta automaticamente se você tem SSH configurado e usa quando disponível. A URL do registry é normalizada com base nas suas configurações.

## Veja também

- [susa self plugin list](list.md) - Ver versões dos plugins instalados
- [susa self plugin add](add.md) - Instalar novo plugin (inclui guia SSH)
- [susa self plugin remove](remove.md) - Remover plugin
