import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';

class SuperAdminHomePage extends ConsumerWidget {
  const SuperAdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Workspace'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('SuperAdmin login success. Main features will be added here.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
