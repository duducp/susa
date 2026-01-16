# Setup Postman

Instala o Postman, uma plataforma completa para desenvolvimento de APIs que permite criar, testar, documentar e monitorar APIs de forma colaborativa.

## O que é Postman?

Postman é a plataforma líder mundial para desenvolvimento de APIs, oferecendo um conjunto completo de ferramentas para todo o ciclo de vida de uma API:

- **Request Builder**: Construtor visual para requisições HTTP/HTTPS
- **Collections**: Organize e compartilhe conjuntos de requests
- **Automated Testing**: Scripts de teste automatizados em JavaScript
- **Mock Servers**: Crie servidores mock para simular APIs
- **Documentation**: Documentação automática e interativa
- **Monitoring**: Monitoramento contínuo de APIs em produção
- **Collaboration**: Workspaces compartilhados para equipes

**Por exemplo:**

```javascript
// Teste automatizado no Postman
pm.test("Status code is 200", function () {
    pm.response.to.have.status(200);
});

pm.test("Response time is less than 200ms", function () {
    pm.expect(pm.response.responseTime).to.be.below(200);
});

pm.test("User has valid email", function () {
    const jsonData = pm.response.json();
    pm.expect(jsonData.email).to.match(/^.+@.+\..+$/);
});
```

## Como usar

### Instalar

```bash
susa setup postman
```

O comando vai:

**No macOS:**

- Verificar se o Homebrew está instalado
- Instalar o Postman via `brew install --cask postman`
- Configurar o comando `postman` no PATH

**No Linux:**

- Baixar a versão mais recente do site oficial
- Extrair para `/opt/Postman`
- Criar link simbólico em `/usr/local/bin/postman`
- Criar entrada no menu de aplicativos

Depois de instalar, você pode abrir o Postman:

```bash
postman              # Abre o Postman
```

### Atualizar

```bash
susa setup postman --upgrade
```

Atualiza o Postman para a versão mais recente disponível. O comando usa:

- **macOS**: `brew upgrade --cask postman`
- **Linux**: Baixa e reinstala a versão mais recente

Todas as suas collections, environments e configurações serão preservados.

### Desinstalar

```bash
susa setup postman --uninstall
```

Remove o Postman do sistema. O comando vai:

1. Remover o binário e aplicação
2. Remover link simbólico (Linux)
3. Remover entrada do menu (Linux)
4. Suas collections e configurações permanecerão em:
   - `~/Postman` (coleções e dados)
   - `~/.config/Postman` (configurações)

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda detalhada |
| `-u, --upgrade` | Atualiza o Postman para a versão mais recente |
| `--uninstall` | Remove o Postman do sistema |
| `-v, --verbose` | Habilita saída detalhada para depuração |
| `-q, --quiet` | Minimiza a saída, desabilita mensagens de depuração |

## Guia Rápido de Uso

### Primeira requisição

1. Abra o Postman
2. Clique em **"+"** para nova tab ou **Ctrl+T**
3. Configure a requisição:
   - **Method**: GET, POST, PUT, DELETE, etc.
   - **URL**: `https://api.github.com/users/octocat`
4. Clique em **Send**
5. Visualize a resposta (Body, Headers, Cookies, etc.)

### Principais recursos

#### 1. Collections

Organize suas requisições em coleções:

```javascript
// Estrutura de uma collection
My API
├── Authentication
│   ├── Login
│   └── Refresh Token
├── Users
│   ├── Get All Users
│   ├── Get User by ID
│   ├── Create User
│   ├── Update User
│   └── Delete User
└── Products
    ├── List Products
    └── Create Product
```

**Criar collection:**
- Sidebar → **Collections** → **+ New Collection**
- Nomeie: "My API"
- Arraste requests para dentro da collection
- Salve variáveis compartilhadas

#### 2. Environments

Gerencie variáveis para diferentes ambientes:

```javascript
// Environment: Development
{
  "baseUrl": "http://localhost:3000",
  "apiKey": "dev-key-123",
  "timeout": 5000
}

// Environment: Production
{
  "baseUrl": "https://api.production.com",
  "apiKey": "prod-key-456",
  "timeout": 30000
}

// Uso na requisição
GET {{baseUrl}}/api/users
Headers:
  Authorization: Bearer {{apiKey}}
```

**Criar environment:**
- Canto superior direito → **Environments** → **+ Create Environment**
- Adicione variáveis (key/value)
- Selecione environment ativo no dropdown

#### 3. Variables

Diferentes escopos de variáveis:

```javascript
// Global variables (todos workspaces)
pm.globals.set("globalVar", "value");

// Collection variables (toda collection)
pm.collectionVariables.set("collectionVar", "value");

// Environment variables (environment ativo)
pm.environment.set("envVar", "value");

// Local variables (apenas request atual)
let localVar = "value";

// Ordem de precedência:
// Local → Environment → Collection → Global
```

#### 4. Pre-request Scripts

Execute código antes da requisição:

```javascript
// Gerar timestamp
pm.environment.set("timestamp", Date.now());

// Gerar UUID
const uuid = require('uuid');
pm.environment.set("requestId", uuid.v4());

// Calcular hash HMAC
const CryptoJS = require('crypto-js');
const message = "my message";
const secret = pm.environment.get("secret");
const hash = CryptoJS.HmacSHA256(message, secret);
pm.environment.set("signature", hash.toString());

// Fazer requisição auxiliar
pm.sendRequest({
    url: pm.environment.get("baseUrl") + "/token",
    method: "POST",
    header: {
        'Content-Type': 'application/json'
    },
    body: {
        mode: 'raw',
        raw: JSON.stringify({
            username: "user",
            password: "pass"
        })
    }
}, function (err, response) {
    if (!err) {
        const token = response.json().token;
        pm.environment.set("accessToken", token);
    }
});
```

#### 5. Tests (Post-response Scripts)

Valide respostas automaticamente:

```javascript
// Status code
pm.test("Status code is 200", () => {
    pm.response.to.have.status(200);
});

// Response time
pm.test("Response time < 500ms", () => {
    pm.expect(pm.response.responseTime).to.be.below(500);
});

// Headers
pm.test("Content-Type is JSON", () => {
    pm.response.to.have.header("Content-Type", "application/json");
});

// Body structure
pm.test("Response has expected structure", () => {
    const jsonData = pm.response.json();
    pm.expect(jsonData).to.have.property("id");
    pm.expect(jsonData).to.have.property("name");
    pm.expect(jsonData.email).to.match(/^.+@.+\..+$/);
});

// Array validation
pm.test("Users array is not empty", () => {
    const jsonData = pm.response.json();
    pm.expect(jsonData.users).to.be.an('array').that.is.not.empty;
    pm.expect(jsonData.users[0]).to.have.property('id');
});

// Schema validation
const schema = {
    type: "object",
    properties: {
        id: { type: "number" },
        name: { type: "string" },
        email: { type: "string", format: "email" }
    },
    required: ["id", "name", "email"]
};

pm.test("Schema is valid", () => {
    pm.response.to.have.jsonSchema(schema);
});

// Save data for next request
const responseData = pm.response.json();
pm.environment.set("userId", responseData.id);
pm.environment.set("userToken", responseData.token);
```

### Atalhos de teclado

#### Navegação

| Atalho | Ação |
|--------|------|
| `Ctrl+T` | Nova tab |
| `Ctrl+W` | Fechar tab atual |
| `Ctrl+Tab` | Próxima tab |
| `Ctrl+Shift+Tab` | Tab anterior |
| `Ctrl+L` | Focar na URL |
| `Ctrl+E` | Abrir environments |

#### Request

| Atalho | Ação |
|--------|------|
| `Ctrl+Enter` | Enviar request |
| `Ctrl+S` | Salvar request |
| `Ctrl+Shift+S` | Salvar como |
| `Ctrl+D` | Duplicar request |
| `Alt+Up/Down` | Navegar histórico |

#### Visualização

| Atalho | Ação |
|--------|------|
| `Ctrl+[` | Sidebar toggle |
| `Ctrl+]` | Console toggle |
| `Ctrl+B` | Beautify JSON |
| `Ctrl+F` | Buscar |

## Recursos Avançados

### 1. Mock Servers

Crie servidores mock para simular APIs:

```bash
# Criar mock server
Collection → ⋯ → Mock Collection
├── Mock Server URL: https://[mock-id].mock.pstmn.io
└── Environment: Create new or use existing

# Exemplo de mock
GET /api/users
Response:
{
    "examples": [
        {
            "name": "Success Response",
            "status": 200,
            "body": {
                "users": [
                    {"id": 1, "name": "John"},
                    {"id": 2, "name": "Jane"}
                ]
            }
        }
    ]
}

# Uso
curl https://[mock-id].mock.pstmn.io/api/users
```

### 2. Newman (CLI Runner)

Execute collections via linha de comando:

```bash
# Instalar Newman
npm install -g newman

# Executar collection
newman run MyCollection.json

# Com environment
newman run MyCollection.json -e Production.json

# Com iterações
newman run MyCollection.json -n 10

# Com data file
newman run MyCollection.json -d data.csv

# Relatório HTML
newman run MyCollection.json -r html --reporter-html-export report.html

# CI/CD integration
newman run MyCollection.json \
  --environment Production.json \
  --reporters cli,json,junit \
  --reporter-junit-export ./newman-report.xml \
  --bail
```

### 3. Data-driven Testing

Teste com múltiplos datasets:

```csv
# data.csv
username,password,expectedStatus
user1,pass1,200
user2,wrongpass,401
admin,adminpass,200
```

```javascript
// Request: POST {{baseUrl}}/login
// Body:
{
    "username": "{{username}}",
    "password": "{{password}}"
}

// Test:
pm.test("Status matches expected", () => {
    const expected = parseInt(pm.iterationData.get("expectedStatus"));
    pm.response.to.have.status(expected);
});

// Runner → Select collection → Data → Select data.csv → Run
```

### 4. Workflows (Request Chaining)

Encadeie requests com `setNextRequest()`:

```javascript
// Request 1: Login
pm.test("Login successful", () => {
    pm.response.to.have.status(200);
    const token = pm.response.json().token;
    pm.environment.set("token", token);
});
pm.setNextRequest("Get User Profile");

// Request 2: Get User Profile
pm.test("Profile retrieved", () => {
    pm.response.to.have.status(200);
    const userId = pm.response.json().id;
    pm.environment.set("userId", userId);
});
pm.setNextRequest("Update User");

// Request 3: Update User
pm.test("Update successful", () => {
    pm.response.to.have.status(200);
});
pm.setNextRequest("Logout");

// Request 4: Logout
pm.test("Logout successful", () => {
    pm.response.to.have.status(200);
});
pm.setNextRequest(null); // Fim do fluxo
```

### 5. API Documentation

Gere documentação automática:

```bash
# Publicar documentação
Collection → ⋯ → Publish Docs
├── Auto-generated documentation
├── Customizable layout
├── Code samples (curl, Python, JavaScript, etc.)
└── Public or private

# Features
✓ Request/response examples
✓ Parameter descriptions
✓ Authentication info
✓ Code snippets in multiple languages
✓ Interactive "Run in Postman" button
```

### 6. Monitors

Monitore APIs automaticamente:

```bash
# Criar monitor
Collection → ⋯ → Monitor Collection
├── Schedule: Every 5 minutes / hourly / daily
├── Environment: Production
├── Email alerts on failure
└── Slack/webhook notifications

# Monitor reports
✓ Response times
✓ Success/failure rates
✓ Test results
✓ Historical trends
```

## Configurações Úteis

### Proxy

Configure proxy para requests:

```bash
Settings → Proxy
├── Use System Proxy: ON/OFF
├── Add Custom Proxy:
│   ├── Proxy Type: HTTP/HTTPS
│   ├── Proxy Server: proxy.company.com
│   ├── Port: 8080
│   └── Authentication: username/password
└── Bypass proxy for: localhost,127.0.0.1
```

### SSL Certificates

Trabalhe com certificados SSL customizados:

```bash
Settings → Certificates
├── CA Certificates: custom-ca.pem
├── Client Certificates:
│   ├── Host: api.mycompany.com
│   ├── Certificate: client-cert.crt
│   └── Key: client-key.key
└── SSL Verification: ON/OFF
```

### Interceptor

Capture requisições do browser:

```bash
# Instalar Postman Interceptor (Chrome Extension)
# Settings → Interceptor
├── Install Interceptor Bridge
├── Connect to browser
└── Capture cookies and requests

# Uso
1. Navigate browser to site
2. Postman captures all requests
3. Save to collection
```

## Exemplos Práticos

### REST API completo

```javascript
// Collection: User Management API

// 1. Register User
POST {{baseUrl}}/api/users/register
Body (JSON):
{
    "name": "John Doe",
    "email": "john@example.com",
    "password": "SecurePass123"
}

Tests:
pm.test("User registered", () => {
    pm.response.to.have.status(201);
    const user = pm.response.json();
    pm.environment.set("userId", user.id);
});

// 2. Login
POST {{baseUrl}}/api/auth/login
Body (JSON):
{
    "email": "john@example.com",
    "password": "SecurePass123"
}

Tests:
pm.test("Login successful", () => {
    pm.response.to.have.status(200);
    const token = pm.response.json().token;
    pm.environment.set("authToken", token);
});

// 3. Get Profile
GET {{baseUrl}}/api/users/{{userId}}
Headers:
Authorization: Bearer {{authToken}}

Tests:
pm.test("Profile retrieved", () => {
    pm.response.to.have.status(200);
    const user = pm.response.json();
    pm.expect(user.email).to.eql("john@example.com");
});

// 4. Update Profile
PUT {{baseUrl}}/api/users/{{userId}}
Headers:
Authorization: Bearer {{authToken}}
Body (JSON):
{
    "name": "John Updated",
    "bio": "Software Developer"
}

Tests:
pm.test("Profile updated", () => {
    pm.response.to.have.status(200);
});

// 5. Delete User
DELETE {{baseUrl}}/api/users/{{userId}}
Headers:
Authorization: Bearer {{authToken}}

Tests:
pm.test("User deleted", () => {
    pm.response.to.have.status(204);
});
```

### GraphQL API

```javascript
POST {{baseUrl}}/graphql
Headers:
Content-Type: application/json

Body (GraphQL):
{
    "query": "query GetUser($id: ID!) { user(id: $id) { id name email posts { id title } } }",
    "variables": {
        "id": "123"
    }
}

Tests:
pm.test("GraphQL query successful", () => {
    pm.response.to.have.status(200);
    const data = pm.response.json().data;
    pm.expect(data.user).to.have.property('id');
    pm.expect(data.user.posts).to.be.an('array');
});
```

### File Upload

```javascript
POST {{baseUrl}}/api/upload
Headers:
Authorization: Bearer {{authToken}}

Body (form-data):
├── file: [Select File]
├── title: "My Document"
└── description: "Important file"

Tests:
pm.test("File uploaded", () => {
    pm.response.to.have.status(201);
    const response = pm.response.json();
    pm.expect(response.fileUrl).to.include('http');
});
```

### WebSocket

```javascript
// WebSocket request
ws://{{baseUrl}}/socket

// Connection
const ws = new WebSocket("ws://localhost:3000/socket");

ws.onopen = function() {
    console.log("Connected");
    ws.send(JSON.stringify({
        type: "subscribe",
        channel: "updates"
    }));
};

ws.onmessage = function(event) {
    const data = JSON.parse(event.data);
    console.log("Received:", data);
};
```

## Integrações

### Git/Version Control

Sincronize collections com Git:

```bash
# Postman → Settings → Version Control
├── Connect to GitHub/GitLab/Bitbucket
├── Select repository
└── Auto-sync on changes

# Ou exportar manualmente
Collection → Export → Collection v2.1
└── Commit to Git
```

### CI/CD Pipeline

```yaml
# GitHub Actions example
name: API Tests

on: [push, pull_request]

jobs:
  api-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Install Newman
        run: npm install -g newman

      - name: Run Postman Collection
        run: |
          newman run collection.json \
            --environment production.json \
            --reporters cli,json \
            --reporter-json-export results.json

      - name: Upload Results
        uses: actions/upload-artifact@v2
        with:
          name: newman-results
          path: results.json
```

### Swagger/OpenAPI

Importe definições OpenAPI:

```bash
# Import → OpenAPI 3.0 / Swagger 2.0
File → Import → Link or File
└── Automatically generates collection from API spec

# Sync with API
Collection → ⋯ → Sync with API
└── Updates when API definition changes
```

## Troubleshooting

### Requisição não funciona

```bash
# Verificar Console
View → Show Postman Console (Ctrl+Alt+C)
└── Veja logs detalhados de requests/responses

# Verificar SSL
Settings → SSL certificate verification: OFF
└── Apenas para desenvolvimento, não para produção

# Verificar Proxy
Settings → Proxy → Use System Proxy: OFF
└── Ou configure proxy manualmente
```

### Environment variables não funcionam

```bash
# Verificar environment ativo
Top-right corner → Check selected environment

# Verificar escopo da variável
Environment → Hover over variable → Check scope

# Reset variables
Environment → ⋯ → Reset
```

### Collection Runner falha

```bash
# Verificar dependências entre requests
Certifique-se que:
├── Tokens são salvos em environment
├── setNextRequest() está correto
├── Pre-request scripts não têm erros
└── Variables estão disponíveis

# Debug
Add console.log() nos scripts
View → Console para ver outputs
```

## Dicas de Produtividade

### 1. Snippets reutilizáveis

Salve snippets comuns:

```javascript
// Validate pagination
pm.test("Pagination is present", () => {
    const json = pm.response.json();
    pm.expect(json).to.have.property('page');
    pm.expect(json).to.have.property('perPage');
    pm.expect(json).to.have.property('total');
});

// Salve como snippet para reusar
```

### 2. Workspaces compartilhados

Organize por projeto:

```
Personal Workspace
Team Workspace
  ├── Project A
  │   ├── API Collection
  │   ├── Dev Environment
  │   └── Prod Environment
  └── Project B
      └── ...
```

### 3. Code generation

Gere código para várias linguagens:

```bash
Request → Code (</> icon) → Select language:
├── cURL
├── Python (requests)
├── JavaScript (fetch/axios)
├── Java (OkHttp)
├── Go (native)
└── PHP (cURL)
```

### 4. Bulk editing

Edite múltiplos requests de uma vez:

```bash
Collection → ⋯ → Bulk Edit
├── Change base URL
├── Update headers
├── Modify auth
└── Add scripts
```

## Recursos e Links

- **Site oficial**: [https://www.postman.com](https://www.postman.com)
- **Documentação**: [https://learning.postman.com/docs/](https://learning.postman.com/docs/)
- **Learning Center**: [https://learning.postman.com/](https://learning.postman.com/)
- **Newman**: [https://github.com/postmanlabs/newman](https://github.com/postmanlabs/newman)
- **Community**: [https://community.postman.com/](https://community.postman.com/)
- **Public APIs**: [https://www.postman.com/explore](https://www.postman.com/explore)

## Comparação com outras ferramentas

| Recurso | Postman | Insomnia | cURL | HTTPie |
|---------|---------|----------|------|--------|
| Interface gráfica | ✅ | ✅ | ❌ | ❌ |
| Collections | ✅ | ✅ | ❌ | ❌ |
| Automated tests | ✅ | ⚠️ Limitado | ❌ | ❌ |
| Mock servers | ✅ | ❌ | ❌ | ❌ |
| Monitoring | ✅ | ❌ | ❌ | ❌ |
| Team collaboration | ✅ | ✅ | ❌ | ❌ |
| CLI runner | ✅ Newman | ✅ | ✅ | ✅ |
| GraphQL | ✅ | ✅ | ⚠️ Manual | ⚠️ Manual |
| WebSocket | ✅ | ✅ | ❌ | ❌ |
| Documentation | ✅ Auto | ⚠️ Manual | ❌ | ❌ |

## Variáveis de Ambiente

O comando usa as seguintes variáveis configuráveis:

| Variável | Valor Padrão | Descrição |
|----------|--------------|-----------|
| `POSTMAN_HOMEBREW_CASK` | `postman` | Nome do cask no Homebrew (macOS) |
| `POSTMAN_DOWNLOAD_URL` | `https://dl.pstmn.io/download/latest/linux64` | URL de download para Linux |
| `POSTMAN_INSTALL_DIR` | `/opt/Postman` | Diretório de instalação no Linux |
| `POSTMAN_DESKTOP_FILE` | `/usr/share/applications/postman.desktop` | Arquivo .desktop para menu de aplicativos |
| `POSTMAN_ICON_URL` | `https://www.postman.com/_ar-assets/images/favicon-1-48.png` | URL do ícone do Postman |

Para personalizar, edite o arquivo `/commands/setup/postman/command.json`.
