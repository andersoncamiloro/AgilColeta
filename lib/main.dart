import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'services/storage_service.dart';
import 'services/seed_service.dart';
import 'utils/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/cadastros_screen.dart';
import 'screens/coleta_screen.dart';
import 'screens/controle_rota_screen.dart';
import 'screens/exportar_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.instance.init();
  await SeedService.runIfNeeded();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider()..loadAll(),
      child: const AgilColetaApp(),
    ),
  );
}

class AgilColetaApp extends StatelessWidget {
  const AgilColetaApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agil Coleta',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      DashboardScreen(onNavigate: (index) => setState(() => _currentIndex = index)),
      const ControleRotaScreen(),
      const ColetaScreen(),
      const CadastrosScreen(),
      const ExportarScreen(),
    ];
  }

  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(
      icon: Icon(Icons.dashboard_rounded),
      label: 'Início',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.play_circle_fill),
      label: 'Rotas',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.water_drop),
      label: 'Coleta',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.list_alt_rounded),
      label: 'Cadastros',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.upload_file),
      label: 'Exportar',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: _navItems,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textLight,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
        ),
      ),
    );
  }
}
