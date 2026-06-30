# Como Funciona o Deploy da Edge Function

## 🚀 Passo 4: Implantar Edge Function

### Comando
```bash
supabase functions deploy enviar-notificacao
```

---

## 📊 O que Acontece Durante o Deploy?

### 1. **Upload do Código**

```
Seu computador                    Supabase
     │                                │
     │ 1. Envia index.ts              │
     │ 2. Envia config.toml           │
     │ 3. Envia package.json          │
     │                                │
     └───────────────────────────────>│
                                      │
```

**Arquivos enviados:**
- `index.ts` - Código da função
- `config.toml` - Configurações
- `package.json` - Dependências (se houver)

### 2. **Instalação de Dependências**

```bash
# Supabase instala dependências automaticamente
npm install
```

**Dependências instaladas:**
- `@supabase/supabase-js` (se necessário)
- Outras dependências do `package.json`

### 3. **Compilação TypeScript → JavaScript**

```
index.ts (TypeScript)
     │
     │ Compila
     ▼
index.js (JavaScript)
```

**Processo:**
- Verifica tipos TypeScript
- Remove type annotations
- Gera JavaScript executável

### 4. **Criação do Container**

```
Container Docker
├── Node.js runtime
├── Código JavaScript
├── Dependências
└── Variáveis de ambiente (secrets)
```

**Características:**
- Isolado (não interfere com outras funções)
- Escalável (pode ter múltiplas instâncias)
- Serverless (paga apenas pelo uso)

### 5. **Deploy no Edge Network**

```
┌─────────────────────────────────────────┐
│         Supabase Edge Network           │
│                                         │
│  ┌─────────────┐  ┌─────────────┐      │
│  │   Região 1  │  │   Região 2  │      │
│  │  (US East)  │  │  (US West)  │      │
│  └─────────────┘  └─────────────┘      │
│                                         │
│  Edge Function replicada em múltiplas  │
│  regiões para baixa latência           │
└─────────────────────────────────────────┘
```

**Vantagens:**
- ✅ Baixa latência (próximo aos usuários)
- ✅ Alta disponibilidade (múltiplas regiões)
- ✅ Escalável automaticamente

### 6. **Configuração de Secrets**

```
Supabase Dashboard
├── Functions
│   └── enviar-notificacao
│       ├── Secrets
│       │   ├── FIREBASE_CLIENT_EMAIL (criptografado)
│       │   ├── FIREBASE_PRIVATE_KEY (criptografado)
│       │   └── PROJECT_ID (público)
│       └── URL
│           └── https://...supabase.co/functions/v1/enviar-notificacao
```

**Secrets são injetados como variáveis de ambiente:**
```typescript
const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL')
const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')
```

### 7. **Ativação da Função**

```
Status: DEPLOYING → ACTIVE

Quando status = ACTIVE:
✅ Função pronta para receber requisições
✅ URL pública disponível
✅ Secrets configurados
```

---

## 🔍 Verificar se Deploy Funcionou

### 1. Verificar Status

```bash
supabase functions list
```

**Saída esperada:**
```
Name                  Status
enviar-notificacao    ACTIVE
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

### 3. Testar a Função

```bash
curl -X POST \
  'https://SEU_PROJECT_ID.supabase.co/functions/v1/enviar-notificacao' \
  -H 'Content-Type: application/json' \
  -d '{
    "tokenFcm": "TOKEN_FCM_AQUI",
    "titulo": "Teste",
    "corpo": "Teste de notificação"
  }'
```

**Resposta esperada:**
```json
{
  "success": true,
  "messageId": "projects/app-iadet/messages/abc123...",
  "message": "Notificação enviada com sucesso"
}
```

---

## 📊 Fluxo Completo: Do Deploy ao Uso

### 1. Deploy (uma vez)
```bash
supabase functions deploy enviar-notificacao
```
**Resultado:** Função ativa e disponível publicamente

### 2. Uso (todas as vezes)
```dart
// Flutter chama a função
await Supabase.instance.client.functions.invoke(
  'enviar-notificacao',
  body: {
    'tokenFcm': token,
    'titulo': 'Teste',
    'corpo': 'Mensagem',
  },
);
```

### 3. Execução (automática)
```
1. Supabase recebe requisição
2. Carrega a função
3. Injeta secrets como variáveis de ambiente
4. Executa o código
5. Retorna resposta
```

---

## 🔐 Segurança Durante o Deploy

### O que é Público
- ✅ Código fonte (index.ts)
- ✅ URL da função
- ✅ Nome da função

### O que é Privado (Secrets)
- 🔒 FIREBASE_CLIENT_EMAIL
- 🔒 FIREBASE_PRIVATE_KEY
- 🔒 Outros secrets

**Os secrets NÃO são enviados no deploy!**
- Eles já estão configurados no Supabase
- São injetados em runtime
- Nunca aparecem em logs

---

## 💰 Custo do Deploy

### Plano Gratuito (Free Tier)
- **500k invocações/mês** GRÁTIS
- **100ms de CPU** por invocação
- Suficiente para ~10k usuários ativos

### Plano Pro ($25/mês)
- **1M invocações/mês**
- **500ms de CPU** por invocação
- Para apps maiores

**Custo por notificação:** ~$0.000001 (muito barato!)

---

## 🔄 Atualizações Futuras

### Se modificar o código:

```bash
# 1. Editar index.ts
# 2. Reimplantar
supabase functions deploy enviar-notificacao

# 3. Verificar logs
supabase functions logs enviar-notificacao
```

**O que muda:**
- ✅ Novo código é implantado
- ✅ Versão anterior é substituída
- ✅ Sem downtime (troca instantânea)

---

## 📝 Checklist de Deploy

- [ ] Código testado localmente
- [ ] Secrets configurados
- [ ] Comando executado: `supabase functions deploy enviar-notificacao`
- [ ] Status: `ACTIVE`
- [ ] Teste com curl funcionando
- [ ] Teste no Flutter funcionando

---

## 🎯 Resumo

**O que o deploy faz:**
1. Envia código para Supabase
2. Compila TypeScript → JavaScript
3. Cria container isolado
4. Replica em múltiplas regiões
5. Configura secrets
6. Ativa a função

**Resultado:**
- ✅ Função disponível publicamente
- ✅ URL: `https://seu-projeto.supabase.co/functions/v1/enviar-notificacao`
- ✅ Segura (usa secrets)
- ✅ Escalável
- ✅ Baixa latência

**Pronto para usar!** 🚀