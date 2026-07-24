# 🧪 Guia de Teste — Sistema de Atualização via GitHub

Este guia explica como testar cada camada do sistema de atualização implementado.

---

## 📋 Pré-requisitos

1. **App instalado em um dispositivo Android** (ou emulador)
2. **Firebase configurado** com FCM funcionando
3. **Supabase configurado** com a tabela `app_config` criada
4. **GitHub CLI (`gh`) instalado** (opcional, para testes manuais)
5. **curl** instalado (para testar a Edge Function)

---

## 🧪 Teste 1: Verificação Passiva na Abertura do App

**Objetivo:** Verificar se o app detecta automaticamente uma nova versão no GitHub.

### Passos:

1. **Verifique a versão atual do app:**
   ```bash
   flutter --version
   # Anote a versão do pubspec.yaml: 1.0.2+1
   ```

2. **Crie uma release no GitHub com versão superior:**
   ```bash
   # Exemplo: criar release v1.1.0
   gh release create v1.1.0 \
     --title "v1.1.0" \
     --notes "## Novidades\n- Correção de bugs\n- Melhorias de performance"
   ```

3. **Anexe um APK à release:**
   ```bash
   # Build do APK
   flutter build apk --build-name=1.1.0 --build-number=1

   # Upload do APK para a release
   gh release upload v1.1.0 build\app\outputs\flutter-apk\app-release.apk
   ```

4. **Abra o app no dispositivo:**
   - O `appUpdateProvider` será executado automaticamente
   - Um **overlay azul** deve aparecer com:
     - Título: "Nova versão disponível"
     - Versão: "1.1.0"
     - Botão: "Baixar v1.1.0"

5. **Toque no botão:**
   - Deve abrir o navegador com a página da release do GitHub
   - Ou fazer download direto do APK

### ✅ Critérios de Sucesso:
- [ ] Overlay de atualização aparece na abertura do app
- [ ] Versão exibida é correta (1.1.0)
- [ ] Botão de download funciona

---

## 🧪 Teste 2: Notificação Push (FCM)

**Objetivo:** Verificar se a notificação push chega no dispositivo quando uma nova versão é lançada.

### Passos:

1. **Certifique-se de que o app está logado** e o token FCM foi registrado no Supabase:
   ```sql
   -- Verificar se há tokens FCM salvos
   SELECT id, email, fcm_token IS NOT NULL as tem_token
   FROM profiles
   WHERE fcm_token IS NOT NULL;
   ```

2. **Teste manual da Edge Function:**
   ```bash
   # Substitua pelos seus valores
   SUPABASE_URL="https://xxxxx.supabase.co"
   SUPABASE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

   curl -X POST "$SUPABASE_URL/functions/v1/notificar-atualizacao" \
     -H "Authorization: Bearer $SUPABASE_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "versao": "1.2.0",
       "apk_url": "https://github.com/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases/download/v1.2.0/app-release.apk",
       "changelog": "## Novidades\n- Feature A\n- Feature B"
     }'
   ```

3. **Verifique o dispositivo:**
   - Uma notificação push deve aparecer na barra de notificações
   - Título: "Nova versão disponível 🎉"
   - Corpo: "Versão 1.2.0 já está disponível para download!"

4. **Toque na notificação:**
   - O app deve abrir
   - O overlay de atualização deve aparecer automaticamente

### ✅ Critérios de Sucesso:
- [ ] Notificação push chega no dispositivo
- [ ] Título e corpo estão corretos
- [ ] Ao tocar, o app abre e mostra o overlay de atualização

---

## 🧪 Teste 3: Atualização Forçada (Versão Mínima)

**Objetivo:** Verificar se o app bloqueia o uso quando a versão local é inferior à mínima configurada.

### Passos:

1. **Execute o SQL no Supabase:**
   ```sql
   -- Definir versão mínima como 99.0.0 (ninguém terá essa versão)
   SELECT atualizar_versao_minima('99.0.0');
   ```

2. **Abra o app:**
   - A tela normal NÃO deve aparecer
   - Deve aparecer uma **tela azul bloqueante** com:
     - Título: "Atualização Obrigatória"
     - Texto: "Sua versão do aplicativo está desatualizada..."
     - Versão necessária: "99.0.0"
     - Botão: "Atualizar Agora"

3. **Tente navegar pelo app:**
   - Não deve ser possível voltar ou acessar outras telas
   - O botão "Voltar" do Android não deve funcionar

4. **Toque em "Atualizar Agora":**
   - Deve abrir o navegador na página de releases do GitHub

5. **Restaure a versão mínima:**
   ```sql
   -- Voltar para a versão atual
   SELECT atualizar_versao_minima('1.0.0');
   ```

### ✅ Critérios de Sucesso:
- [ ] Tela de atualização obrigatória aparece
- [ ] App fica bloqueado (não permite navegação)
- [ ] Botão "Atualizar Agora" funciona
- [ ] Após restaurar `min_version`, o app funciona normalmente

---

## 🧪 Teste 4: GitHub Action Automático

**Objetivo:** Verificar se o GitHub Action dispara automaticamente ao publicar uma release.

### Passos:

1. **Configure os secrets no GitHub:**
   - Vá para `Settings > Secrets and variables > Actions`
   - Adicione:
     - `SUPABASE_FUNCTION_URL`: `https://xxxxx.supabase.co/functions/v1`
     - `SUPABASE_SERVICE_ROLE_KEY`: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

2. **Crie uma nova release:**
   ```bash
   gh release create v1.3.0 \
     --title "v1.3.0 - Teste Automático" \
     --notes "Testando GitHub Action"
   ```

3. **Acompanhe o workflow:**
   - Vá para `Actions` no GitHub
   - O workflow "Notificar Atualização via Push" deve aparecer
   - Clique para ver os logs

4. **Verifique o resultado:**
   - O step "Notificar usuários via Supabase" deve ter status ✅
   - Deve mostrar: "✅ Notificação de atualização enviada!"

5. **Verifique no dispositivo:**
   - A notificação push deve chegar em até 1 minuto

### ✅ Critérios de Sucesso:
- [ ] Workflow é executado automaticamente
- [ ] Todos os steps passam (✅)
- [ ] Notificação push chega no dispositivo

---

## 🧪 Teste 5: Fluxo Completo End-to-End

**Objetivo:** Simular o fluxo real de atualização do usuário.

### Passos:

1. **Prepare o ambiente:**
   ```bash
   # App instalado: versão 1.0.0
   # Supabase: min_version = '1.0.0'
   # GitHub: release mais recente = v1.0.0
   ```

2. **Você (como admin) publica uma nova versão:**
   ```bash
   gh release create v1.5.0 \
     --title "v1.5.0 - Grande Atualização" \
     --notes "## O que há de novo\n- Interface redesenhada\n- Novos serviços\n- Correções"
   
   flutter build apk --build-name=1.5.0 --build-number=5
   gh release upload v1.5.0 build\app\outputs\flutter-apk\app-release.apk
   ```

3. **GitHub Action dispara automaticamente** → notificação push enviada

4. **Usuário recebe a notificação:**
   - Toca na notificação
   - App abre com overlay de atualização
   - Lê o changelog
   - Toca em "Baixar v1.5.0"
   - Download do APK inicia

5. **Usuário instala o APK:**
   - Permite instalação de fontes desconhecidas
   - Instala o app
   - Abre o app atualizado

6. **Verificação final:**
   - App abre normalmente (sem overlay)
   - Versão exibida: 1.5.0+5

### ✅ Critérios de Sucesso:
- [ ] Notificação chega automaticamente
- [ ] Overlay de atualização funciona
- [ ] Download e instalação funcionam
- [ ] App atualizado funciona normalmente

---

## 🐛 Troubleshooting

### Notificação não chega:
```bash
# Verificar logs da Edge Function
# Vá para Supabase > Edge Functions > notificar-atualizacao > Logs

# Verificar token FCM no Supabase
SELECT id, email, LEFT(fcm_token, 20) as token_prefix
FROM profiles
WHERE fcm_token IS NOT NULL;
```

### App não detecta atualização:
```bash
# Testar API do GitHub diretamente
curl https://api.github.com/repos/Darlysson717/SISTEMA-DE-GESTAO-DE-IGREJAS/releases/latest

# Verificar se o app tem permissão de internet
# AndroidManifest.xml deve ter:
# <uses-permission android:name="android.permission.INTERNET" />
```

### GitHub Action falha:
```bash
# Verificar secrets
gh secret list

# Testar Edge Function manualmente
curl -X POST $SUPABASE_URL/functions/v1/notificar-atualizacao \
  -H "Authorization: Bearer $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"versao":"1.0.0","apk_url":"https://example.com","changelog":"teste"}'
```

---

## 📊 Checklist Rápido

- [ ] Teste 1: Verificação passiva na abertura
- [ ] Teste 2: Notificação push manual
- [ ] Teste 3: Atualização forçada (min_version)
- [ ] Teste 4: GitHub Action automático
- [ ] Teste 5: Fluxo completo E2E

---

## 🎯 Próximos Passos

Após todos os testes passarem:

1. **Deploy em produção:**
   - Execute `supabase/SETUP_APP_CONFIG.sql` no banco de produção
   - Configure os secrets do GitHub
   - Faça a primeira release de teste

2. **Monitore:**
   - Acompanhe os logs do GitHub Actions
   - Monitore a taxa de entrega de notificações no Firebase Console
   - Verifique se os usuários estão atualizando

3. **Otimize:**
   - Adicione analytics para rastrear quantos usuários atualizaram
   - Considere adicionar um botão "Lembrar depois" no overlay
   - Implemente atualizações incrementais (APK splits)