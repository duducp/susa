# Changelog - Refatoração do Sistema de Categorias

## 📅 Data: 11 de Janeiro de 2026

## 🔄 Mudanças Principais

### Antes (Sistema Antigo)
- **Comandos:** Diretórios COM `config.yaml`
- **Subcategorias:** Diretórios SEM `config.yaml` (usavam `.category` para descrição)
- **Problema:** Confuso - presença/ausência de arquivo determinava o tipo

### Depois (Sistema Novo) ✅
- **Comandos:** Diretórios com `config.yaml` + campo `script:` + arquivo do script
- **Subcategorias:** Diretórios com `config.yaml` SEM campo `script:`
- **Vantagem:** Mais intuitivo - "tem script executável = é comando"

## 🎯 Lógica de Detecção

O sistema agora verifica em ordem:
1. Diretório tem `config.yaml`? → Se não, ignora
2. Config tem campo `script:`? → Se não, é subcategoria
3. Arquivo do script existe? → Se não, é subcategoria
4. ✅ É um comando executável!

## 📝 Estrutura de Arquivos

### Comando (Executável)
```yaml
# commands/install/docker/config.yaml
name: "Docker"
description: "Instala Docker CE"
script: "main.sh"      # ← Campo obrigatório
sudo: true
os: ["linux"]
```

### Subcategoria (Navegável)
```yaml
# commands/install/python/config.yaml
name: "Python"
description: "Ferramentas Python"
# SEM campo 'script' = navegável
```

## 🗑️ Arquivos Removidos

- ❌ `.category` - Não é mais necessário
- ✅ Todos usam `config.yaml` agora

## 🔧 Código Modificado

### Arquivos Alterados

1. **lib/yaml.sh**
   - Nova função: `is_command_dir()` - Verifica se é comando
   - Atualizada: `discover_items_in_category()` - Usa nova lógica
   - Simplificada: `get_category_info()` - Apenas lê config.yaml

2. **lib/dependencies.sh**
   - Corrigida: `ensure_yq_installed()` - Adicione corpo à função

3. **commands/install/python/.category** → **config.yaml**
4. **commands/install/nodejs/.category** → **config.yaml**
5. **commands/install/python/tools/.category** → **config.yaml**

### Arquivos de Documentação Atualizados

1. **docs/QUICK_START.md**
   - Atualizada lógica de detecção
   - Novos exemplos com config.yaml
   - FAQ atualizado

2. **docs/SUBCATEGORIES.md**
   - Explicação detalhada da nova lógica
   - Exemplos atualizados
   - Troubleshooting revisado

## ✅ Testes Realizados

- [x] Lista categoria principal: `./susa setup`
- [x] Lista subcategoria: `./susa setup python`
- [x] Lista sub-subcategoria: `./susa setup python tools`
- [x] Executa comando direto: `./susa setup asdf`
- [x] Executa comando em subcategoria: `./susa setup python pip`
- [x] Executa comando nível 3: `./susa setup python tools venv`

## 🎁 Benefícios

1. **Mais Intuitivo** 
   - "Tem script = é executável" é uma lógica natural

2. **Mais Consistente**
   - Todos os itens usam o mesmo formato de arquivo

3. **Mais Simples**
   - Um único tipo de arquivo para gerenciar
   - Menos arquivos ocultos (sem `.category`)

4. **Mais Robusto**
   - Verifica existência real do script
   - Evita configurações inválidas

## 📚 Migração de Projetos Existentes

Se você tem comandos no formato antigo:

```bash
# Converter .category para config.yaml
mv commands/categoria/.category commands/categoria/config.yaml

# Verificar que comandos têm campo 'script:'
# (Adicionar se estiver faltando)
```

## 🔮 Próximos Passos

- Sistema está pronto para uso em produção
- Documentação completa e atualizada
- Todos os testes passando

---

**Versão:** 2.0.0  
**Data:** 11/01/2026  
**Status:** ✅ Concluído e Testado
