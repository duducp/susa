# Setup UV

Instala o UV (by Astral), um gerenciador de pacotes e projetos Python extremamente rápido, escrito em Rust. Substitui pip, pip-tools, pipx, poetry, pyenv, virtualenv e muito mais.

## O que é UV?

UV é uma ferramenta Python de próxima geração que oferece velocidade incomparável (10-100x mais rápida) e funcionalidade completa:

- **Extremamente Rápido**: Escrito em Rust, 10-100x mais rápido que pip
- **Gerenciador Completo**: Substitui pip, pip-tools, pipx, poetry, pyenv, virtualenv
- **Resolução Inteligente**: Resolver de dependências ultra-rápido
- **Lock Files**: Builds reproduzíveis com uv.lock
- **Compatibilidade**: Funciona com requirements.txt, pyproject.toml, etc.
- **Python Management**: Instala e gerencia versões do Python

**Por exemplo:**

```bash
# Tradicional (lento)
python -m venv .venv && source .venv/bin/activate && pip install requests
# ~30 segundos

# Com UV (ultra-rápido)
uv venv && uv pip install requests
# ~1 segundo ⚡
```

## Como usar

### Instalar

```bash
susa setup uv
```

O comando vai:

- Baixar o instalador oficial do UV
- Instalar o UV em `~/.local/bin`
- Configurar o PATH no seu shell (bash ou zsh)
- Verificar a instalação

Depois de instalar, reinicie o terminal ou execute:

```bash
source ~/.bashrc  # ou ~/.zshrc
```

### Atualizar

```bash
susa setup uv --upgrade
```

Atualiza o UV para a versão mais recente usando o comando `uv self update`.

### Desinstalar

```bash
susa setup uv --uninstall
```

Remove o UV do sistema. Você terá a opção de também remover o cache salvo em `~/.cache/uv`.

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `-u, --upgrade` | Atualiza o UV para a versão mais recente |
| `--uninstall` | Remove o UV do sistema |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída, desabilita mensagens de depuração |

## Guia Rápido de Uso

### Comandos Essenciais

**Criar Novo Projeto**

```bash
# Criar projeto com estrutura moderna
uv init meu-projeto
cd meu-projeto

# Ver estrutura criada
tree
```

**Gerenciar Dependências**

```bash
# Adicionar dependência
uv add requests

# Adicionar dependência de desenvolvimento
uv add --dev pytest black

# Adicionar com versão específica
uv add "django>=4.0,<5.0"

# Remover dependência
uv remove requests
```

**Ambiente Virtual**

```bash
# Criar virtualenv
uv venv

# Ativar (Linux/Mac)
source .venv/bin/activate

# Ou usar uv run (não precisa ativar)
uv run python script.py
uv run pytest
```

**Instalar Dependências**

```bash
# Instalar de pyproject.toml
uv sync

# Instalar de requirements.txt
uv pip install -r requirements.txt

# Instalar pacote específico
uv pip install requests
```

### Configuração Inicial

**1. Criar um Novo Projeto**

```bash
uv init meu-projeto
cd meu-projeto
```

Estrutura criada:

```
meu-projeto/
├── .python-version
├── pyproject.toml
├── README.md
└── hello.py
```

**2. Configurar pyproject.toml**

```toml
[project]
name = "meu-projeto"
version = "0.1.0"
description = "Meu projeto incrível"
readme = "README.md"
requires-python = ">=3.9"
dependencies = [
    "requests>=2.28.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.2.0",
    "black>=22.10.0",
    "ruff>=0.1.0",
]
```

**3. Instalar Dependências**

```bash
uv sync
```

Isso vai:
- Resolver todas as dependências
- Criar uv.lock (lock file)
- Criar ambiente virtual automaticamente
- Instalar todos os pacotes

## Recursos Avançados

### 1. Gerenciamento de Python

UV pode instalar e gerenciar versões do Python:

```bash
# Listar versões disponíveis
uv python list

# Instalar versão específica
uv python install 3.12

# Usar versão específica no projeto
uv python pin 3.12

# Ver versão ativa
uv python find
```

### 2. uvx - Executar Ferramentas sem Instalar

Execute ferramentas Python temporariamente:

```bash
# Executar ruff (linter)
uvx ruff check .

# Executar black (formatter)
uvx black .

# Executar mypy (type checker)
uvx mypy .

# Executar com versão específica
uvx ruff@0.1.0 check .
```

### 3. Workspaces (Monorepos)

Gerencie múltiplos pacotes em um único repositório:

```toml
# pyproject.toml (raiz)
[tool.uv.workspace]
members = ["packages/*"]

[tool.uv]
dev-dependencies = [
    "pytest>=7.0.0",
]
```

Estrutura:

```
meu-workspace/
├── pyproject.toml
└── packages/
    ├── api/
    │   └── pyproject.toml
    └── core/
        └── pyproject.toml
```

### 4. Grupos de Dependências

Organize dependências por contexto:

```toml
[project]
dependencies = [
    "requests>=2.28.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.2.0",
    "black>=22.10.0",
]
docs = [
    "mkdocs>=1.4.0",
    "mkdocs-material>=9.0.0",
]
```

Instalar grupos específicos:

```bash
# Instalar apenas dependências principais
uv sync

# Instalar com dev
uv sync --extra dev

# Instalar com docs
uv sync --extra docs

# Instalar todos os grupos
uv sync --all-extras
```

### 5. Scripts de Projeto

Defina scripts no pyproject.toml:

```toml
[project.scripts]
start = "meu_projeto.main:main"

[project.optional-dependencies]
dev = ["pytest", "black"]
```

Execute:

```bash
uv run start
uv run pytest
uv run black .
```

### 6. Compatibilidade com Poetry

Migrar de Poetry para UV é simples:

```bash
# Converter poetry.lock para uv.lock
uv sync

# UV lê pyproject.toml do Poetry
# Não precisa alterar estrutura!
```

Ou use modo de compatibilidade:

```bash
# Usar como poetry
uv run poetry install
uv run poetry add requests
```

## Comparação de Performance

### Instalação de Dependências

| Ferramenta | Tempo | Velocidade Relativa |
|------------|-------|---------------------|
| **uv** | 1.2s | **Baseline** ⚡ |
| pip | 42s | 35x mais lento |
| poetry | 58s | 48x mais lento |
| pipenv | 73s | 61x mais lento |

*Teste: Instalar Flask + SQLAlchemy + suas dependências*

### Resolução de Dependências

| Ferramenta | Tempo | Velocidade Relativa |
|------------|-------|---------------------|
| **uv** | 0.3s | **Baseline** ⚡ |
| poetry | 12s | 40x mais lento |
| pipenv | 18s | 60x mais lento |

### Criação de Virtualenv

| Ferramenta | Tempo |
|------------|-------|
| **uv venv** | 0.1s ⚡ |
| python -m venv | 2.5s |
| virtualenv | 1.8s |

## Integração com IDEs

### VS Code

Configure o Python interpreter:

1. Crie virtualenv com UV: `uv venv`
2. Abra Command Palette (Ctrl+Shift+P)
3. Digite "Python: Select Interpreter"
4. Escolha `.venv/bin/python`

Ou adicione ao `.vscode/settings.json`:

```json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python"
}
```

### PyCharm

1. Settings → Project → Python Interpreter
2. Add Interpreter → Existing Environment
3. Selecione: `{project}/.venv/bin/python`

## Migração de Outras Ferramentas

### De pip + venv

```bash
# Antes
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# Depois (muito mais rápido!)
uv venv
uv pip install -r requirements.txt
```

### De Poetry

```bash
# Manter pyproject.toml existente
# Simplesmente usar uv:
uv sync

# UV lê automaticamente:
# - [tool.poetry.dependencies]
# - [tool.poetry.group.*.dependencies]
```

### De Pipenv

```bash
# Converter Pipfile para requirements.txt
pipenv requirements > requirements.txt

# Usar UV
uv venv
uv pip install -r requirements.txt
```

## Workflows Comuns

### Desenvolvimento Local

```bash
# Setup inicial
uv venv
uv sync --extra dev

# Adicionar nova biblioteca
uv add nova-biblioteca

# Executar testes
uv run pytest

# Format código
uv run black .
uv run ruff check .

# Commit
git add uv.lock pyproject.toml
git commit -m "Add nova-biblioteca"
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

      - name: Install uv
        run: curl -LsSf https://astral.sh/uv/install.sh | sh

      - name: Install dependencies
        run: uv sync --extra dev

      - name: Run tests
        run: uv run pytest
```

### Docker

```dockerfile
FROM python:3.12-slim

# Instalar UV
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Copiar arquivos
COPY pyproject.toml uv.lock ./

# Instalar dependências
RUN uv sync --frozen --no-dev

# Copiar código
COPY . .

# Executar
CMD ["uv", "run", "python", "main.py"]
```

## Comandos UV vs Outras Ferramentas

### Comparação de Comandos

| Tarefa | UV | pip | poetry |
|--------|-----|-----|--------|
| **Instalar pacote** | `uv add requests` | `pip install requests` | `poetry add requests` |
| **Criar venv** | `uv venv` | `python -m venv .venv` | `poetry install` |
| **Instalar deps** | `uv sync` | `pip install -r requirements.txt` | `poetry install` |
| **Atualizar deps** | `uv lock --upgrade` | `pip install --upgrade` | `poetry update` |
| **Executar script** | `uv run python app.py` | `python app.py` | `poetry run python app.py` |
| **Adicionar dev dep** | `uv add --dev pytest` | `pip install pytest` | `poetry add -D pytest` |
| **Listar deps** | `uv pip list` | `pip list` | `poetry show` |
| **Congelar deps** | `uv pip freeze` | `pip freeze` | `poetry export` |

## Configurações Recomendadas

### Performance

```bash
# Cache de compilação
export UV_CACHE_DIR=~/.cache/uv

# Instalar pacotes pré-compilados (wheels)
export UV_PRERELEASE=disallow
```

### Ambiente Virtual

```bash
# Criar venv dentro do projeto
uv venv .venv

# Usar Python específico
uv venv --python 3.12

# Usar Python do sistema
uv venv --system-site-packages
```

### Configuração Global

Crie `~/.config/uv/uv.toml`:

```toml
[pip]
index-url = "https://pypi.org/simple"
extra-index-url = ["https://pypi.example.com/simple"]

[install]
compile-bytecode = true
```

## Troubleshooting

### UV comando não encontrado

```bash
# Verificar instalação
ls -la ~/.local/bin/uv

# Adicionar ao PATH manualmente
export PATH="$HOME/.local/bin:$PATH"

# Ou reinstalar
susa setup uv
```

### Dependências não resolvem

```bash
# Limpar cache
uv cache clean

# Forçar atualização do lock
uv lock --upgrade

# Reinstalar do zero
rm -rf .venv uv.lock
uv sync
```

### Virtualenv não é criado

```bash
# Criar manualmente
uv venv

# Verificar se foi criado
ls -la .venv

# Usar Python específico
uv venv --python 3.11
```

### Conflito com pip existente

```bash
# UV e pip podem coexistir
# Mas prefira usar uv pip:
uv pip install requests

# Em vez de:
pip install requests
```

### Performance não está rápida

```bash
# Verificar cache
du -sh ~/.cache/uv

# Limpar cache antigo
uv cache clean

# Usar wheels pré-compilados
uv pip install --no-build-isolation requests
```

## Recursos Avançados

### 1. Index Customizado

Use seu próprio PyPI:

```toml
[tool.uv]
index-url = "https://pypi.example.com/simple"
extra-index-url = [
    "https://download.pytorch.org/whl/cpu",
]
```

### 2. Resolver Offline

Trabalhe sem internet:

```bash
# Baixar dependências
uv pip download -r requirements.txt -d ./wheels

# Instalar offline
uv pip install --no-index --find-links ./wheels -r requirements.txt
```

### 3. Build de Pacotes

Compile seu próprio pacote:

```bash
# Build wheel e sdist
uv build

# Publicar no PyPI
uv publish
```

### 4. Pre-commit Integration

Adicione ao `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: local
    hooks:
      - id: uv-lock
        name: uv lock
        entry: uv lock
        language: system
        pass_filenames: false
```

## Compatibilidade

- **Python**: 3.8 ou superior
- **Sistema Operacional**: Linux, macOS, Windows
- **Formato**: pyproject.toml (PEP 621), requirements.txt, setup.py
- **Instalação**: Script oficial

## Comparação com Outras Ferramentas

| Recurso | UV | pip | poetry | pipenv | PDM |
|---------|-----|-----|--------|--------|-----|
| **Velocidade** | ⚡⚡⚡⚡⚡ | ⚡ | ⚡⚡ | ⚡ | ⚡⚡⚡ |
| **Gerencia Python** | ✅ | ❌ | ❌ | ❌ | ❌ |
| **Lock files** | ✅ | ❌ | ✅ | ✅ | ✅ |
| **Monorepos** | ✅ | ❌ | ❌ | ❌ | ✅ |
| **pip compatible** | ✅ | ✅ | ❌ | ❌ | ❌ |
| **Build/Publish** | ✅ | ❌ | ✅ | ❌ | ✅ |
| **Escrito em** | Rust | Python | Python | Python | Python |

## Links Úteis

- [Site Oficial](https://docs.astral.sh/uv/)
- [Documentação](https://docs.astral.sh/uv/getting-started/)
- [GitHub Repository](https://github.com/astral-sh/uv)
- [Blog Astral](https://astral.sh/blog)
- [Ruff (Linter)](https://docs.astral.sh/ruff/)
- [Issue Tracker](https://github.com/astral-sh/uv/issues)

## Próximos Passos

Depois de instalar o UV:

1. ✅ Crie seu primeiro projeto com `uv init`
2. ✅ Experimente `uvx` para executar ferramentas sem instalar
3. ✅ Migre projetos existentes (pip, poetry, pipenv)
4. ✅ Configure CI/CD com UV
5. ✅ Explore workspaces para monorepos
6. ✅ Use `uv python` para gerenciar versões do Python
7. ✅ Experimente a velocidade incomparável! ⚡

---

**Dica**: UV é mantido pela Astral, mesma empresa do Ruff (linter Python mais rápido). Use ambos para máxima performance! 🚀
