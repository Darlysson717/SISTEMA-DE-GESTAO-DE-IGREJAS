# Verificar o que Já Existe

## 🎯 Objetivo

Verificar se os passos anteriores (secrets e deploy) já foram executados.

---

## 📋 Checklist de Verificação

### 1. Verificar se os Secrets Estão Configurados

```bash
supabase secrets list
```

**Se você ver isso, os secrets JÁ estão configurados:**
```
Name                  Value
FIREBASE_CLIENT_EMAIL firebase-adminsdk-xxxxx@app-iadet.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY  eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
PROJECT_ID            app-iadet
```

**Se aparecer vazio ou erro, precisa configurar:**
```bash
supabase secrets set FIREBASE_CLIENT_EMAIL=...
supabase secrets set FIREBASE_PRIVATE_KEY=...
supabase secrets set PROJECT_ID=app-iadet
```

---

### 2. Verificar se a Edge Function Está Deployada

```bash
supabase functions list
```

**Se você ver isso, a função JÁ está deployada:**
```
Name                  Status
enviar-notificacao    ACTIVE
```

**Se não aparecer, precisa fazer deploy:**
```bash
supabase functions deploy enviar-notificacao
```

---

### 3. Verificar se o Código Mudou

Compare o arquivo atual com o que foi deployado:

**Arquivo atual:** `supabase/functions/enviar-notificacao/index.ts`

**Última modificação:** Verifique a data de modificação do arquivo

**Se você modificou o código DEPOIS do último deploy, precisa reimplantar:**
```bash
supabase functions deploy enviar-notificacao
```

---

## ✅ Cenário 1: Tudo Já Está Pronto

Se você verificou e:
- ✅ Secrets estão configurados
- ✅ Função está ACTIVE
- ✅ Código não foi modificado desde o último deploy

**Então NÃO precisa fazer nada!**

Apenas siga para o **Passo 3: Integrar no Flutter**

---

## ⏳ Cenário 2: Apenas Integração Flutter

Se você verificou e:
- ✅ Secrets configurados
- ✅ Função deployada e ACTIVE
- ✅ Apenas falta usar no Flutter

**Então faça apenas o Passo 3:**

```dart
// Adicione onde cria/cancela agendamentos
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

## 🔄 Cenário 3: Apenas Reimplantar

Se você verificou e:
- ✅ Secrets configurados
- ✅ Função existe mas código foi modificado
- ⏳ Precisa reimplantar

**Execute:**
```bash
supabase functions deploy enviar-notificacao
```

---

## ❌ Cenário 4: Tudo Precisa ser Feito

Se você verificou e:
- ❌ Secrets não configurados
- ❌ Função não deployada

**Execute os 3 passos:**
1. Configurar secrets
2. Fazer deploy
3. Integrar no Flutter

---

## 🎯 Resumo Rápido

### Verificação Rápida (2 minutos):

```bash
# 1. Verificar secrets
supabase secrets list

# 2. Verificar função
supabase functions list

# 3. Verificar logs (última execução)
supabase functions logs enviar-notificacao --tail 5
```

### Decisão:

| Se você ver... | Então... |
|----------------|----------|
| Secrets + Função ACTIVE | ✅ Pule para integração Flutter |
| Secrets + Função não existe | ⏳ Faça deploy |
| Sem secrets | ⏳ Configure secrets + deploy |
| Função ACTIVE + código modificado | 🔄 Reimplante |

---

## 💡 Dica

**Se você já fez o deploy anteriormente e não modificou o código, NÃO precisa fazer de novo!**

Apenas:
1. Verifique se a função está ACTIVE
2. Integre no Flutter
3. Teste

---

## 📝 Comandos Úteis

```bash
# Ver status de todas as funções
supabase functions list

# Ver logs da função
supabase functions logs enviar-notificacao

# Reimplantar (se modificou código)
supabase functions deploy enviar-notificacao

# Testar localmente
supabase functions serve enviar-notificacao
```

---

**Verifique primeiro, depois execute apenas o que falta!** 🔍