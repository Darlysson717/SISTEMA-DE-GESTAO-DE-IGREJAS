# Guia: Configurar GitHub Pages para o version.json

## 📌 Objetivo

Hospedar o arquivo `version.json` no GitHub Pages para servir como fallback do sistema de atualização.

**URL final**: `https://darlysson717.github.io/SISTEMA-DE-GESTAO-DE-IGREJAS/version.json`

---

## 🚀 Opção 1: Usando pasta `docs/` (MAIS FÁCIL)

### Passo 1: Criar a pasta `docs` no projeto

```bash
mkdir docs
```

### Passo 2: Copiar o `version.json` para a pasta `docs`

```bash
cp version.json docs/version.json
```

### Passo 3: Configurar o GitHub Pages

1. Acesse: https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/settings/pages
2. Em **Source**, selecione: **Deploy from a branch**
3. Em **Branch**, selecione: `main` / `docs`
4. Clique em **Save**

### Passo 4: Commit e push

```bash
git add docs/version.json
git commit -m "adiciona version.json no GitHub Pages"
git push origin main
```

### Passo 5: Aguardar deploy

- O GitHub Pages demora cerca de **2-5 minutos** para fazer o deploy
- Acesse: `https://darlysson717.github.io/SISTEMA-DE-GESTAO-DE-IGREJAS/version.json`
- Se aparecer o JSON, está funcionando!

---

## 🚀 Opção 2: Usando branch `gh-pages` (ALTERNATIVA)

### Passo 1: Criar a branch `gh-pages`

```bash
git checkout --orphan gh-pages
git rm -rf .
```

### Passo 2: Adicionar o `version.json`

```bash
# Copie o version.json para a raiz
cp ../main/version.json .
git add version.json
git commit -m "adiciona version.json para GitHub Pages"
git push origin gh-pages
```

### Passo 3: Configurar o GitHub Pages

1. Acesse: https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/settings/pages
2. Em **Source**, selecione: **Deploy from a branch**
3. Em **Branch**, selecione: `gh-pages` / `root`
4. Clique em **Save**

### Passo 4: Voltar para a branch main

```bash
git checkout main
```

---

## ✅ Verificar se funcionou

### Teste 1: Acessar a URL no navegador

Abra no navegador:
```
https://darlysson717.github.io/SISTEMA-DE-GESTAO-DE-IGREJAS/version.json
```

Você deve ver o JSON:
```json
{
  "version": "1.0.7",
  "downloadUrl": "https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases/latest",
  ...
}
```

### Teste 2: Usar curl

```bash
curl https://darlysson717.github.io/SISTEMA-DE-GESTAO-DE-IGREJAS/version.json
```

### Teste 3: Verificar no app

1. Execute o app no Android: `flutter run`
2. Verifique os logs no console
3. Se o GitHub API falhar, o app usará o fallback do GitHub Pages

---

## 🔄 Como atualizar o `version.json` no futuro

Sempre que lançar uma nova versão:

```bash
# 1. Edite o version.json com a nova versão
# 2. Commit e push
git add docs/version.json
git commit -m "atualiza version.json para 1.0.8"
git push origin main

# 3. Aguarde 2-5 minutos para o deploy
```

---

## ⚠️ Problemas Comuns

### 1. Página 404 ao acessar o `version.json`

**Causa**: GitHub Pages não está configurado ou o deploy não terminou

**Solução**:
- Verifique se o GitHub Pages está ativo nas configurações
- Aguarde 5-10 minutos após o primeiro deploy
- Verifique se o arquivo está na pasta `docs/` ou branch `gh-pages`

### 2. JSON não atualiza

**Causa**: Cache do navegador ou CDN

**Solução**:
- Limpe o cache do navegador
- Adicione `?v=2` no final da URL para forçar refresh
- Aguarde alguns minutos

### 3. App não encontra o `version.json`

**Causa**: URL incorreta ou arquivo não acessível

**Solução**:
- Verifique se a URL está correta no código
- Teste a URL diretamente no navegador
- Verifique se o arquivo tem permissões públicas

---

## 📋 Checklist de Configuração

- [ ] Criar pasta `docs/` ou branch `gh-pages`
- [ ] Copiar `version.json` para a pasta/branch
- [ ] Configurar GitHub Pages nas settings
- [ ] Commit e push
- [ ] Aguardar deploy (2-5 min)
- [ ] Testar URL no navegador
- [ ] Testar no app Android

---

## 🎯 Comandos Rápidos

```bash
# Criar pasta docs
mkdir docs

# Copiar version.json
cp version.json docs/version.json

# Commit e push
git add docs/version.json
git commit -m "adiciona version.json no GitHub Pages"
git push origin main

# Testar URL
curl https://darlysson717.github.io/SISTEMA-DE-GESTAO-DE-IGREJAS/version.json
```

---

## 📞 Suporte

Se tiver problemas:
1. Verifique as configurações do GitHub Pages
2. Confira se o arquivo está na pasta/branch correta
3. Teste a URL diretamente no navegador
4. Verifique os logs do app para ver se o fallback está sendo usado