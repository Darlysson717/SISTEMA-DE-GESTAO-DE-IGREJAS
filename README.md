# Centro Social da Igreja - Flutter + Supabase

Sistema base escalável para Centro Social da Igreja com serviços gratuitos comunitários (psicologia, médico, jurídico etc.), construído em arquitetura modular limpa e preparado para evolução SaaS.

## ✅ Sistema Simplificado

**Todos os usuários são tratados como membros da comunidade.** Não há mais distinção entre administradores, voluntários e usuários comuns. A identificação de "profissionais" é feita automaticamente quando um usuário publica serviços.

### Funcionalidades Automáticas
- **Criação automática de disponibilidade**: Quando um serviço é aprovado, as `professional_availabilities` são criadas automaticamente baseadas nos horários do serviço
- **Políticas RLS simplificadas**: Todos os usuários gerenciam seus próprios dados
- **Interface unificada**: Mesma experiência para todos os usuários

## Módulos implementados

- Autenticação com Supabase Auth
- Login com conta Google (OAuth)
- Sistema de serviços comunitários
- Agendamento automático com validação
- Perfil de usuário simplificado

## Estrutura de arquitetura

```
lib/src/
	core/
		config/
	features/
		auth/
			data/
			domain/
			presentation/
		home/
			presentation/
		scheduling/
			data/
			domain/
			presentation/
		services/
			presentation/
```

## Scripts de Banco de Dados

### Migração e Simplificação
- `SIMPLIFY_USERS_SYSTEM.sql` - Simplificação completa do sistema de usuários
- `AUTO_CREATE_AVAILABILITIES.sql` - Criação automática de disponibilidade
- `CREATE_MISSING_AVAILABILITIES.sql` - Criar availabilities para serviços já aprovados

### Verificação e Testes
- `VERIFY_SIMPLIFICATION.sql` - Verificação da simplificação
- `TEST_POST_SIMPLIFICATION.sql` - Testes pós-simplificação
- `TEST_SCHEDULING_AFTER_FIX.sql` - Teste de agendamento após correções
- `FINAL_SYSTEM_CHECK.sql` - Verificação final completa

## Como Usar o Sistema Simplificado

1. **Execute a migração**: `SIMPLIFY_USERS_SYSTEM.sql`
2. **Verifique a simplificação**: `VERIFY_SIMPLIFICATION.sql`
3. **Crie availabilities para serviços existentes**: `CREATE_MISSING_AVAILABILITIES.sql`
4. **Teste final**: `FINAL_SYSTEM_CHECK.sql`

### Funcionamento Automático

- **Aprovação de serviço** → `professional_availabilities` criadas automaticamente
- **Agendamento** → Validação baseada nas availabilities criadas
- **Todos os usuários** têm as mesmas permissões sobre seus dados

## Configuração Supabase

1. Crie um projeto no Supabase.
2. Execute o script SQL em `supabase/schema.sql`.
3. Execute a **simplificação**: `supabase/SIMPLIFY_USERS_SYSTEM.sql`.
4. Ative Google Provider em `Authentication > Providers > Google` no painel Supabase.
5. Em `Authentication > URL Configuration`, adicione Redirect URL:

	 - `com.igreja.centro_social_app://login-callback/`

## Executar o app

```bash
flutter pub get
flutter run \
	--dart-define=SUPABASE_URL=https://gtxamoukdklnudhxgjhc.supabase.co \
	--dart-define=SUPABASE_ANON_KEY=sb_publishable_9QiR4QbOFYojwurQ_RSi5w_dhLBsQyW \
	--dart-define=SUPABASE_REDIRECT_URL=com.igreja.centro_social_app://login-callback/
```
- O app Flutter deve usar apenas URL + chave publicável via Supabase client.
- Nunca exponha senha do banco em app mobile.

## Evolução recomendada (próximos módulos)

- Catálogo de serviços voluntários
- Agenda e solicitação de atendimento
- Aprovação/triagem por voluntários
- Painel administrativo com métricas
- Multi-tenant para SaaS (por organização/igreja)
