import 'package:centro_social_app/src/funcionalidades/eventos/dominio/entidades/evento_app.dart';
import 'package:centro_social_app/src/funcionalidades/eventos/apresentacao/componentes/imagem_evento_adaptativa.dart';
import 'package:flutter/material.dart';

class EventFeedCard extends StatelessWidget {
  final AppEvent event;
  final VoidCallback? onCardTap;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onVolunteerAction;
  final String primaryActionLabel;
  final String volunteerActionLabel;

  const EventFeedCard({
    super.key,
    required this.event,
    this.onCardTap,
    this.onPrimaryAction,
    this.onVolunteerAction,
    this.primaryActionLabel = 'Participar',
    this.volunteerActionLabel = 'Quero ser voluntario',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onCardTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    AdaptiveEventImage(
                      imageUrl: event.imagemCapaUrlVersionada,
                      defaultAspectRatio: 16 / 9,
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.28),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(event.categoria),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          event.categoria,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.nome,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event.resumoCurto,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.45,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  event.dataTexto,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (onPrimaryAction != null) ...[
                        const SizedBox(height: 12),
                        if (!event.permitirVoluntarios)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: onPrimaryAction,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: Text(primaryActionLabel),
                            ),
                          )
                        else
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: onPrimaryAction,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF6366F1),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  icon: const Icon(
                                    Icons.arrow_forward,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Participar',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed:
                                      onVolunteerAction ??
                                      () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Interesse em voluntariado registrado em "${event.nome}"',
                                            ),
                                            backgroundColor: const Color(
                                              0xFF059669,
                                            ),
                                          ),
                                        );
                                      },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    textStyle: const TextStyle(fontSize: 12),
                                  ),
                                  icon: const Icon(
                                    Icons.volunteer_activism_outlined,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Ser voluntario',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'juridico':
      case 'jurídico':
        return const Color(0xFF059669);
      case 'psicologia':
        return const Color(0xFFDC2626);
      case 'saude':
      case 'saúde':
        return const Color(0xFF7C3AED);
      case 'emprego':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF6366F1);
    }
  }
}
