# Self Info

Exibe informações detalhadas sobre a instalação do Susa CLI.

## O que mostra?

Este comando apresenta:

- **Nome e versão** da CLI
- **Diretório de instalação**
- **Localização do executável**
- **Shell atual** em uso
- **Status do autocompletar**
- **Detalhes do sistema operacional**
- **Status das dependências**

## Como usar

```bash
susa self info
```

## Exemplo de saída

```text
╔═════════════════════════════════════════════════╗
║           Informações de Instalação             ║
╚═════════════════════════════════════════════════╝

  📦 Nome:             Susa CLI
  🏷️  Versão:           1.0.0
  📂 Instalação:       /home/user/.susa
  🔗 Executável:       /usr/local/bin/susa
  🐚 Shell atual:      bash
  ✨ Autocompletar:    Sim - Configurado em ~/.bashrc
```

## Opções

| Opção | O que faz |
|-------|-----------|
| `-h, --help` | Mostra ajuda |

## Veja também

- [susa self version](version.md) - Ver apenas a versão
- [susa self completion](completion.md) - Configurar autocompletar
