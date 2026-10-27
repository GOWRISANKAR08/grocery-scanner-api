import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_state.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(create: (_) => AuthState()..load(), child: const App()),
  );
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return MaterialApp(
      title: 'Grocery Scanner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: auth.loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : (auth.loggedIn ? const HomeScreen() : const LoginScreen()),
    );
  }
}
