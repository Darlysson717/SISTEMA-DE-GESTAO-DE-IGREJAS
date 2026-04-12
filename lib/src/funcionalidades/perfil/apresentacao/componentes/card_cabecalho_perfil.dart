import 'package:flutter/material.dart';

class ProfileHeaderCard extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final VoidCallback? onEditProfile;

  const ProfileHeaderCard({
    super.key,
    required this.name,
    required this.email,
    this.photoUrl,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 44,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
              child: photoUrl == null
                  ? Icon(
                      Icons.person,
                      size: 44,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              email,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onEditProfile != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onEditProfile,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar perfil'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
