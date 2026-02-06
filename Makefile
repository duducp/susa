.PHONY: help install-dev setup-vscode serve doc clean cli-install cli-uninstall test shellcheck shfmt format lint

# Cores para output
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
RED := \033[0;31m
NC := \033[0m

help:
	@echo "$(GREEN)CLI - Makefile Commands$(NC)"
	@echo ""
	@echo "$(BLUE)CLI Commands:$(NC)"
	@grep -E '^cli-[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Development Commands:$(NC)"
	@grep -E '^(install-dev|setup-vscode):.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Quality Assurance Commands:$(NC)"
	@grep -E '^(shellcheck|shfmt|format|lint|test):.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Documentation Commands:$(NC)"
	@grep -E '^(serve|doc|clean):.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

serve: ## Inicia servidor de documentação local
	@echo "$(GREEN)🌐 Iniciando servidor MkDocs...$(NC)"
	@echo "$(YELLOW)📖 Acesse: http://127.0.0.1:8000$(NC)"
	@echo ""
	@mkdocs serve

doc: serve ## Alias para 'serve' - inicia servidor de documentação

clean: ## Remove arquivos gerados
	@echo "$(YELLOW)🧹 Limpando arquivos gerados...$(NC)"
	@rm -rf site/
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "$(GREEN)✅ Limpeza concluída!$(NC)"

# CLI Installation
cli-install: ## Instala o CLI no sistema (modo desenvolvimento - symlink local)
	@echo "$(GREEN)🚀 Instalando CLI em modo desenvolvimento...$(NC)"
	@echo ""
	@BIN_DIR="$$HOME/.local/bin"; \
	CLI_PATH="$$(pwd)/core/susa"; \
	if [ ! -f "$$CLI_PATH" ]; then \
		echo "$(RED)❌ Arquivo core/susa não encontrado!$(NC)"; \
		exit 1; \
	fi; \
	mkdir -p "$$BIN_DIR"; \
	if [ -L "$$BIN_DIR/susa" ] || [ -f "$$BIN_DIR/susa" ]; then \
		echo "$(YELLOW)⚠️  SUSA já está instalado em $$BIN_DIR/susa$(NC)"; \
		CURRENT_TARGET=$$(readlink "$$BIN_DIR/susa" 2>/dev/null || echo "arquivo regular"); \
		echo "$(DIM)   Atual: $$CURRENT_TARGET$(NC)"; \
		echo "$(DIM)   Novo:  $$CLI_PATH$(NC)"; \
		echo ""; \
		read -p "Deseja reinstalar? (s/N): " response; \
		if [ "$$response" = "s" ] || [ "$$response" = "S" ] || [ "$$response" = "y" ] || [ "$$response" = "Y" ]; then \
			echo ""; \
			echo "$(BLUE)→ Removendo instalação anterior...$(NC)"; \
			rm -f "$$BIN_DIR/susa"; \
			echo "$(BLUE)→ Criando symlink para $$CLI_PATH...$(NC)"; \
			ln -sf "$$CLI_PATH" "$$BIN_DIR/susa"; \
			echo "$(GREEN)  ✓ Symlink criado com sucesso!$(NC)"; \
		else \
			echo "$(BLUE)ℹ️  Instalação cancelada$(NC)"; \
			exit 0; \
		fi \
	else \
		echo "$(BLUE)→ Criando diretório $$BIN_DIR...$(NC)"; \
		echo "$(BLUE)→ Criando symlink para $$CLI_PATH...$(NC)"; \
		ln -sf "$$CLI_PATH" "$$BIN_DIR/susa"; \
		echo "$(GREEN)  ✓ Symlink criado com sucesso!$(NC)"; \
	fi; \
	echo ""; \
	if echo "$$PATH" | grep -q "$$HOME/.local/bin"; then \
		echo "$(GREEN)  ✓ $$HOME/.local/bin já está no PATH$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  $$HOME/.local/bin não está no PATH$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Adicione ao seu ~/.bashrc ou ~/.zshrc:$(NC)"; \
		echo "$(BLUE)  export PATH=\"\$$HOME/.local/bin:\$$PATH\"$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Depois execute: source ~/.bashrc (ou ~/.zshrc)$(NC)"; \
	fi; \
	echo ""; \
	echo "$(GREEN)✅ CLI instalado com sucesso em modo desenvolvimento!$(NC)"; \
	echo "$(DIM)   Symlink: $$BIN_DIR/susa -> $$CLI_PATH$(NC)"; \
	echo ""; \
	echo "$(YELLOW)💡 Teste com: susa --version$(NC)"

cli-uninstall: ## Remove o CLI do sistema (remove apenas o symlink)
	@echo "$(YELLOW)🗑️  Desinstalando CLI...$(NC)"
	@echo ""
	@BIN_DIR="$$HOME/.local/bin"; \
	if [ -L "$$BIN_DIR/susa" ]; then \
		LINK_TARGET=$$(readlink "$$BIN_DIR/susa"); \
		echo "$(BLUE)→ Removendo symlink...$(NC)"; \
		echo "$(DIM)   $$BIN_DIR/susa -> $$LINK_TARGET$(NC)"; \
		rm -f "$$BIN_DIR/susa"; \
		echo "$(GREEN)  ✓ Symlink removido com sucesso!$(NC)"; \
	elif [ -f "$$BIN_DIR/susa" ]; then \
		echo "$(YELLOW)⚠️  $$BIN_DIR/susa existe mas não é um symlink$(NC)"; \
		echo "$(YELLOW)   Pode ser uma instalação via install.sh$(NC)"; \
		echo ""; \
		read -p "Deseja remover mesmo assim? (s/N): " response; \
		if [ "$$response" = "s" ] || [ "$$response" = "S" ] || [ "$$response" = "y" ] || [ "$$response" = "Y" ]; then \
			rm -f "$$BIN_DIR/susa"; \
			echo "$(GREEN)  ✓ Arquivo removido!$(NC)"; \
		else \
			echo "$(BLUE)ℹ️  Nada foi removido$(NC)"; \
			exit 0; \
		fi \
	else \
		echo "$(BLUE)ℹ️  CLI não está instalado em $$BIN_DIR/susa$(NC)"; \
		exit 0; \
	fi; \
	echo ""; \
	echo "$(GREEN)✅ CLI desinstalado com sucesso!$(NC)"; \
	echo "$(DIM)   Os arquivos do projeto em $$(pwd) não foram removidos.$(NC)"

# Quality Assurance
lint: ## Executa ShellCheck, shfmt em todos os arquivos
	@echo "$(BLUE)🔍 Executando verificações via pre-commit...$(NC)"
	@if command -v pre-commit >/dev/null 2>&1; then \
		pre-commit run --all-files; \
	else \
		echo "$(RED)❌ pre-commit não está instalado$(NC)"; \
		echo "$(YELLOW)💡 Instale com: pip install pre-commit$(NC)"; \
		exit 1; \
	fi

format: ## Formata automaticamente todos os scripts com shfmt
	@echo "$(GREEN)✨ Formatando scripts com shfmt...$(NC)"
	@command -v shfmt >/dev/null 2>&1 || { echo "$(RED)❌ shfmt não está instalado. Instale com: sudo apt install shfmt ou brew install shfmt$(NC)"; exit 1; }
	@shfmt -w -i 4 -ci -sr \
		core/susa \
		$$(find core/lib -name "*.sh" -type f 2>/dev/null) \
		$$(find . -maxdepth 1 -name "install*.sh" -o -name "uninstall*.sh" 2>/dev/null) \
		$$(find commands -name "*.sh" -type f 2>/dev/null | grep -v "/node_modules/") \
		$$(find plugins -name "*.sh" -type f 2>/dev/null | grep -v "/node_modules/" || true)
	@echo "$(GREEN)✅ Scripts formatados com sucesso!$(NC)"

test: ## Executa todos os testes
	@echo "$(GREEN)✅ Todos os testes passaram!$(NC)"

# Development Commands
install-dev: ## Instala ferramentas de desenvolvimento
	@echo "$(GREEN)📦 Instalando ferramentas de desenvolvimento...$(NC)"
	@echo ""

	@# Criar diretório local para binários se não existir
	@mkdir -p $$HOME/.local/bin
	@export PATH="$$HOME/.local/bin:$$PATH"

	@# Instalar bash-language-server via npm
	@if ! command -v bash-language-server >/dev/null 2>&1; then \
		echo "$(BLUE)  → Instalando bash-language-server...$(NC)"; \
		if command -v npm >/dev/null 2>&1; then \
			npm install -g bash-language-server 2>/dev/null || npm install --prefix $$HOME/.local bash-language-server; \
			echo "$(GREEN)    ✅ bash-language-server instalado!$(NC)"; \
		else \
			echo "$(YELLOW)    ⚠️  npm não encontrado, pulando bash-language-server$(NC)"; \
		fi \
	else \
		echo "$(GREEN)  ✓ bash-language-server já instalado$(NC)"; \
	fi

	@# Instalar shellcheck
	@if ! command -v shellcheck >/dev/null 2>&1; then \
		echo "$(BLUE)  → Instalando shellcheck...$(NC)"; \
		if [ "$$(uname)" = "Darwin" ]; then \
			if command -v brew >/dev/null 2>&1; then \
				brew install shellcheck; \
			else \
				echo "$(RED)    ❌ Homebrew não encontrado. Instale em: https://brew.sh$(NC)"; \
				exit 1; \
			fi \
		else \
			sudo apt install -y shellcheck; \
		fi; \
		echo "$(GREEN)    ✅ shellcheck instalado!$(NC)"; \
	else \
		echo "$(GREEN)  ✓ shellcheck já instalado$(NC)"; \
	fi

	@# Instalar shfmt
	@if ! command -v shfmt >/dev/null 2>&1; then \
		echo "$(BLUE)  → Instalando shfmt...$(NC)"; \
		if [ "$$(uname)" = "Darwin" ]; then \
			if command -v brew >/dev/null 2>&1; then \
				brew install shfmt; \
			else \
				echo "$(RED)    ❌ Homebrew não encontrado. Instale em: https://brew.sh$(NC)"; \
				exit 1; \
			fi \
		else \
			sudo apt install -y shfmt; \
		fi; \
		echo "$(GREEN)    ✅ shfmt instalado!$(NC)"; \
	else \
		echo "$(GREEN)  ✓ shfmt já instalado$(NC)"; \
	fi

	@# Verificar se pip está disponível
	@if ! command -v pip3 >/dev/null 2>&1 && ! command -v pip >/dev/null 2>&1; then \
		echo "$(YELLOW)⚠️  pip não encontrado. Instalando ferramentas Python com método alternativo...$(NC)"; \
		if command -v python3 >/dev/null 2>&1; then \
			python3 -m ensurepip --user 2>/dev/null || echo "$(YELLOW)  ⚠️  Não foi possível instalar pip$(NC)"; \
		fi \
	fi

	@# Usar pip3 ou pip, com preferência para --user
	@PIP_CMD=$$(command -v pip3 || command -v pip); \
	if [ -n "$$PIP_CMD" ]; then \
		echo "$(BLUE)  → Instalando ferramentas Python...$(NC)"; \
		$$PIP_CMD install --user --upgrade pip 2>/dev/null || $$PIP_CMD install --upgrade pip; \
		$$PIP_CMD install --user pre-commit 2>/dev/null || $$PIP_CMD install pre-commit; \
		echo "$(GREEN)    ✅ pre-commit instalado!$(NC)"; \
		echo "$(BLUE)  → Instalando MkDocs e plugins...$(NC)"; \
		$$PIP_CMD install --user mkdocs-material pymdown-extensions mkdocs-awesome-pages-plugin mkdocs-glightbox mkdocs-panzoom-plugin mkdocs-include-markdown-plugin 2>/dev/null || \
		$$PIP_CMD install mkdocs-material pymdown-extensions mkdocs-awesome-pages-plugin mkdocs-glightbox mkdocs-panzoom-plugin mkdocs-include-markdown-plugin; \
		echo "$(GREEN)    ✅ MkDocs e plugins instalados!$(NC)"; \
	else \
		echo "$(RED)❌ pip não está disponível. Instale Python/pip primeiro.$(NC)"; \
		exit 1; \
	fi

	@# Instalar hooks do pre-commit
	@if command -v pre-commit >/dev/null 2>&1; then \
		echo "$(BLUE)  → Configurando hooks do pre-commit...$(NC)"; \
		pre-commit install; \
		echo "$(GREEN)    ✅ Hooks instalados!$(NC)"; \
	fi

	@echo ""
	@echo "$(GREEN)✅ Ferramentas de desenvolvimento instaladas com sucesso!$(NC)"
	@echo ""
	@echo "$(YELLOW)💡 Certifique-se de que $$HOME/.local/bin está no seu PATH$(NC)"
	@echo "$(YELLOW)💡 Adicione ao seu ~/.bashrc ou ~/.zshrc:$(NC)"
	@echo "$(BLUE)   export PATH=\"\$$HOME/.local/bin:\$$PATH\"$(NC)"
	@echo ""
	@echo "$(YELLOW)💡 Execute 'make setup-vscode' para configurar o VS Code$(NC)"

setup-vscode: ## Configura VS Code com configurações do projeto
	@echo "$(GREEN)⚙️  Configurando VS Code...$(NC)"
	@echo ""
	@if [ ! -d ".vscode" ]; then \
		echo "$(RED)❌ Diretório .vscode não encontrado!$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f ".vscode/settings.json.example" ]; then \
		echo "$(RED)❌ Arquivo .vscode/settings.json.example não encontrado!$(NC)"; \
		exit 1; \
	fi
	@if [ ! -f ".vscode/extensions.json.example" ]; then \
		echo "$(RED)❌ Arquivo .vscode/extensions.json.example não encontrado!$(NC)"; \
		exit 1; \
	fi
	@if [ -f ".vscode/settings.json" ]; then \
		echo "$(YELLOW)⚠️  settings.json já existe. Deseja sobrescrever? (s/N):$(NC)"; \
		read -p "" response; \
		if [ "$$response" = "s" ] || [ "$$response" = "S" ]; then \
			echo "$(BLUE)Criando settings.json...$(NC)"; \
			cp .vscode/settings.json.example .vscode/settings.json; \
		else \
			echo "$(BLUE)ℹ️  Mantendo settings.json existente$(NC)"; \
		fi \
	else \
		echo "$(BLUE)Criando settings.json...$(NC)"; \
		cp .vscode/settings.json.example .vscode/settings.json; \
	fi
	@if [ -f ".vscode/extensions.json" ]; then \
		echo "$(YELLOW)⚠️  extensions.json já existe. Deseja sobrescrever? (s/N):$(NC)"; \
		read -p "" response; \
		if [ "$$response" = "s" ] || [ "$$response" = "S" ]; then \
			echo "$(BLUE)Criando extensions.json...$(NC)"; \
			cp .vscode/extensions.json.example .vscode/extensions.json; \
		else \
			echo "$(BLUE)ℹ️  Mantendo extensions.json existente$(NC)"; \
		fi \
	else \
		echo "$(BLUE)Criando extensions.json...$(NC)"; \
		cp .vscode/extensions.json.example .vscode/extensions.json; \
	fi
	@echo ""
	@echo "$(GREEN)✅ VS Code configurado com sucesso!$(NC)"
	@echo "$(YELLOW)💡 Reabra o VS Code para aplicar as configurações$(NC)"
	@echo "$(YELLOW)💡 Instale as extensões recomendadas quando solicitado$(NC)"
