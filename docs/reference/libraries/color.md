# color.sh

Define constantes de cores para formatação de texto no console.

## Variáveis Disponíveis

### Cores Básicas

```bash
RED              # Vermelho
GREEN            # Verde
YELLOW           # Amarelo
BLUE             # Azul
MAGENTA          # Magenta
CYAN             # Ciano
GRAY             # Cinza
WHITE            # Branco
```

### Cores Claras

```bash
LIGHT_RED        # Vermelho claro
LIGHT_GREEN      # Verde claro
LIGHT_YELLOW     # Amarelo claro
LIGHT_BLUE       # Azul claro
LIGHT_MAGENTA    # Magenta claro
LIGHT_CYAN       # Ciano claro
LIGHT_GRAY       # Cinza claro
```

### Cores Escuras

```bash
CYAN_DARK        # Ciano escuro
```

### Estilos

```bash
BOLD             # Negrito
ITALIC           # Itálico
UNDERLINE        # Sublinhado
DIM              # Escurecido

NC               # Reset (No Color)
RESET            # Reset (alias para NC)
```

## Exemplo de Uso

```bash
#!/bin/bash
source "$CLI_DIR/lib/color.sh"

echo -e "${GREEN}Sucesso!${NC}"
echo -e "${RED}${BOLD}Erro crítico!${NC}"
echo -e "${YELLOW}Atenção: ${GRAY}mensagem de aviso${NC}"
```

## Boas Práticas

1. Sempre termine mensagens coloridas com `${NC}`
2. Combine estilos: `${BOLD}${GREEN}Texto${NC}`
3. Use cores consistentemente (verde=sucesso, vermelho=erro, amarelo=aviso)
