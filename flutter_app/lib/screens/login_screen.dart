import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController(), _email = TextEditingController(), _pw = TextEditingController();
  bool _register = false, _diabetic = false, _busy = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    final auth = context.read<AuthState>();
    try {
      if (_register) {
        await auth.register(_name.text.trim(), _email.text.trim(), _pw.text, _diabetic);
      } else {
        await auth.login(_email.text.trim(), _pw.text);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.qr_code_scanner, size: 72, color: Colors.green),
              const SizedBox(height: 8),
              Text('Grocery Scanner', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              if (_register) TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: _pw, obscureText: true, decoration: const InputDecoration(labelText: 'Password')),
              if (_register)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('I follow a diabetic diet'),
                  value: _diabetic,
                  onChanged: (v) => setState(() => _diabetic = v),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(_register ? 'Create account' : 'Log in'),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _register = !_register),
                child: Text(_register ? 'Have an account? Log in' : 'New here? Sign up'),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
