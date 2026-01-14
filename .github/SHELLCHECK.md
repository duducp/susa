# ShellCheck Integration

## Instalação

### Linux (Debian/Ubuntu)

```bash
sudo apt install shellcheck
```

### Linux (Fedora/RHEL)

```bash
sudo dnf install shellcheck
```

### macOS

```bash
brew install shellcheck
```

### Verificar instalação

```bash
shellcheck --version
```

## Uso Local

### Via Makefile (recomendado)

```bash
# Executar ShellCheck em todos os scripts
make shellcheck

# Ou usar o alias
make lint

# Executar todos os testes
make test
```

### Manualmente

```bash
# Verificar um arquivo específico
shellcheck core/susa

# Verificar múltiplos arquivos
shellcheck core/lib/*.sh

# Verificar todos os comandos
find commands -name "*.sh" -exec shellcheck {} \;
```

## Configuração

O arquivo `.shellcheckrc` na raiz do projeto contém as configurações:

- **Shell padrão**: bash
- **Severidade mínima**: warning
- **Checks desabilitados**:
  - `SC1090`: Can't follow non-constant source (sourcing dinâmico)
  - `SC1091`: Not following: arquivo não encontrado (dependências externas)

## CI/CD - GitHub Actions

A verificação automática é executada em:

- ✅ Push para branches `main` e `develop`
- ✅ Pull Requests para `main` e `develop`
- ✅ Execução manual via workflow_dispatch

### Jobs do CI

1. **ShellCheck**: Verifica todos os scripts shell
   - Core files (`core/susa`)
   - Bibliotecas (`core/lib/**/*.sh`)
   - Comandos (`commands/**/*.sh`)

2. **Lint**: Verificações de qualidade de código
   - Trailing whitespaces
   - Estilo de código

3. **Summary**: Resumo final dos checks

## Verificando antes de Commit

Para garantir que seu código passa no CI:

```bash
# Executar todos os checks localmente
make test

# Ou apenas o shellcheck
make shellcheck
```

## Corrigindo Problemas

Quando o ShellCheck encontrar problemas:

1. **Leia a mensagem**: ShellCheck fornece código do erro (ex: SC2086)
2. **Consulte a wiki**: https://www.shellcheck.net/wiki/SC2086
3. **Corrija o código**: Siga as sugestões
4. **Teste novamente**: `make shellcheck`

## Exemplos de Problemas Comuns

### Variáveis sem aspas

```bash
# ❌ Errado
echo $USER

# ✅ Correto
echo "$USER"
```

### Comparações

```bash
# ❌ Errado
if [ $x = "test" ]; then

# ✅ Correto
if [ "$x" = "test" ]; then
```

### Exit code

```bash
# ❌ Errado
command
if [ $? -eq 0 ]; then

# ✅ Correto
if command; then
```

## Desabilitar Checks Específicos

Se necessário, desabilite checks específicos com comentários:

```bash
# shellcheck disable=SC2086
echo $var

# Ou para múltiplos checks
# shellcheck disable=SC2086,SC2181
```

## Links Úteis

- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [Lista de Checks](https://github.com/koalaman/shellcheck/wiki/Checks)
- [GitHub Action](https://github.com/ludeeus/action-shellcheck)
