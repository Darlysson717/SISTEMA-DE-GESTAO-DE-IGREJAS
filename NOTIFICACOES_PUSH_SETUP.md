# Configuração de Push Notifications - Firebase Cloud Messaging

## 📋 Estrutura Implementada

### Serviço de Notificações
- **Localização:** `lib/src/nucleo/notificacoes/servico_notificacoes.dart`
- **Inicialização:** `lib/main.dart` (linha 34)
- **Integração com Login:** `lib/src/funcionalidades/autenticacao/apresentacao/controladores/controlador_autenticacao.dart`

### Funcionalidades
✅ Push notifications em foreground, background e terminated  
✅ Notificações locais para garantir exibição  
✅ Registro automático de token FCM após login  
✅ Remoção de token no logout  
✅ Atualização automática de token  
✅ Firebase Analytics integrado  

---

## 🔧 Configuração Android

### Arquivos Modificados
1. `android/app/build.gradle.kts` - Dependências Firebase + Core Library Desugaring
2. `android/app/src/main/AndroidManifest.xml` - Permissões e intent filters
3. `android/app/src/main/kotlin/com/desiadet/app/MainActivity.kt` - Package name correto
4. `android/app/google-services.json` - Configuração Firebase

### Permissões Adicionadas
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.INTERNET" />
```

---

## 🧪 Como Testar as Notificações

### ⚠️ IMPORTANTE: Como Enviar Notificação CORRETAMENTE

Para evitar atrasos de 2 minutos, siga estas instruções:

#### 1. Acesse o Firebase Console
- Vá para: https://console.firebase.google.com/
- Selecione o projeto: **app-iadet**

#### 2. Crie uma Nova Notificação
- Menu lateral: **Engage** → **Messaging**
- Clique em **"Nova campanha"** → **"Notificações"**

#### 3. Preencha os Dados
```
Título: TESTE
Texto: TESTe de notificação
```

#### 4. ⚠️ CONFIGURAÇÃO CRÍTICA - NÃO ADICIONE DADOS CUSTOMIZADOS
- **NÃO** adicione "Dados customizados" (deixe vazio)
- **NÃO** marque "Enviar mensagem de dados"
- Apenas preencha **Título** e **Texto**

#### 5. Envie o Teste
- Clique em **"Enviar teste"** (canto superior direito)
- Cole o **token FCM** do usuário
- Clique em **"Testar"**

---

## ⚡ Por Que as Notificações Demoram?

### Causa do Atraso de 2 Minutos

O atraso acontece quando você envia uma **mensagem de dados (data message)** ao invés de uma **mensagem de notificação (notification message)**.

#### ❌ ERRADO (causa atraso):
```json
{
  "to": "token_fcm",
  "data": {
    "titulo": "TESTE",
    "corpo": "TESTE"
  },
  "priority": "high"
}
```

#### ✅ CORRETO (entrega imediata):
```json
{
  "to": "token_fcm",
  "notification": {
    "title": "TESTE",
    "body": "TESTE"
  },
  "priority": "high",
  "android": {
    "priority": "high",
    "notification": {
      "channel_id": "high_importance_channel"
    }
  }
}
```

### Quando Usar Cada Tipo

**Notification Message (use este para notificações simples):**
- Apenas título e texto
- Firebase exibe automaticamente
- Entrega IMEDIATA
- App não precisa estar aberto

**Data Message (use para ações customizadas):**
- Contém dados customizados
- App processa a mensagem
- Pode ter atraso de até 2 minutos
- Requer app em background ou foreground

---

## 🔍 Como Verificar se Está Funcionando

### 1. Verificar Logs no Terminal
Quando o app estiver rodando, você verá:
```
✅ Serviço de notificações inicializado com sucesso
📱 Permissão de notificações: AuthorizationStatus.authorized
🔑 Token FCM obtido: eXaMpLeToKeN...
✅ Token FCM salvo no Supabase para usuário <user-id>
```

### 2. Verificar Token no Supabase
```sql
SELECT id, email, full_name, fcm_token 
FROM public.profiles 
WHERE fcm_token IS NOT NULL;
```

### 3. Testar com App Fechado
1. Feche o app completamente (não minimize)
2. Envie notificação pelo Firebase Console (apenas título e texto)
3. A notificação deve aparecer em **até 10 segundos**

---

## 📱 Estados do App e Comportamento

### App em Foreground (ABERTO)
- ✅ Notificação aparece na barra do Android
- ✅ Log no terminal: `📬 Notificação recebida (foreground)`

### App em Background (MINIMIZADO)
- ✅ Notificação aparece na barra do Android
- ✅ Firebase exibe automaticamente

### App em Terminated (FECHADO)
- ✅ Notificação aparece na barra do Android
- ✅ Firebase exibe automaticamente
- ✅ Ao tocar, app abre

---

## 🛠️ Solução de Problemas

### Problema: Notificação demora 2 minutos
**Solução:** Envie apenas título e texto, SEM dados customizados

### Problema: Notificação não aparece com app fechado
**Solução:** 
1. Verifique se o app tem permissão de notificações
2. Verifique se o canal "Notificações Importantes" está ativado
3. Vá em Configurações → Apps → DESIADET → Notificações

### Problema: Token não é salvo no Supabase
**Solução:**
1. Verifique se o usuário está logado
2. Verifique se a coluna `fcm_token` existe na tabela `profiles`
3. Execute: `SELECT * FROM public.profiles LIMIT 1;` para verificar

### Problema: App crash ao receber notificação
**Solução:**
1. Verifique os logs no terminal
2. Verifique se o `google-services.json` está correto
3. Execute `flutter clean` e `flutter run` novamente

---

## 📊 Firebase Analytics

O Firebase Analytics está configurado e coletando dados automaticamente:
- Abertura do app
- Eventos de login/logout
- Visualizações de telas
- Interações com notificações

Para ver os dados:
- Firebase Console → Analytics → Dashboard

---

## 🔐 Segurança

- Tokens FCM são salvos de forma segura no Supabase
- Apenas usuários autenticados recebem notificações
- Token é removido no logout
- Token é atualizado automaticamente quando necessário

---

## 📝 Notas Técnicas

### Canal de Notificações (Android)
- **ID:** `high_importance_channel`
- **Nome:** `Notificações Importantes`
- **Prioridade:** Alta
- **Som:** Padrão do sistema

### Prioridade das Notificações
- **Foreground:** Alta (exibe notificação local)
- **Background:** Alta (gerenciado pelo Firebase)
- **Terminated:** Alta (gerenciado pelo Firebase)

### Token FCM
- Obtido automaticamente na inicialização
- Salvo no Supabase após login
- Atualizado automaticamente quando expira
- Removido no logout

---

## ✅ Checklist de Verificação

- [ ] App compila sem erros
- [ ] Firebase inicializado corretamente
- [ ] Permissão de notificações solicitada
- [ ] Token FCM obtido
- [ ] Token salvo no Supabase
- [ ] Notificação recebida com app aberto
- [ ] Notificação recebida com app fechado
- [ ] Firebase Analytics coletando dados

---

## 🚀 Próximos Passos

1. Teste as notificações seguindo o guia acima
2. Verifique os logs no terminal
3. Confirme o token no Supabase
4. Envie uma notificação de teste
5. Verifique se chega em até 10 segundos

**Importante:** Sempre envie apenas título e texto, sem dados customizados, para garantir entrega imediata!