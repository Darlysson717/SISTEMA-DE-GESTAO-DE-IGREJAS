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
  final double? fixedImageHeight;
  final bool compact;

  const EventFeedCard({
    super.key,
    required this.event,
    this.onCardTap,
    this.onPrimaryAction,
    this.onVolunteerAction,
    this.primaryActionLabel = 'Participar',
    this.volunteerActionLabel = 'Quero ser voluntario',
    this.fixedImageHeight,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;
    final useCompact = compact || isWideScreen;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onCardTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                fixedImageHeight != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: SizedBox(
                          height: fixedImageHeight,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              SizedBox(
                                height: fixedImageHeight,
                                width: double.infinity,
                                child: Image.network(
                                  event.imagemCapaUrlVersionada?.trim() ?? '',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: fixedImageHeight,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFF1F5F9),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Color(0xFF94A3B8),
                                      size: 36,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned.fill(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.25),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(event.categoria),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    event.categoria,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          AdaptiveEventImage(
                            imageUrl: event.imagemCapaUrlVersionada,
                            defaultAspectRatio: useCompact ? 16 / 10 : 16 / 9,
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.25),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(event.categoria),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                event.categoria,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                Padding(
                  padding: EdgeInsets.all(useCompact ? 10 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.nome,
                        style: TextStyle(
                          fontSize: useCompact ? 15 : 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: useCompact ? 5 : 8),
                      Text(
                        event.resumoCurto,
                        style: TextStyle(
                          fontSize: useCompact ? 12 : 13,
                          color: const Color(0xFF64748B),
                          height: 1.4,
                        ),
                        maxLines: useCompact ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: useCompact ? 8 : 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 14,
                              color: Color(0xFF6366F1),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              event.dataTexto,
                              style: TextStyle(
                                fontSize: useCompact ? 11 : 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onPrimaryAction != null) ...[
                        SizedBox(height: useCompact ? 8 : 12),
                        if (!event.permitirVoluntarios)
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: onPrimaryAction,
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: useCompact ? 8 : 10,
                                ),
                              ),
                              icon: Icon(Icons.arrow_forward, size: useCompact ? 14 : 16),
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: useCompact ? 8 : 10,
                                    ),
                                    textStyle: TextStyle(fontSize: useCompact ? 11 : 12),
                                  ),
                                  icon: Icon(
                                    Icons.arrow_forward,
                                    size: useCompact ? 12 : 14,
                                  ),
                                  label: Text(
                                    'Participar',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
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
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: useCompact ? 8 : 10,
                                    ),
                                    textStyle: TextStyle(fontSize: useCompact ? 11 : 12),
                                  ),
                                  icon: Icon(
                                    Icons.volunteer_activism_outlined,
                                    size: useCompact ? 12 : 14,
                                  ),
                                  label: Text(
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