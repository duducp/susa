# Docker

Instala e configura o Docker CLI e Engine para gerenciamento de containers.

## O que é Docker?

Docker é a plataforma líder mundial em containers, permitindo que desenvolvedores empacotem aplicações e suas dependências em containers portáteis que podem ser executados em qualquer ambiente que suporte Docker. Esta instalação inclui apenas o Docker CLI e Engine, sem o Docker Desktop.

### Características Principais

- **Portabilidade**: Containers funcionam consistentemente em qualquer ambiente
- **Isolamento**: Aplicações rodam isoladas umas das outras
- **Eficiência**: Containers compartilham o kernel do sistema operacional
- **Velocidade**: Inicialização rápida comparada a máquinas virtuais
- **Ecosistema Rico**: Docker Hub com milhões de imagens prontas

### Docker vs Podman

| Característica | Docker | Podman |
| --- | --- | --- |
| Arquitetura | Cliente-servidor (daemon) | Daemon-less |
| Permissões | Requer grupo docker | Rootless nativo |
| Compatibilidade | Padrão da indústria | Compatível com Docker |
| Compose | docker-compose | podman-compose |
| Desktop | Docker Desktop disponível | Sem interface gráfica oficial |

## Uso

```bash
susa setup docker [opções]
```

### Opções

| Opção | Descrição |
| --- | --- |
| `-h, --help` | Mostra mensagem de ajuda |
| `--uninstall` | Desinstala o Docker |
| `--update` | Atualiza para a versão mais recente |
| `-v, --verbose` | Modo detalhado com logs de debug |
| `-q, --quiet` | Modo silencioso |

## Guia Rápido

### Instalação

```bash
# Instalar Docker
susa setup docker

# Instalar com logs detalhados
susa setup docker -v
```

### Pós-Instalação

Após a instalação, faça logout e login novamente para que as permissões do grupo docker sejam aplicadas, ou execute:

```bash
newgrp docker
```

### Verificar Instalação

```bash
# Verificar versão
docker --version

# Testar com hello-world
docker run hello-world

# Verificar informações do sistema
docker info
```

### Atualização

```bash
# Atualizar Docker
susa setup docker --update

# Atualizar com logs detalhados
susa setup docker --update -v
```

### Desinstalação

```bash
# Desinstalar Docker
susa setup docker --uninstall

# A desinstalação irá perguntar se deseja:
# 1. Confirmar remoção do Docker
# 2. Remover imagens, containers e volumes
```

## Primeiros Passos com Docker

### Executar Primeiro Container

```bash
# Hello World
docker run hello-world

# Container interativo Ubuntu
docker run -it ubuntu bash

# Servidor web Nginx
docker run -d -p 8080:80 nginx
```

### Gerenciar Imagens

```bash
# Listar imagens
docker images

# Baixar imagem
docker pull ubuntu:22.04

# Remover imagem
docker rmi ubuntu:22.04

# Limpar imagens não utilizadas
docker image prune -a
```

### Gerenciar Containers

```bash
# Listar containers em execução
docker ps

# Listar todos os containers
docker ps -a

# Parar container
docker stop <container-id>

# Remover container
docker rm <container-id>

# Limpar containers parados
docker container prune
```

### Docker Compose

O Docker Compose é instalado automaticamente como plugin:

```bash
# Verificar instalação
docker compose version

# Iniciar serviços
docker compose up -d

# Parar serviços
docker compose down

# Ver logs
docker compose logs -f
```

## Recursos Avançados

### Construir Imagens

Criar um `Dockerfile`:

```dockerfile
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    git \
    vim

WORKDIR /app
COPY . .

CMD ["bash"]
```

Construir e executar:

```bash
# Construir imagem
docker build -t minha-imagem .

# Executar container
docker run -it minha-imagem
```

### Volumes e Persistência

```bash
# Criar volume
docker volume create meu-volume

# Usar volume em container
docker run -v meu-volume:/data ubuntu

# Bind mount (mapear diretório local)
docker run -v $(pwd):/app ubuntu

# Listar volumes
docker volume ls

# Remover volumes não utilizados
docker volume prune
```

### Redes

```bash
# Listar redes
docker network ls

# Criar rede
docker network create minha-rede

# Conectar container à rede
docker run --network minha-rede ubuntu

# Inspecionar rede
docker network inspect minha-rede
```

### Multi-stage Builds

Otimizar tamanho de imagens:

```dockerfile
# Stage de build
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage de produção
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]
```

### Health Checks

```dockerfile
FROM nginx:alpine

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost/ || exit 1

COPY index.html /usr/share/nginx/html/
```

## Exemplo: Aplicação Full-Stack

### docker-compose.yml

```yaml
version: '3.8'

services:
  frontend:
    build: ./frontend
    ports:
      - "3000:3000"
    depends_on:
      - backend
    environment:
      - REACT_APP_API_URL=http://localhost:5000

  backend:
    build: ./backend
    ports:
      - "5000:5000"
    depends_on:
      - database
    environment:
      - DATABASE_URL=postgresql://user:pass@database:5432/mydb

  database:
    image: postgres:15
    volumes:
      - db-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
      - POSTGRES_DB=mydb

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"

volumes:
  db-data:
```

Executar:

```bash
# Iniciar todos os serviços
docker compose up -d

# Ver logs
docker compose logs -f

# Parar todos os serviços
docker compose down

# Remover volumes também
docker compose down -v
```

## Configurações no macOS

No macOS, o Docker requer uma máquina virtual para executar containers Linux. Recomendamos usar **colima**:

```bash
# Instalar colima
brew install colima

# Iniciar colima
colima start

# Verificar status
colima status

# Parar colima
colima stop

# Configurar recursos
colima start --cpu 4 --memory 8
```

## Integração com IDEs

### Visual Studio Code

Instale a extensão oficial:

```bash
code --install-extension ms-azuretools.vscode-docker
```

Recursos:

- Visualizar containers e imagens
- Build e run com um clique
- Logs em tempo real
- Attach ao container para debug

### JetBrains IDEs

Suporte nativo ao Docker em:

- IntelliJ IDEA
- PyCharm
- WebStorm
- GoLand

Configurar em: **Settings → Build, Execution, Deployment → Docker**

## Melhores Práticas

### Segurança

```bash
# Não executar containers como root quando possível
docker run --user 1000:1000 ubuntu

# Limitar recursos
docker run --memory="512m" --cpus="1.0" ubuntu

# Modo read-only
docker run --read-only ubuntu

# Usar imagens oficiais e verificadas
docker pull ubuntu:22.04
```

### Performance

```bash
# Usar .dockerignore
echo "node_modules" > .dockerignore
echo ".git" >> .dockerignore
echo "*.log" >> .dockerignore

# Multi-stage builds para reduzir tamanho
# Cache de layers - comandos que mudam pouco no início
# Combinar comandos RUN para reduzir layers
```

### Limpeza

```bash
# Limpar tudo não utilizado
docker system prune -a

# Limpar apenas containers parados
docker container prune

# Limpar apenas imagens não utilizadas
docker image prune

# Limpar apenas volumes não utilizados
docker volume prune

# Ver espaço utilizado
docker system df
```

## Troubleshooting

### Permissões Negadas

Se receber erro de permissão:

```bash
# Verificar se está no grupo docker
groups

# Adicionar ao grupo (feito automaticamente na instalação)
sudo usermod -aG docker $USER

# Aplicar mudanças
newgrp docker

# Ou fazer logout/login
```

### Container não Inicia

```bash
# Ver logs do container
docker logs <container-id>

# Modo interativo para debug
docker run -it <imagem> bash

# Inspecionar container
docker inspect <container-id>
```

### Problemas de Rede

```bash
# Verificar redes
docker network ls

# Inspecionar rede
docker network inspect bridge

# Recriar rede padrão
docker network rm bridge
docker network create bridge
```

### Espaço em Disco

```bash
# Ver uso de espaço
docker system df

# Limpar tudo não utilizado (cuidado!)
docker system prune -a --volumes

# Limpar apenas imagens antigas
docker image prune -a --filter "until=720h"
```

### Serviço Docker não Inicia

```bash
# Verificar status
sudo systemctl status docker

# Ver logs do serviço
sudo journalctl -u docker -n 50

# Reiniciar serviço
sudo systemctl restart docker

# Verificar configuração
docker info
```

## Comparação com Outras Ferramentas

### Docker vs Kubernetes

| Aspecto | Docker | Kubernetes |
|---|---|---|
| Propósito | Containerização | Orquestração |
| Escala | Single host | Multi-host cluster |
| Complexidade | Simples | Complexo |
| Uso | Desenvolvimento/Produção | Produção em larga escala |

### Docker vs Podman

Veja a seção "Docker vs Podman" no início deste documento.

### Quando Usar Docker

- Desenvolvimento local
- CI/CD pipelines
- Aplicações em produção (single host)
- Microserviços
- Ambientes de teste isolados

### Quando Considerar Alternativas

- **Podman**: Se precisa de execução rootless ou daemon-less
- **Kubernetes**: Para orquestração em larga escala
- **Docker Swarm**: Para cluster simples (menos features que K8s)
- **LXC/LXD**: Para containers de sistema completo

## Recursos Adicionais

### Documentação Oficial

- [Docker Docs](https://docs.docker.com/)
- [Docker Hub](https://hub.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Dockerfile Reference](https://docs.docker.com/engine/reference/builder/)

### Aprendizado

- [Docker Getting Started](https://docs.docker.com/get-started/)
- [Play with Docker](https://labs.play-with-docker.com/)
- [Docker Curriculum](https://docker-curriculum.com/)

### Ferramentas Úteis

- **Portainer**: Interface web para gerenciar Docker
- **Lazydocker**: TUI para gerenciar Docker
- **dive**: Analisar layers de imagens
- **hadolint**: Linter para Dockerfiles

### Comunidade

- [Docker Community Forums](https://forums.docker.com/)
- [Docker Slack](https://dockercommunity.slack.com/)
- [Stack Overflow - Docker](https://stackoverflow.com/questions/tagged/docker)

## Veja Também

- [Podman](podman.md) - Alternativa daemon-less ao Docker
- [Poetry](poetry.md) - Gerenciador de dependências Python
- [UV](uv.md) - Gerenciador de pacotes Python ultra-rápido
