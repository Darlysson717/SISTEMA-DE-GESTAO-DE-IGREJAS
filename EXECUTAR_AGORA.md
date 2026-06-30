# Executar Agora - Deploy em 3 Passos

## 🎯 Você já tem:
- ✅ Firebase configurado
- ✅ Service Account criada
- ✅ CLI Supabase instalada

## ⚡ Faltam apenas 3 passos (15 minutos):

---

### 1️⃣ CONFIGURAR SECRETS (5 min)

```bash
cd "c:\Users\darly\Desktop\app iadet"
supabase login
supabase link --project_ref SEU_PROJECT_ID

# Configure os 3 secrets:
supabase secrets set FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxxxx@app-iadet.iam.gserviceaccount.com
supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
supabase secrets set PROJECT_ID=app-iadet
```

**Onde pegar os valores:**
- `FIREBASE_CLIENT_EMAIL` e `FIREBASE_PRIVATE_KEY`: Do arquivo JSON da Service Account
- `PROJECT_ID`: Firebase Console → Project Settings

---

### 2️⃣ FAZER DEPLOY (2 min)

```bash
supabase functions deploy enviar-notificacao
```

**Aguardar:**
```
Uploading... Compiling... Deploying...
Status: ACTIVE ✅
```

---

### 3️⃣ INTEGRAR NO FLUTTER (10 min)

Adicione este código onde você cria/cancela agendamentos:

```dart
// Depois de salvar no banco, adicione:
if (profissional['fcm_token'] != null) {
  await Supabase.instance.client.functions.invoke(
    'enviar-notificacao',
    body: {
      'tokenFcm': profissional['fcm_token'],
      'titulo': 'Novo Agendamento',
      'corpo': 'Você tem um novo agendamento',
    },
  );
}
```

---

## ✅ Pronto!

Depois disso:
- ✅ Notificações IMEDIATAS (até 10s)
- ✅ Sistema 100% automático
- ✅ Seguro e escalável

**Boa implementação!** 🚀