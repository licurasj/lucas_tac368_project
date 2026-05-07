import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_cubit.dart';
import 'app_state.dart';
import 'app_storage.dart';
import 'drive_sync_service.dart';
import 'home_screen.dart';
import 'journal_screen.dart';
import 'todo_screen.dart';
import 'watchlist_screen.dart';
import 'grocery_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final AppStorage storage = AppStorage();
  final String deviceId = await storage.getOrCreateDeviceId();

  runApp(
    BlocProvider(
      create: (_) => AppCubit(
        storage: storage,
        driveSyncService: DriveSyncService(),
        deviceId: deviceId,
      )..loadData(),
      child: const HybridNoteApp(),
    ),
  );
}

class HybridNoteApp extends StatelessWidget {
  const HybridNoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hybrid Note App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Segoe UI',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A66D8),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF4F8FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF0A3D91),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF0A3D91),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            fontFamily: 'Segoe UI',
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0A66D8),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0A66D8),
            side: const BorderSide(
              color: Color(0xFF0A66D8),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
              color: Color(0xFF0A66D8),
              width: 2,
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFD8E9FF),
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              color: Color(0xFF0A3D91),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() {
    return _MainShellState();
  }
}

class _MainShellState extends State<MainShell> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    HomeScreen(),
    TodoScreen(),
    GroceryScreen(),
    JournalScreen(),
    WatchlistScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppCubit, AppState>(
      listenWhen: (oldState, newState) {
        return oldState.errorMessage != newState.errorMessage ||
            oldState.syncMessage != newState.syncMessage;
      },
      listener: (context, state) {
        final String? message = state.errorMessage ?? state.syncMessage;

        if (message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
      child: Scaffold(
        body: screens[selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.check_box_outlined),
              selectedIcon: Icon(Icons.check_box),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined),
              selectedIcon: Icon(Icons.shopping_cart),
              label: 'Grocery',
            ),
            NavigationDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book),
              label: 'Journal',
            ),
            NavigationDestination(
              icon: Icon(Icons.movie_outlined),
              selectedIcon: Icon(Icons.movie),
              label: 'Watch/Read',
            ),
          ],
        ),
      ),
    );
  }
}
