# Setup ASDF

Instala o ASDF, um gerenciador que permite usar várias versões de linguagens de programação no mesmo computador.

## O que é ASDF?

Imagine que você precisa trabalhar com diferentes projetos que usam versões diferentes de Node.js, Python ou Ruby. O ASDF permite instalar e alternar entre essas versões facilmente, sem conflitos.

**Por exemplo:**

- Projeto A usa Node.js 18
- Projeto B usa Node.js 20
- Com ASDF, ambos funcionam perfeitamente! ✨

## Como usar

### Instalar

```bash
susa setup asdf
```

Se o ASDF já estiver instalado, você receberá uma mensagem informando a versão atual. Para atualizar, use o comando `--upgrade`.

Depois de instalar, reinicie o terminal e pronto! 🎉

### Atualizar

```bash
susa setup asdf --upgrade
```

Atualiza o ASDF para a versão mais recente. Seus plugins e versões de ferramentas instaladas serão preservados.

### Desinstalar

```bash
susa setup asdf --uninstall
```

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda |
| `-u, --upgrade` | Atualiza para a versão mais recente |
| `--uninstall` | Remove o ASDF |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída, desabilita mensagens de depuração |

## Guia Rápido de Uso

Depois de instalar o ASDF, você pode instalar linguagens de programação. Veja como:

**1. Instalar Node.js (exemplo)**

```bash
# Adicionar plugin do Node.js
asdf plugin add nodejs

# Instalar última versão
asdf install nodejs latest

# Definir como versão padrão
asdf global nodejs latest

# Verificar
node --version
```

**2. Instalar Python (exemplo)**

```bash
# Adicionar plugin do Python
asdf plugin add python

# Instalar versão específica
asdf install python 3.11.0

# Definir como versão padrão
asdf global python 3.11.0
```

**3. Ver todas as linguagens disponíveis**

```bash
asdf plugin list all
```

## Linguagens Disponíveis

Você pode instalar várias linguagens e ferramentas:

| Linguagem | Para que serve | Como adicionar |
|-----------|----------------|----------------|
| **Node.js** | JavaScript no servidor | `asdf plugin add nodejs` |
| **Python** | Ciência de dados, automação | `asdf plugin add python` |
| **Ruby** | Desenvolvimento web | `asdf plugin add ruby` |
| **Java** | Apps empresariais | `asdf plugin add java` |
| **Go** | APIs e serviços | `asdf plugin add golang` |
| **PHP** | Sites dinâmicos | `asdf plugin add php` |

## Perguntas Frequentes

### 💡 Preciso desinstalar meu Node.js atual?

Não! O ASDF funciona em paralelo. Você pode manter sua instalação atual.

### 💡 Como trocar de versão em um projeto específico?

Dentro da pasta do projeto:

```bash
asdf local nodejs 18.0.0
```

Isso cria um arquivo `.tool-versions` que o ASDF lê automaticamente.

### 💡 E se eu já tiver Node.js instalado?

Sem problemas! O ASDF não interfere na instalação existente.

## Problemas Comuns

### ❌ "Comando não encontrado" após instalar

**Solução:** Reinicie o terminal ou execute:

```bash
source ~/.bashrc  # no Bash
source ~/.zshrc   # no Zsh
```

### ❌ Erro ao instalar uma linguagem

**Solução:** Pode faltar alguma dependência do sistema. Exemplo para Node.js no Ubuntu:

```bash
sudo apt install build-essential
```

## Recursos Externos

- [Documentação oficial do ASDF](https://asdf-vm.com/)
- [Lista de plugins disponíveis](https://github.com/asdf-vm/asdf-plugins)
- [Repositório do ASDF no GitHub](https://github.com/asdf-vm/asdf)

## Veja Também

- [susa self plugin add](../self/plugins/add.md) - Adicionar plugins ao Susa CLI
- [Bibliotecas disponíveis](../../libraries/index.md) - Referência de bibliotecas do Susa
Quer saber mais?

- 📖 [Documentação oficial do ASDF](https://asdf-vm.com/)
- 🔌 [Todos os plugins disponíveis](https://github.com/asdf-vm/asdf-plugins)

## Compatibilidade

Funciona em:

- ✅ Linux (Ubuntu, Debian, Fedora, etc.)
- ✅ macOS
