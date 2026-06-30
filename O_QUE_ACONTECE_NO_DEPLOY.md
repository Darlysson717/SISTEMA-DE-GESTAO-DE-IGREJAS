# O Que Acontece no Deploy? (Explicação Direta)

## 🎯 Comando
```bash
supabase functions deploy enviar-notificacao
```

---

## 📊 O Que Acontece (Passo a Passo Real)

### 1. Você Executa o Comando
```bash
supabase functions deploy enviar-notificacao
```

### 2. CLI Envia Arquivos para Supabase
```
Seu computador → Envia → Supabase
├── index.ts (código da função)
├── config.toml (configurações)
└── package.json (dependências)
```

### 3. Supabase Compila o Código
```
TypeScript (index.ts)
    ↓
JavaScript (index.js)
```

**O que é removido:**
- Tipos TypeScript
- Anotações de tipo
- Comentários

**O que é mantido:**
- Lógica do código
- Funções
- Variáveis

### 4. Cria um Container
```
Container Docker
├── Node.js (runtime)
├── Código JavaScript
├── Dependências npm
└── Variáveis de ambiente (secrets)
```

**Características:**
- Isolado (não mistura com outras funções)
- Escalável (pode ter várias cópias)
- Serverless (só roda quando chamado)

### 5. Replica na Edge Network
```
Supabase Edge Network
├── Região US East (Nova York)
├── Região US West (São Francisco)
├── Região Europa (Londres)
└── Região Ásia (Tóquio)
```

**Vantagem:** Função fica perto de todos os usuários = baixa latência

### 6. Ativa a Função
```
Status: DEPLOYING → ACTIVE

Quando ACTIVE:
✅ Função pronta para receber requisições
✅ URL pública disponível
✅ Secrets injetados como variáveis de ambiente
```

---

## 🔍 Como Verificar se Funcionou

### 1. Verificar Status
```bash
supabase functions list
```

**Saída:**
```
Name                  Status
enviar-notificacao    ACTIVE  ← Você quer ver isso!
```

### 2. Verificar Logs
```bash
supabase functions logs enviar-notificacao
```

**Saída esperada:**
```
2024-01-15T10:30:00Z - Function initialized
2024-01-15T10:30:00Z - Ready to receive requests
```

### 3. Testar
```bash
curl -X POST \
  'https://SEU_PROJECT_ID.supabase.co/functions/v1/enviar-notificacao' \
  -H 'Content-Type: application/json' \
  -d '{"tokenFcm": "...", "titulo": "Teste", "corpo": "Teste"}'
```

**Resposta esperada:**
```json
{
  "success": true,
  "messageId": "projects/app-iadet/messages/abc123",
  "message": "Notificação enviada com sucesso"
}
```

---

## 🔐 O Que Acontece com os Secrets?

### NÃO são enviados no deploy!
```
❌ FIREBASE_CLIENT_EMAIL (não enviado)
❌ FIREBASE_PRIVATE_KEY (não enviado)
❌ PROJECT_ID (não enviado)
```

### São injetados em runtime!
```
Quando a função é chamada:
1. Supabase carrega a função
2. Injeta secrets como variáveis de ambiente
3. Código acessa via Deno.env.get()
```

**Exemplo no código:**
```typescript
// Isso NÃO está no código deployado
const clientEmail = 'firebase-adminsdk@...'  // ❌

// Isso está no código deployado
const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL')  // ✅
// O valor é injetado em runtime pelo Supabase
```

---

## 💰 Quanto Custa?

### Plano Gratuito
- **500k invocações/mês** GRÁTIS
- Suficiente para ~10k usuários ativos

### Por Notificação
- ~$0.000001 (muito barato!)
- 1000 notificações = ~$0.001

---

## 🔄 Se Eu Modificar o Código?

```bash
# 1. Edite index.ts
# 2. Reimplantar
supabase functions deploy enviar-notificacao

# 3. Pronto! Nova versão ativa
```

**O que muda:**
- ✅ Novo código é implantado
- ✅ Versão anterior substituída
- ✅ Sem downtime (troca instantânea)

---

## 📝 Resumo Super Direto

**O que o deploy faz:**
1. Envia código TypeScript para Supabase
2. Compila para JavaScript
3. Cria container isolado
4. Replica em múltiplas regiões
5. Injeta secrets como variáveis de ambiente
6. Ativa a função

**Resultado:**
- ✅ Função disponível publicamente
- ✅ URL: `https://seu-projeto.supabase.co/functions/v1/enviar-notificacao`
- ✅ Segura (secrets não expostos)
- ✅ Escalável
- ✅ Baixa latência

---

## ✅ Checklist Rápido

- [ ] Executar: `supabase functions deploy enviar-notificacao`
- [ ] Verificar: `supabase functions list` → Status = ACTIVE
- [ ] Testar: Chamar a função e verificar se retorna sucesso

**Pronto!** 🚀