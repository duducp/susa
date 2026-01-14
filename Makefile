.PHONY: help install serve build deploy clean cli-install cli-uninstall test shellcheck shfmt format lint

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
	@echo "$(BLUE)Quality Assurance Commands:$(NC)"
	@grep -E '^(shellcheck|shfmt|format|lint|test):.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(BLUE)Documentation Commands:$(NC)"
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) | grep -v '^cli-' | grep -v '^shellcheck' | grep -v '^shfmt' | grep -v '^format' | grep -v '^lint' | grep -v '^test' | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'
	@echo ""

install: ## Instala dependências para documentação
	@pip install --upgrade pip
	@pip install mkdocs-material
	@pip install pymdown-extensions
	@pip install mkdocs-awesome-pages-plugin
	@pip install mkdocs-glightbox
	@pip install mkdocs-panzoom-plugin
	@pip install mkdocs-include-markdown-plugin

serve doc: ## Inicia servidor de documentação local
	@echo "$(GREEN)🌐 Iniciando servidor MkDocs...$(NC)"
	@echo "$(YELLOW)📖 Acesse: http://127.0.0.1:8000$(NC)"
	@echo ""
	@mkdocs serve

clean: ## Remove arquivos gerados
	@echo "$(YELLOW)🧹 Limpando arquivos gerados...$(NC)"
	@rm -rf site/
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@echo "$(GREEN)✅ Limpeza concluída!$(NC)"

# CLI Installation
cli-install: ## Instala o CLI no sistema
	@if command -v susa > /dev/null 2>&1; then \
		echo "$(YELLOW)⚠️  SUSA já está instalado$(NC)"; \
		read -p "Deseja reinstalar? (s/N): " response; \
		if [ "$$response" = "s" ] || [ "$$response" = "S" ]; then \
			echo "$(GREEN)🚀 Reinstalando CLI...$(NC)"; \
			./install.sh; \
		else \
			echo "$(BLUE)ℹ️  Instalação cancelada$(NC)"; \
		fi \
	else \
		echo "$(GREEN)🚀 Instalando CLI...$(NC)"; \
		./install.sh; \
	fi

cli-uninstall: ## Remove o CLI do sistema
	@echo "$(YELLOW)🗑️  Desinstalando CLI...$(NC)"
	@./uninstall.sh

# Quality Assurance
shellcheck: ## Executa ShellCheck em todos os scripts
	@echo "$(GREEN)🔍 Executando ShellCheck...$(NC)"
	@command -v shellcheck >/dev/null 2>&1 || { echo "$(RED)❌ ShellCheck não está instalado. Instale com: sudo apt install shellcheck ou brew install shellcheck$(NC)"; exit 1; }
	@echo ""
	@errors=0; \
	total=0; \
	echo "$(BLUE)Verificando core/susa...$(NC)"; \
	if shellcheck -x core/susa 2>&1 | grep -v "^$$"; then \
		errors=$$((errors + 1)); \
	fi; \
	total=$$((total + 1)); \
	for lib in core/lib/*.sh core/lib/internal/*.sh; do \
		if [ -f "$$lib" ]; then \
			echo "$(BLUE)Verificando $$lib...$(NC)"; \
			if shellcheck -x "$$lib" 2>&1 | grep -v "^$$"; then \
				errors=$$((errors + 1)); \
			fi; \
			total=$$((total + 1)); \
		fi; \
	done; \
	for script in $$(find commands -name "main.sh" -o -name "*.sh" | grep -v "/node_modules/"); do \
		echo "$(BLUE)Verificando $$script...$(NC)"; \
		if shellcheck -x "$$script" 2>&1 | grep -v "^$$"; then \
			errors=$$((errors + 1)); \
		fi; \
		total=$$((total + 1)); \
	done; \
	echo ""; \
	if [ $$errors -eq 0 ]; then \
		echo "$(GREEN)✅ Todos os $$total scripts passaram na verificação!$(NC)"; \
	else \
		echo "$(RED)❌ $$errors de $$total arquivo(s) com problemas$(NC)"; \
		exit 1; \
	fi

shfmt: ## Verifica formatação de scripts com shfmt
	@echo "$(GREEN)📝 Verificando formatação com shfmt...$(NC)"
	@command -v shfmt >/dev/null 2>&1 || { echo "$(RED)❌ shfmt não está instalado. Instale com: sudo apt install shfmt ou brew install shfmt$(NC)"; exit 1; }
	@echo ""
	@errors=0; \
	total=0; \
	echo "$(BLUE)Verificando core/susa...$(NC)"; \
	if ! shfmt -d -i 4 -ci core/susa; then \
		errors=$$((errors + 1)); \
	fi; \
	total=$$((total + 1)); \
	for lib in core/lib/*.sh core/lib/internal/*.sh; do \
		if [ -f "$$lib" ]; then \
			echo "$(BLUE)Verificando $$lib...$(NC)"; \
			if ! shfmt -d -i 4 -ci "$$lib"; then \
				errors=$$((errors + 1)); \
			fi; \
			total=$$((total + 1)); \
		fi; \
	done; \
	for script in $$(find commands install*.sh uninstall*.sh -name "*.sh" -o -name "main.sh" | grep -v "/node_modules/"); do \
		if [ -f "$$script" ]; then \
			echo "$(BLUE)Verificando $$script...$(NC)"; \
			if ! shfmt -d -i 4 -ci "$$script"; then \
				errors=$$((errors + 1)); \
			fi; \
			total=$$((total + 1)); \
		fi; \
	done; \
	echo ""; \
	if [ $$errors -eq 0 ]; then \
		echo "$(GREEN)✅ Todos os $$total scripts estão formatados corretamente!$(NC)"; \
	else \
		echo "$(RED)❌ $$errors de $$total arquivo(s) com problemas de formatação$(NC)"; \
		echo "$(YELLOW)💡 Execute 'make format' para corrigir automaticamente$(NC)"; \
		exit 1; \
	fi

format: ## Formata automaticamente todos os scripts com shfmt
	@echo "$(GREEN)✨ Formatando scripts com shfmt...$(NC)"
	@command -v shfmt >/dev/null 2>&1 || { echo "$(RED)❌ shfmt não está instalado. Instale com: sudo apt install shfmt ou brew install shfmt$(NC)"; exit 1; }
	@echo ""
	@total=0; \
	echo "$(BLUE)Formatando core/susa...$(NC)"; \
	shfmt -w -i 4 -ci core/susa; \
	total=$$((total + 1)); \
	for lib in core/lib/*.sh core/lib/internal/*.sh; do \
		if [ -f "$$lib" ]; then \
			echo "$(BLUE)Formatando $$lib...$(NC)"; \
			shfmt -w -i 4 -ci "$$lib"; \
			total=$$((total + 1)); \
		fi; \
	done; \
	for script in $$(find commands install*.sh uninstall*.sh -name "*.sh" -o -name "main.sh" | grep -v "/node_modules/"); do \
		if [ -f "$$script" ]; then \
			echo "$(BLUE)Formatando $$script...$(NC)"; \
			shfmt -w -i 4 -ci "$$script"; \
			total=$$((total + 1)); \
		fi; \
	done; \
	echo ""; \
	echo "$(GREEN)✅ $$total scripts formatados com sucesso!$(NC)"

lint: shellcheck shfmt ## Executa todas as verificações de qualidade

test: shellcheck shfmt ## Executa todos os testes
	@echo "$(GREEN)✅ Todos os testes passaram!$(NC)"
