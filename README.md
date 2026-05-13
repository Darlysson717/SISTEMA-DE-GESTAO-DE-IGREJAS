# Centro Social da Igreja - Flutter + Supabase

Sistema base escalável para Centro Social da Igreja com serviços gratuitos comunitários (psicologia, médico, jurídico etc.), construído em arquitetura modular limpa e preparado para evolução SaaS.

## ✅ Sistema Simplificado

**Todos os usuários são tratados como membros da comunidade.** Há distinção entre administradores, voluntários e usuários comuns. A identificação de "profissionais" é feita automaticamente quando um usuário publica serviços.

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

### Funcionamento Automático

- **Aprovação de serviço** → `professional_availabilities` criadas automaticamente
- **Agendamento** → Validação baseada nas availabilities criadas
- **Todos os usuários** têm as mesmas permissões sobre seus dados






