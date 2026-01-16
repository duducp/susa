# Setup Mise

Instala o Mise (anteriormente rtx), um gerenciador de versões de ferramentas de desenvolvimento polyglot, escrito em Rust. É compatível com ASDF, mas oferece melhor performance e recursos adicionais.

## O que é Mise?

Mise é uma ferramenta moderna de gerenciamento de versões que combina o melhor de várias ferramentas:

- **Compatível com ASDF**: Usa os mesmos plugins do ASDF
- **Extremamente Rápido**: Escrito em Rust, muito mais rápido que ASDF
- **Task Runner**: Executa tarefas como Make, mas melhor
- **Env Management**: Gerencia variáveis de ambiente por projeto
- **Polyglot**: Suporta múltiplas linguagens em um único projeto
- **Versionamento Semântico**: Suporte nativo a ranges de versões

**Por exemplo:**

```bash
# Tradicional com ASDF
asdf plugin add nodejs
asdf install nodejs 20.0.0
asdf global nodejs 20.0.0

# Com Mise (mais simples e rápido) ⚡
mise use --global node@20
```

## Como usar

### Instalar

```bash
susa setup mise
```

O comando vai:

- Baixar o binário oficial do Mise
- Instalar em `~/.local/bin`
- Configurar o shell activation (bash ou zsh)
- Verificar a instalação

Depois de instalar, reinicie o terminal ou execute:

```bash
source ~/.bashrc  # ou ~/.zshrc
```

### Atualizar

```bash
susa setup mise --upgrade
```

Atualiza o Mise para a versão mais recente.

### Desinstalar

```bash
susa setup mise --uninstall
```

Remove o Mise do sistema. Você terá a opção de também remover o cache salvo em `~/.cache/mise`.

## Opções

| Opção | O que faz |
| --- | --- |
| `-h, --help` | Mostra ajuda detalhada |
| `-u, --upgrade` | Atualiza o Mise para a versão mais recente |
| `--uninstall` | Remove o Mise do sistema |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída, desabilita mensagens de depuração |

## Guia Rápido de Uso

### Comandos Essenciais

#### Instalar e Usar Ferramentas

```bash
# Instalar Node.js 20
mise use --global node@20

# Instalar Python 3.12
mise use --global python@3.12

# Instalar versão específica
mise install ruby@3.2.0

# Ver ferramentas instaladas
mise list
```

**Gerenciar Versões por Projeto**

```bash
# No diretório do projeto
mise use node@18 python@3.11

# Isso cria/atualiza .mise.toml
cat .mise.toml
```

**Configuração com .mise.toml**

```toml
[tools]
node = "20.10.0"
python = "3.12"
ruby = "latest"

[env]
NODE_ENV = "development"
API_KEY = "secret"
```

### Configuração Inicial

**1. Instalar Ferramentas Globais**

```bash
# Instalar Node.js globalmente
mise use --global node@20

# Instalar múltiplas ferramentas
mise use --global node@20 python@3.12 ruby@3.2
```

**2. Criar Projeto com Mise**

```bash
mkdir meu-projeto && cd meu-projeto

# Definir versões para o projeto
mise use node@18 python@3.11

# Ver configuração
cat .mise.toml
```

**3. Instalar de .mise.toml**

```bash
# Outras pessoas do time fazem:
mise install
```

## Recursos Avançados

### 1. Task Runner

Mise pode executar tasks como um Makefile moderno:

```toml
# .mise.toml
[tasks.dev]
run = "npm run dev"
description = "Start dev server"

[tasks.test]
run = "pytest tests/"
description = "Run tests"

[tasks.build]
run = [
  "npm run build",
  "python setup.py sdist"
]
description = "Build project"
```

Executar tasks:

```bash
# Listar tasks
mise tasks

# Executar task
mise run dev
mise run test
mise run build
```

### 2. Variáveis de Ambiente

Gerencie env vars por projeto:

```toml
[env]
NODE_ENV = "development"
DATABASE_URL = "postgresql://localhost/mydb"
API_KEY = { file = ".env.secret" }
PORT = 3000

[env.production]
NODE_ENV = "production"
DATABASE_URL = "postgresql://prod.example.com/mydb"
```

Usar:

```bash
# Automaticamente carregado no diretório
echo $NODE_ENV  # development

# Ou executar comando com env
mise exec -- node server.js
```

### 3. Aliases e Backends Customizados

```toml
[tools]
# Usar alias
node = "lts"  # Última versão LTS

# Backend customizado
terraform = "1.6"

[alias.node]
lts = "20"
current = "21"
```

### 4. Hooks e Scripts

Execute scripts em eventos:

```toml
[hooks]
enter = "echo 'Entrando no projeto'"
leave = "echo 'Saindo do projeto'"
preinstall = "echo 'Instalando dependências...'"
```

### 5. Templates

Use templates em configurações:

```toml
[env]
PROJECT_ROOT = "{{ cwd }}"
HOME_DIR = "{{ env.HOME }}"
TIMESTAMP = "{{ now() }}"
```

## Migração do ASDF

Mise é totalmente compatível com ASDF:

### Usar Plugins do ASDF

```bash
# Plugins ASDF funcionam diretamente
mise plugin add erlang
mise install erlang@26.0

# Ou use o registry do mise (mais rápido)
mise use erlang@26
```

### Migrar .tool-versions

```bash
# Mise lê .tool-versions automaticamente
cat .tool-versions
# nodejs 20.0.0
# python 3.12.0

# Funciona sem mudanças!
mise install
```

### Converter para .mise.toml

```bash
# Opcional: converter para formato nativo
mise use $(cat .tool-versions)
```

## Comparação de Performance

### Instalação de Ferramentas

| Ferramenta | Tempo | Velocidade Relativa |
|------------|-------|---------------------|
| **Mise** | 2.1s | **Baseline** ⚡ |
| ASDF | 8.5s | 4x mais lento |

### Ativação de Shell

| Ferramenta | Tempo |
|------------|-------|
| **Mise** | 5ms ⚡ |
| ASDF | 120ms |

### Resolução de Versões

| Ferramenta | Tempo |
|------------|-------|
| **Mise** | <1ms ⚡ |
| ASDF | 25ms |

## Integração com IDEs

### VS Code

Configure o workspace:

```json
{
  "terminal.integrated.env.linux": {
    "PATH": "${env:HOME}/.local/share/mise/shims:${env:PATH}"
  }
}
```

### PyCharm / IntelliJ

Use o Python/Node.js gerenciado pelo Mise:

```
Settings → Project → Python Interpreter
→ Add Interpreter → System Interpreter
→ ~/.local/share/mise/installs/python/3.12/bin/python
```

## Workflows Comuns

### Desenvolvimento Local

```bash
# Setup do projeto
cd meu-projeto
mise use node@20 python@3.12

# Instalar ferramentas
mise install

# Executar com ambiente correto
mise exec -- npm start

# Ou usar tasks
mise run dev
```

### CI/CD (GitHub Actions)

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Mise
        run: curl https://mise.run | sh

      - name: Install tools
        run: |
          mise install

      - name: Run tests
        run: mise run test
```

### Docker

```dockerfile
FROM ubuntu:22.04

# Instalar Mise
RUN curl https://mise.run | sh
ENV PATH="/root/.local/bin:$PATH"

# Copiar config
COPY .mise.toml ./

# Instalar ferramentas
RUN mise install

# Executar app
CMD ["mise", "exec", "--", "node", "server.js"]
```

## Comandos Mise vs ASDF

| Tarefa | Mise | ASDF |
|--------|------|------|
| **Instalar ferramenta** | `mise use node@20` | `asdf plugin add nodejs && asdf install nodejs 20.0.0` |
| **Listar versões** | `mise ls node` | `asdf list nodejs` |
| **Ver instaladas** | `mise list` | `asdf list` |
| **Desinstalar** | `mise uninstall node@18` | `asdf uninstall nodejs 18.0.0` |
| **Versão atual** | `mise current` | `asdf current` |
| **Onde está** | `mise where node` | `asdf where nodejs` |
| **Executar comando** | `mise exec -- node app.js` | `node app.js` |
| **Atualizar ferramenta** | `mise upgrade node` | `asdf install nodejs latest` |

## Configurações Recomendadas

### ~/.config/mise/config.toml

```toml
[settings]
experimental = true
verbose = false
asdf_compat = true  # Compatibilidade total com ASDF
legacy_version_file = true  # Ler .tool-versions

[alias.node]
lts = "20"
latest = "21"

[alias.python]
3 = "3.12"
```

### Por Projeto (.mise.toml)

```toml
[tools]
node = "20"
python = { version = "3.12", virtualenv = ".venv" }

[env]
NODE_ENV = "development"

[tasks.dev]
run = "npm run dev"

[tasks.test]
run = "npm test"
depends = ["lint"]

[tasks.lint]
run = "eslint ."
```

## Troubleshooting

### Mise comando não encontrado

```bash
# Verificar instalação
ls -la ~/.local/bin/mise

# Adicionar ao PATH
export PATH="$HOME/.local/bin:$PATH"

# Ou reinstalar
susa setup mise
```

### Ferramenta não encontrada após instalação

```bash
# Verificar se está instalada
mise list

# Reinstalar
mise install node@20

# Verificar shims
mise reshim
```

### Conflito com ASDF

```bash
# Desativar ASDF
# Remover do ~/.bashrc ou ~/.zshrc:
# eval "$(asdf activate bash)"

# Mise e ASDF podem coexistir, mas não use ambos ativos
```

### Performance lenta

```bash
# Limpar cache
mise cache clear

# Desabilitar plugins desnecessários
mise plugin uninstall <plugin>

# Usar versões pré-compiladas
mise settings set python_compile false
```

### Erro ao instalar ferramenta

```bash
# Ver logs detalhados
mise install node@20 --verbose

# Verificar dependências do sistema
mise doctor

# Forçar reinstalação
mise install node@20 --force
```

## Compatibilidade

- **Plugins**: 100% compatível com plugins ASDF
- **Arquivos**: Lê `.tool-versions`, `.node-version`, `.ruby-version`, etc.
- **Sistema Operacional**: Linux, macOS (Windows via WSL)
- **Shells**: bash, zsh, fish

## Comparação com Outras Ferramentas

| Recurso | Mise | ASDF | rtx (antigo) |
|---------|------|------|--------------|
| **Velocidade** | ⚡⚡⚡⚡⚡ | ⚡⚡ | ⚡⚡⚡⚡⚡ |
| **Plugins ASDF** | ✅ | ✅ | ✅ |
| **Task Runner** | ✅ | ❌ | ❌ |
| **Env Management** | ✅ | ❌ | ✅ |
| **Escrito em** | Rust | Shell | Rust |
| **Ativo** | ✅ | ✅ | ❌ (renomeado para Mise) |

## Links Úteis

- [Site Oficial](https://mise.jdx.dev/)
- [Documentação](https://mise.jdx.dev/getting-started.html)
- [GitHub Repository](https://github.com/jdx/mise)
- [Registry de Ferramentas](https://mise.jdx.dev/registry.html)
- [Comparação com ASDF](https://mise.jdx.dev/comparison-to-asdf.html)
- [Issue Tracker](https://github.com/jdx/mise/issues)

## Próximos Passos

Depois de instalar o Mise:

1. ✅ Instale ferramentas globais: `mise use --global node@20`
2. ✅ Configure um projeto: `mise use node@18 python@3.11`
3. ✅ Crie tasks: Adicione `[tasks.*]` no `.mise.toml`
4. ✅ Configure envvars: Defina `[env]` no `.mise.toml`
5. ✅ Migre do ASDF: Mise lê `.tool-versions` automaticamente
6. ✅ Configure CI/CD com Mise
7. ✅ Experimente a velocidade incomparável! ⚡

---

**Dica**: Mise foi anteriormente chamado de rtx. Se você usava rtx, pode migrar facilmente - é a mesma ferramenta com novo nome! 🚀
