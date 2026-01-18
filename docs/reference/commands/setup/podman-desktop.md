# Setup Podman Desktop

Instala o Podman Desktop, uma interface gráfica moderna para gerenciar containers, imagens e pods Podman.

## O que é Podman Desktop?

Podman Desktop é uma aplicação desktop que oferece uma experiência visual amigável para trabalhar com containers Podman, sem necessidade de linha de comando. É uma alternativa ao Docker Desktop.

**Principais recursos:**

- **Interface gráfica moderna**: Gerenciamento visual de containers, imagens e pods
- **Multiplataforma**: Funciona no Linux, macOS e Windows
- **Open-source**: Software livre e gratuito
- **Integração com Podman**: Usa o Podman como backend
- **Gerenciamento de imagens**: Construir, baixar e gerenciar imagens de container
- **Pods Kubernetes**: Criar e gerenciar pods localmente

## Como usar

### Instalar

```bash
susa setup podman-desktop
```

O comando vai:

- **Linux**: Baixar e instalar o binário em `/usr/local/bin/podman-desktop`
- **macOS**: Baixar o DMG e instalar em `/Applications/Podman Desktop.app`
- Registrar a instalação no sistema SUSA

Depois de instalar, inicie o Podman Desktop:

```bash
# Linux
podman-desktop

# macOS
open '/Applications/Podman Desktop.app'
```

### Atualizar

```bash
susa setup podman-desktop --upgrade
```

O comando vai:

1. Verificar a versão instalada e a versão mais recente disponível
2. Baixar e instalar a versão mais recente do GitHub
3. Substituir a versão antiga pela nova
4. Atualizar o registro no sistema SUSA
5. Informar se já está na versão mais recente

### Desinstalar

```bash
susa setup podman-desktop --uninstall
```

Com confirmação interativa para evitar remoção acidental. Use `-y` para pular:

```bash
susa setup podman-desktop --uninstall -y
```

### Ver informações

```bash
susa setup podman-desktop --info
```

Exibe:
- Status de instalação
- Versão instalada
- Versão mais recente disponível
- Localização do binário

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `--info` | Exibe informações sobre a instalação |
| `-u, --upgrade` | Atualiza para a versão mais recente |
| `--uninstall` | Remove o Podman Desktop do sistema |
| `-y, --yes` | Pula confirmação (usar com --uninstall) |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída |

## Guia Rápido de Uso

### Primeiro uso

1. **Inicie o Podman Desktop**
   ```bash
   podman-desktop  # Linux
   ```

2. **Configure o backend Podman**
   - O app vai detectar automaticamente a instalação do Podman
   - Se não tiver Podman instalado, ele oferece opções de instalação

3. **Explore a interface**
   - **Dashboard**: Visão geral dos containers em execução
   - **Images**: Gerenciar imagens de container
   - **Containers**: Listar, iniciar, parar containers
   - **Pods**: Criar e gerenciar pods Kubernetes
   - **Volumes**: Gerenciar volumes de dados

### Tarefas Comuns

**1. Executar um container**

- Vá em **Images** → Busque uma imagem (ex: `nginx`)
- Clique em **Pull** para baixar
- Clique com botão direito → **Run**
- Configure portas e variáveis de ambiente
- Clique em **Start Container**

**2. Gerenciar containers em execução**

- Vá em **Containers**
- Visualize logs, terminal, estatísticas
- Pare, reinicie ou remova containers

**3. Criar um pod**

- Vá em **Pods** → **Create Pod**
- Adicione containers ao pod
- Configure rede e volumes compartilhados

**4. Construir imagem de um Dockerfile**

- Vá em **Images** → **Build**
- Selecione o Dockerfile
- Configure tags e build args
- Clique em **Build**

## Pré-requisitos

### Linux

- **Podman instalado**: `susa setup podman` ou instalação manual
- **Permissões**: Pode precisar de `sudo` para instalação

### macOS

- **Podman Machine**: O Podman Desktop pode configurar automaticamente
- **Rosetta 2**: Para Macs Apple Silicon (M1/M2/M3)

## Comparação com Docker Desktop

| Recurso | Podman Desktop | Docker Desktop |
|---------|----------------|----------------|
| Licença | Open-source (Apache 2.0) | Grátis para uso pessoal |
| Backend | Podman (sem daemon) | Docker Engine (com daemon) |
| Pods Kubernetes | ✅ Nativo | ❌ Não suporta |
| Rootless | ✅ Sim | ⚠️ Experimental |
| Compatibilidade Docker | ✅ Alta | ✅ Total |
| Interface gráfica | ✅ Moderna | ✅ Moderna |

## Integração com VS Code

O Podman Desktop se integra bem com extensões do VS Code:

1. Instale a extensão **Docker** ou **Podman** no VS Code
2. Configure para usar Podman como backend
3. Gerencie containers diretamente do editor

## Troubleshooting

### Podman não detectado

```bash
# Verifique se Podman está instalado
podman --version

# Se não estiver, instale:
susa setup podman
```

### Erro de permissões (Linux)

```bash
# Adicione seu usuário ao grupo podman
sudo usermod -aG podman $USER

# Reinicie a sessão
newgrp podman
```

### Interface não inicia

```bash
# Tente iniciar com verbose para ver erros
podman-desktop --verbose

# Ou verifique logs do sistema
journalctl -u podman-desktop  # Linux
```

## Exemplos

```bash
# Instalar Podman Desktop
susa setup podman-desktop

# Ver informações da instalação
susa setup podman-desktop --info

# Atualizar para última versão
susa setup podman-desktop --upgrade

# Desinstalar (com confirmação)
susa setup podman-desktop --uninstall

# Desinstalar sem confirmação
susa setup podman-desktop --uninstall -y

# Modo verbose para debug
susa setup podman-desktop --verbose
```

## Recursos Adicionais

- [Site oficial](https://podman-desktop.io/)
- [Documentação](https://podman-desktop.io/docs)
- [GitHub Repository](https://github.com/podman-desktop/podman-desktop)
- [Tutorials](https://podman-desktop.io/docs/tutorials)

## Veja também

- [susa setup podman](podman.md) - Instalar o Podman CLI
- [susa setup docker](docker.md) - Alternativa: Docker Engine
