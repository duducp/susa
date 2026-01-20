# Setup NordPass

Instala o NordPass, um gerenciador de senhas seguro e intuitivo para proteger suas credenciais.

## O que é NordPass?

NordPass é um gerenciador de senhas moderno que oferece armazenamento criptografado de senhas, cartões de crédito e notas seguras, com sincronização entre dispositivos.

**Principais recursos:**

- **Criptografia XChaCha20**: Segurança de ponta com algoritmo de criptografia avançado
- **Armazenamento seguro**: Senhas, cartões de crédito e notas protegidas
- **Sincronização multi-dispositivo**: Acesse suas senhas em todos os dispositivos
- **Gerador de senhas**: Crie senhas fortes e únicas automaticamente
- **Autopreenchimento**: Preencha formulários automaticamente
- **Verificação de vazamentos**: Receba alertas sobre dados vazados
- **Autenticação de dois fatores**: Camada extra de segurança

## Como usar

### Instalar

```bash
susa setup nordpass install
```

O comando vai:

- **Linux**: Instalar via Snap (`snap install nordpass`)
- **macOS**: Instalar via Homebrew (`brew install --cask nordpass`)
- Registrar a instalação no sistema SUSA

Depois de instalar, inicie o NordPass:

```bash
# Linux
snap run nordpass

# macOS
open '/Applications/NordPass.app'
```

Ou abra pelo menu de aplicativos do seu sistema.

### Atualizar

```bash
susa setup nordpass update
```

O comando vai:

1. Verificar a versão instalada
2. Buscar atualizações disponíveis
3. Atualizar para a versão mais recente
4. Atualizar o registro no sistema SUSA
5. Informar se já está na versão mais recente

### Desinstalar

```bash
susa setup nordpass uninstall
```

Com confirmação interativa para evitar remoção acidental. Use `-y` para pular:

```bash
susa setup nordpass uninstall -y
```

### Ver informações

```bash
susa setup nordpass --info
```

Exibe:

- Status de instalação
- Versão instalada
- Versão mais recente disponível

## Comandos Disponíveis

### Install

```bash
susa setup nordpass install [opções]
```

Instala o NordPass no sistema.

**Opções:**

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída |

### Update

```bash
susa setup nordpass update [opções]
```

Atualiza o NordPass para a versão mais recente.

**Opções:**

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída |

### Uninstall

```bash
susa setup nordpass uninstall [opções]
```

Remove o NordPass do sistema.

**Opções:**

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `-y, --yes` | Pula confirmação e desinstala automaticamente |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída |

## Guia Rápido de Uso

### Primeiro uso

1. **Inicie o NordPass**
   - Abra pelo menu de aplicativos
   - Ou use os comandos acima

2. **Crie ou faça login na sua conta**
   - Crie uma conta nova (gratuita ou premium)
   - Ou faça login se já tiver uma conta

3. **Configure a senha mestra**
   - A senha mestra protege seu cofre
   - **Importante**: Não perca esta senha!
   - Considere usar autenticação biométrica

### Tarefas Comuns

**1. Adicionar uma senha**

- Clique no botão **+ Add Item**
- Selecione **Password**
- Preencha:
  - Nome do site/serviço
  - URL
  - Nome de usuário
  - Senha (ou gere uma)
- Salve

**2. Gerar senha forte**

- Ao adicionar/editar senha
- Clique no ícone de **Gerador**
- Configure:
  - Comprimento
  - Caracteres especiais
  - Números e letras
- Clique em **Use Password**

**3. Autopreenchimento**

- Instale a extensão do navegador
- Faça login no site desejado
- O NordPass oferece preencher automaticamente
- Confirme e pronto!

**4. Compartilhar senhas**

- Selecione o item a compartilhar
- Clique em **Share**
- Digite o email do destinatário (deve ter NordPass)
- Defina permissões (visualizar ou editar)
- Envie

**5. Verificar vazamentos**

- Vá em **Data Breach Scanner**
- Verifique se suas senhas foram vazadas
- Atualize senhas comprometidas imediatamente

## Boas Práticas

### Segurança

1. **Senha mestra forte**
   - Use pelo menos 16 caracteres
   - Misture letras, números e símbolos
   - Não reutilize em outros serviços

2. **Autenticação de dois fatores**
   - Ative 2FA na sua conta NordPass
   - Use app autenticador (Google Authenticator, Authy)

3. **Senhas únicas**
   - Nunca reutilize senhas entre serviços
   - Use o gerador para criar senhas fortes

4. **Atualização regular**
   - Mantenha o NordPass atualizado
   - Execute `susa setup nordpass update` periodicamente

### Organização

1. **Use pastas**
   - Organize senhas por categorias
   - Exemplos: Trabalho, Pessoal, Financeiro

2. **Adicione notas**
   - Informações extras em cada item
   - Perguntas de segurança
   - Números de conta

3. **Adicione tags**
   - Facilita busca e organização
   - Exemplos: urgente, revisar, importante

## Diferenças entre planos

### Free (Gratuito)

- Senhas ilimitadas
- 1 dispositivo ativo
- Sincronização ilimitada
- Gerador de senhas
- Autenticação 2FA

### Premium

- Senhas ilimitadas
- 6 dispositivos ativos
- Verificação de vazamentos
- Scanner de data breach
- Compartilhamento de senhas
- Suporte prioritário
- Armazenamento de arquivos (3GB)

## Requisitos do Sistema

### Linux

- **Sistema**: Ubuntu 20.04+, Fedora 34+, ou equivalente
- **Snap**: Snapd instalado e habilitado
- **RAM**: Mínimo 2GB
- **Espaço**: ~200MB

### macOS

- **Sistema**: macOS 10.15 Catalina ou superior
- **Homebrew**: Instalado (o comando verifica automaticamente)
- **RAM**: Mínimo 2GB
- **Espaço**: ~150MB

## Solução de Problemas

### Linux: Snap não instalado

Se o Snap não estiver instalado:

```bash
# Ubuntu/Debian
sudo apt install snapd

# Fedora
sudo dnf install snapd

# Arch
sudo pacman -S snapd
sudo systemctl enable --now snapd.socket
```

### macOS: Homebrew não instalado

Se o Homebrew não estiver instalado:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### App não inicia

1. **Verificar instalação**

   ```bash
   susa setup nordpass --info
   ```

2. **Reinstalar**

   ```bash
   susa setup nordpass uninstall -y
   susa setup nordpass install
   ```

3. **Logs de erro** (Linux)

   ```bash
   snap logs nordpass
   ```

### Sincronização não funciona

1. Verifique conexão com internet
2. Faça logout e login novamente
3. Verifique se o plano permite múltiplos dispositivos

## Alternativas

Se o NordPass não atender suas necessidades, considere:

- **Bitwarden**: Open-source, gratuito
- **1Password**: Premium, para equipes
- **LastPass**: Freemium, interface web
- **KeePassXC**: Local, offline, open-source

## Veja também

- [Guia de Segurança](../../guides/security.md) - Práticas de segurança geral
- [Comandos Setup](./index.md) - Outros comandos de instalação
- [NordPass Website](https://nordpass.com) - Site oficial
