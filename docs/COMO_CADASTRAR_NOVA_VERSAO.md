# Como Cadastrar uma Nova Versão do App

Este guia explica passo a passo como publicar uma nova versão do aplicativo usando o sistema de atualização automática.

---

## 📋 Pré-requisitos

- [ ] Acesso ao repositório GitHub: https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS
- [ ] Acesso ao Supabase do projeto
- [ ] Flutter instalado e configurado
- [ ] APK compilado da nova versão

---

## 🚀 Passo a Passo Completo

### **PASSO 1: Atualizar a Versão no App (PRIMEIRO!)**

1. Abra o arquivo `pubspec.yaml`
2. Localize a linha com `version:`
3. Atualize para a nova versão:

```yaml
# Antes
version: 1.0.0+1

# Depois (exemplo)
version: 1.1.0+2
```

**Formato:** `versão+build`
- **Versão:** Formato semântico (ex: `1.1.0`, `2.0.0`)
- **Build:** Número inteiro crescente (ex: `1`, `2`, `3`)

4. Salve o arquivo

⚠️ **IMPORTANTE:** Faça isso PRIMEIRO, antes de compilar o APK!

---

### **PASSO 2: Compilar o APK (DEPOIS da versão)**

1. Abra o terminal na pasta do projeto
2. Execute o comando:

```bash
flutter build apk --release
```

3. Aguarde a compilação (pode demorar alguns minutos)
4. O APK estará em: `build\app\outputs\flutter-apk\app-release.apk`

**Dica:** Verifique o tamanho do APK antes de continuar:
```bash
ls -lh build\app\outputs\flutter-apk\app-release.apk
```

✅ O APK já terá a nova versão embutida!

---

### **PASSO 3: Criar Release no GitHub**

1. Acesse: https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases

2. Clique no botão **"Draft a new release"** (lado direito)

3. **Preencha os campos:**

   **Tag version:**
   ```
   v1.1.0
   ```
   ⚠️ **Importante:** Use o prefixo `v` + mesma versão do `pubspec.yaml`

   **Release title:**
   ```
   Versão 1.1.0
   ```

   **Description (changelog):**
   ```markdown
   ### Nova versão 1.1.0
   
   **Correções:**
   - Correção do bug do calendário de agendamentos
   - Corrigido problema ao clicar em datas disponíveis
   
   **Melhorias:**
   - Interface mais responsiva
   - Performance otimizada
   
   **Novas funcionalidades:**
   - Sistema de atualização automática via Supabase
   ```

4. **Faça upload do APK:**
   - Role até a seção "Attach binaries by dropping them here or selecting them"
   - Arraste o arquivo `app-release.apk` ou clique para selecionar
   - Aguarde o upload (pode demorar dependendo do tamanho)

5. **Marque as opções:**
   - ✅ "This is a pre-release" (se for versão de teste)
   - ❌ "Set as latest release" (deixe desmarcado por enquanto)

6. Clique em **"Publish release"**

---

### **PASSO 4: Copiar a URL do APK**

Após publicar a release, você precisará da URL de download:

1. Na página da release, clique no arquivo `app-release.apk`
2. Copie a URL do navegador

**Formato da URL:**
```
https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases/download/v1.1.0/app-release.apk
```

**Dica:** Teste a URL colando no navegador - deve iniciar o download automaticamente.

---

### **PASSO 5: Cadastrar a Versão no Supabase**

1. Acesse o Supabase: https://supabase.com/dashboard

2. Selecione seu projeto

3. Clique em **"SQL Editor"** (menu lateral esquerdo)

4. Clique em **"New query"**

5. Cole o seguinte SQL (ajuste os valores):

```sql
INSERT INTO app_versions (
  version,
  build_number,
  apk_download_url,
  apk_file_name,
  changelog,
  is_mandatory,
  is_active
) VALUES (
  '1.1.0',  -- Mesma versão da tag do GitHub
  2,        -- Mesmo build number do pubspec.yaml
  'https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases/download/v1.1.0/app-release.apk',
  'app-release.apk',
  '### Nova versão 1.1.0
- Correção do bug do calendário
- Melhorias na interface
- Performance otimizada',
  false,  -- false = atualização opcional, true = obrigatória
  true    -- true = versão ativa
);
```

6. Clique em **"Run"** (ou pressione Ctrl+Enter)

7. Você verá a mensagem: "Success. No rows returned"

---

### **PASSO 6: Verificar se Funcionou**

1. No Supabase, vá em **"Table Editor"**

2. Selecione a tabela `app_versions`

3. Você verá a nova versão cadastrada:

| version | build_number | apk_download_url | is_mandatory | is_active | released_at |
|---------|--------------|------------------|--------------|-----------|-------------|
| 1.1.0   | 2            | https://...      | false        | true      | 2026-07-24  |

---

### **PASSO 7: Testar no App**

1. Abra o app em um dispositivo/emulador

2. O app irá:
   - Consultar o Supabase
   - Comparar versão local (1.0.0+1) vs remota (1.1.0+2)
   - Mostrar o overlay de atualização

3. Clique em **"Baixar v1.1.0"**

4. O navegador abrirá e fará o download do APK

5. Instale o APK manualmente

---

## 📊 Gerenciamento de Versões

### **Ver todas as versões cadastradas:**

```sql
SELECT 
  version, 
  build_number, 
  is_mandatory, 
  is_active, 
  released_at 
FROM app_versions 
ORDER BY released_at DESC;
```

### **Desativar uma versão antiga:**

```sql
UPDATE app_versions 
SET is_active = false 
WHERE version = '1.0.0';
```

### **Marcar como atualização obrigatória:**

```sql
UPDATE app_versions 
SET is_mandatory = true 
WHERE version = '1.1.0';
```

### **Ver apenas versões ativas:**

```sql
SELECT * FROM app_versions WHERE is_active = true ORDER BY released_at DESC;
```

---

## 🔄 Próxima Atualização

Quando precisar lançar uma nova versão, repita todos os passos:

1. **Compile o APK** → `flutter build apk --release`
2. **Atualize o pubspec.yaml** → `version: 1.2.0+3`
3. **Crie release no GitHub** → Tag `v1.2.0` + upload do APK
4. **Cadastre no Supabase** → INSERT com nova versão
5. **Teste no app** → Verifique se o overlay aparece

---

## ⚠️ Regras Importantes

### **Versionamento:**
- ✅ Sempre incremente a versão (não pode repetir)
- ✅ Sempre incremente o build number (não pode repetir)
- ✅ Use o formato semântico: `MAJOR.MINOR.PATCH+BUILD`
  - Ex: `1.0.0`, `1.1.0`, `2.0.0`
- ✅ Build number sempre crescente: `1`, `2`, `3`, `4`...

### **GitHub:**
- ✅ Tag deve começar com `v` (ex: `v1.1.0`)
- ✅ Nome do APK deve ser consistente (ex: sempre `app-release.apk`)
- ✅ Changelog deve ser claro e objetivo

### **Supabase:**
- ✅ Apenas UMA versão ativa por vez (a mais recente)
- ✅ Versões antigas devem ser desativadas (`is_active = false`)
- ✅ Use `is_mandatory = true` apenas para atualizações críticas

---

## 🐛 Troubleshooting

### **Problema: App não detecta atualização**

**Solução:**
1. Verifique se a versão no Supabase é maior que a local
2. Verifique se `is_active = true` na tabela
3. Verifique se a URL do APK está correta (teste no navegador)
4. Verifique se o build number no Supabase > build number no app

### **Problema: Overlay não aparece**

**Solução:**
1. Verifique se o app tem permissão de internet
2. Verifique se o Supabase está acessível
3. Verifique os logs do app para erros

### **Problema: Download não inicia**

**Solução:**
1. Teste a URL do APK no navegador
2. Verifique se a release no GitHub está pública
3. Verifique se o APK foi enviado corretamente na release

---

## 📝 Exemplo Prático Completo

### **Cenário:** Lançar versão 1.1.0 com correção de bug

### **1. pubspec.yaml (PRIMEIRO):**
```yaml
version: 1.1.0+2
```

### **2. Compilar (DEPOIS):**
```bash
flutter build apk --release
```

### **3. GitHub Release:**
- Tag: `v1.1.0`
- Upload: `app-release.apk`
- Changelog: Descrição das mudanças

### **4. URL do APK:**
```
https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases/download/v1.1.0/app-release.apk
```

### **5. SQL no Supabase:**
```sql
INSERT INTO app_versions (
  version,
  build_number,
  apk_download_url,
  apk_file_name,
  changelog,
  is_mandatory,
  is_active
) VALUES (
  '1.1.0',
  2,
  'https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases/download/v1.1.0/app-release.apk',
  'app-release.apk',
  '### Versão 1.1.0
- Correção do bug do calendário',
  false,
  true
);
```

### **6. Testar:**
- Abrir o app
- Overlay deve aparecer
- Download deve funcionar

---

## ✅ Checklist Final

Antes de publicar, verifique:

- [ ] **Versão atualizada no `pubspec.yaml`** (PRIMEIRO!)
- [ ] APK compilado com sucesso (DEPOIS da versão)
- [ ] Release criada no GitHub
- [ ] APK enviado na release
- [ ] URL do APK testada no navegador
- [ ] Versão cadastrada no Supabase
- [ ] Build number correto no Supabase
- [ ] `is_active = true` no Supabase
- [ ] App testado e funcionando

---

Pronto! Agora você sabe como cadastrar uma nova versão do app! 🎉