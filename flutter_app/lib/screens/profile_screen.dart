import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api.dart';
import '../services/auth_state.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final u = auth.user!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(children: [
        ListTile(leading: const CircleAvatar(child: Icon(Icons.person)), title: Text(u.name), subtitle: Text(u.email)),
        SwitchListTile(
          title: const Text('Diabetic diet mode'),
          subtitle: const Text('Rate products for diabetic needs'),
          value: u.isDiabetic,
          onChanged: (v) async => auth.setUser(await Api.updateMe(diabetic: v)),
        ),
        ListTile(
          leading: Icon(u.isPremium ? Icons.workspace_premium : Icons.lock_open, color: u.isPremium ? Colors.amber : null),
          title: Text(u.isPremium ? 'Premium active' : 'Free plan'),
          trailing: u.isPremium ? null : const Icon(Icons.chevron_right),
          onTap: u.isPremium ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
        ),
        const Divider(),
        ListTile(leading: const Icon(Icons.logout), title: const Text('Log out'), onTap: auth.logout),
      ]),
    );
  }
}
