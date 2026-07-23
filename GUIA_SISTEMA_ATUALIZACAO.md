# Guia do Sistema de Atualização

## 📋 Visão Geral

O sistema de atualização funciona da seguinte forma:
1. O app verifica a versão mais recente na API do GitHub
2. Se falhar (rate limit, erro, etc.), usa um arquivo JSON de fallback hospedado no GitHub Pages
3. Compara com a versão local instalada
4. Se houver atualização, exibe um card obrigatório

## 🔧 Arquivos Modificados

### 1. `pubspec.yaml`
- **Versão atual**: `1.0.6+1`
- Quando atualizar, incremente o build number: `1.0.7+2`, `1.0.8+3`, etc.

### 2. `lib/src/funcionalidades/inicio/apresentacao/provedores/provedores_atualizacao.dart`
- Adicionado logs de debug para facilitar troubleshooting
- Sistema de fallback implementado (GitHub → JSON)
- Logs aparecem no console do Android Studio/VS Code

### 3. `version.json` (raiz do projeto)
- Arquivo de fallback hospedado no GitHub Pages
- Contém informações da versão mais recente
- **NÃO é um asset do Flutter** (não está no pubspec.yaml)

### 4. GitHub Pages
- O `version.json` deve estar na branch `gh-pages` ou na pasta `docs/`
- Acessível em: `https://darlysson717.github.io/SISTEMA-DE-GESTAO-DE-IGREJAS/version.json`

## 🚀 Como Publicar uma Nova Versão

### Passo 1: Atualizar a versão no `pubspec.yaml`

```yaml
version: 1.0.7+2  # Incremente o build number!
```

### Passo 2: Commit e tag

```bash
git add .
git commit -m "versão 1.0.7"
git tag v1.0.7
git push origin main
git push origin v1.0.7
```

### Passo 3: Criar Release no GitHub

1. Acesse: https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases
2. Clique em "Draft a new release"
3. Selecione a tag `v1.0.7`
4. Adicione título e descrição (changelog)
5. **IMPORTANTE**: Faça upload do APK como asset
   - Nome do APK: `DESIADET-1.0.7.apk`
   - Gerar APK: `flutter build apk --build-name=1.0.7 --build-number=2`
6. Publique a release

### Passo 4: Atualizar o `version.json` (fallback)

Edite o arquivo `version.json` na raiz do projeto:

```json
{
  "version": "1.0.7",
  "downloadUrl": "https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases/latest",
  "changelog": "## O que há de novo?\n\n- Novas funcionalidades\n- Correções de bugs\n\n### Como atualizar\n\n1. Baixe o APK da release\n2. Instale no dispositivo",
  "apkUrl": "https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases/latest",
  "minVersion": "1.0.0",
  "forceUpdate": false
}
```

### Passo 5: Deploy no GitHub Pages

```bash
# Opção 1: Se usar branch gh-pages
git add version.json
git commit -m "atualiza version.json para 1.0.7"
git push origin main
# Depois execute: git subtree push --prefix part origin gh-pages

# Opção 2: Se usar pasta docs/
git add version.json docs/version.json
git commit -m "atualiza version.json para 1.0.7"
git push origin main
```

O `version.json` estará disponível em:
`https://darlysson717.github.io/SISTEMA-DE-GESTAO-DE-IGREJAS/version.json`

## 🐛 Debug e Troubleshooting

### Verificar logs no Android

1. Conecte o dispositivo Android
2. Abra o Android Studio ou VS Code
3. Execute: `flutter run`
4. Filtre o log por "🔍" ou "❌" ou "✅"

### Logs esperados (sucesso)

```
🔍 Verificando atualização...
   Versão local: 1.0.6+1
✅ Release encontrada: v1.0.7
   Tag da release: v1.0.7
   Versão remota: 1.0.7
   Comparação local vs remota: -1
✅ Atualização disponível: 1.0.7
```

### Logs esperados (fallback)

```
🔍 Verificando atualização...
   Versão local: 1.0.6+1
⚠️ GitHub API retornou status: 403
🔍 Tentando fallback (GitHub Pages): https://darlysson717.github.io/SISTEMA-DE-GESTAO-DE-IGREJAS/version.json
✅ Versão obtida do fallback: 1.0.7
✅ Atualização disponível: 1.0.7
```

### Logs esperados (app atualizado)

```
🔍 Verificando atualização...
   Versão local: 1.0.7+2
✅ Release encontrada: v1.0.7
   Tag da release: v1.0.7
   Versão remota: 1.0.7
   Comparação local vs remota: 0
✅ App já está atualizado
```

## ⚠️ Problemas Comuns

### 1. Card de atualização não aparece

**Causa**: A versão local é igual ou maior que a remota

**Solução**: Verifique os logs e compare as versões

### 2. GitHub API retorna 403 (rate limit)

**Causa**: Muitas requisições à API do GitHub

**Solução**: O sistema usa automaticamente o fallback do Vercel

### 3. APK não é encontrado

**Causa**: O APK não foi adicionado como asset na release

**Solução**: 
- Adicione o APK na release do GitHub
- OU atualize o `version.json` com o link direto do APK

### 4. Fallback não funciona

**Causa**: O `version.json` não está acessível no GitHub Pages

**Solução**:
- Verifique se o GitHub Pages está ativo: https://darlysson717.github.io/SISTEMA-DE-GESTAO-DE-IGREJAS/version.json
- Verifique se o arquivo está na branch `gh-pages` ou na pasta `docs/`
- Acesse a URL diretamente no navegador para confirmar

## 📱 Testando o Sistema

### Teste 1: Simular atualização

1. Altere o `version.json` para uma versão MAIOR que a instalada:
   ```json
   {
     "version": "99.0.0",
     ...
   }
   ```

2. Faça deploy no Vercel
3. Abra o app no Android
4. O card de atualização deve aparecer

### Teste 2: Simular app atualizado

1. Altere o `version.json` para uma versão MENOR ou IGUAL:
   ```json
   {
     "version": "1.0.0",
     ...
   }
   ```

2. Faça deploy no Vercel
3. Abra o app no Android
4. O card NÃO deve aparecer

### Teste 3: Verificar logs

1. Execute o app em modo debug
2. Verifique os logs no console
3. Confirme se a versão local e remota estão corretas

## 🔄 Fluxo Completo de Atualização

```
┌─────────────────────────────────────────┐
│  App abre na tela inicial               │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Lê versão local (PackageInfo)          │
│  Ex: 1.0.6+1                            │
└──────────────┬──────────────────────────┘
               │
               ▼
┌─────────────────────────────────────────┐
│  Busca versão remota (GitHub API)       │
│  GET /repos/.../releases/latest         │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴───────┐
       │               │
       ▼               ▼
  ┌───────┐    ┌──────────────┐
  │ 200 OK│    │ Erro/403/404 │
  └───┬───┘    └──────┬───────┘
      │               │
      ▼               ▼
  ┌─────────────┐  ┌──────────────────┐
  │ Parse JSON  │  │ Tenta fallback   │
  │ tag_name    │  │ version.json     │
  └──────┬──────┘  └────────┬─────────┘
         │                  │
         └──────────┬───────┘
                    │
                    ▼
         ┌──────────────────────┐
         │ Compara versões      │
         │ local vs remota      │
         └──────────┬───────────┘
                    │
          ┌─────────┴─────────┐
          │                   │
          ▼                   ▼
    ┌──────────┐      ┌──────────────┐
    │ Atualizado│      │ Desatualizado│
    │return null│      │ Mostra card  │
    └──────────┘      └──────────────┘
```

## 📝 Checklist de Publicação

- [ ] Atualizar `pubspec.yaml` com nova versão
- [ ] Commit das alterações
- [ ] Criar tag: `git tag vX.Y.Z`
- [ ] Push da tag: `git push origin vX.Y.Z`
- [ ] Criar release no GitHub com APK
- [ ] Atualizar `version.json` com nova versão
- [ ] Commit e push do `version.json`
- [ ] Atualizar GitHub Pages (se necessário)
- [ ] Testar no dispositivo Android

## 🎯 Comandos Úteis

```bash
# Ver versão atual
grep "version:" pubspec.yaml

# Gerar APK
flutter build apk --build-name=1.0.7 --build-number=2

# Ver logs do app
flutter run --verbose

# Testar API do GitHub
curl https://api.github.com/repos/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases/latest

# Testar fallback
curl https://darlysson717.github.io/SISTEMA-DE-GESTAO-DE-IGREJAS/version.json
```

## 📞 Suporte

Se o sistema não funcionar:
1. Verifique os logs no console
2. Confira se a tag no GitHub está no formato `vX.Y.Z`
3. Confira se o APK está na release
4. Confira se o `version.json` está acessível
5. Verifique se a versão no `pubspec.yaml` é menor que a remota