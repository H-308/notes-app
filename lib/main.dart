import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:notes_app/config/theme/app_theme.dart';
import 'package:notes_app/features/auth/auth_screen.dart';
import 'package:notes_app/features/auth/auth_provider.dart';
import 'package:notes_app/features/auth/auth_remote_datasource.dart';
import 'package:notes_app/features/auth/auth_repository_impl.dart';
import 'package:notes_app/core/services/firebase_auth_service.dart';
import 'package:notes_app/features/notes_list/notes_list_page.dart';
import 'package:notes_app/features/notes_map/notes_map_page.dart';
import 'package:notes_app/features/note_editor/note_editor_page.dart';
import 'package:notes_app/features/notes_list/notes_list_provider.dart';
import 'package:notes_app/features/notes_list/notes_list_repository_impl.dart';
import 'package:notes_app/core/services/firestore_service.dart';
import 'package:notes_app/features/note_editor/note_editor_provider.dart';
import 'package:notes_app/features/note_editor/note_editor_repository_impl.dart';
import 'package:notes_app/core/services/location_service.dart';
import 'package:notes_app/features/notes_map/notes_map_provider.dart';
import 'package:notes_app/features/notes_map/notes_map_repository_impl.dart';

/// Main screen with bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String? _selectedNoteId;

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      NotesListPage(
        onCreateNote: _handleCreateNote,
        onNoteSelected: _handleNoteSelected,
      ),
      NotesMapPage(onMarkerTapped: _handleMarkerTapped),
    ];
  }

  void _handleCreateNote() {
    context.read<NoteEditorNotifier>().reset();
    setState(() => _selectedNoteId = null);
    _navigateToEditor();
  }

  void _handleNoteSelected(String noteId) {
    setState(() => _selectedNoteId = noteId);
    _navigateToEditor();
  }

  void _handleMarkerTapped(String noteId) {
    setState(() => _selectedNoteId = noteId);
    _navigateToEditor();
  }

  void _navigateToEditor() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NoteEditorPage(
          noteId: _selectedNoteId,
          onSave: () {
            setState(() => _selectedNoteId = null);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthStateNotifier>().signOut(),
          ),
        ],
      ),
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Notes'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreateNote,
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// Root widget that manages auth state and syncs providers
class RootApp extends StatelessWidget {
  const RootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthStateNotifier>(
      builder: (context, authProvider, _) {
        return StreamBuilder<dynamic>(
          stream: authProvider.authStateStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasData && snapshot.data != null) {
              return const MainScreen();
            }

            return const AuthScreen();
          },
        );
      },
    );
  }
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Location-Based Notes',
      theme: AppTheme.getLightTheme(),
      debugShowCheckedModeBanner: false,
      home: const RootApp(),
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase Error: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthStateNotifier(
            AuthRepositoryImpl(AuthRemoteDataSource(FirebaseAuthService())),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              NotesListNotifier(NotesListRepositoryImpl(FirestoreService())),
        ),
        ChangeNotifierProvider(
          create: (_) => NoteEditorNotifier(
            NoteEditorRepositoryImpl(FirestoreService()),
            LocationService(),
          ),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              NotesMapNotifier(NotesMapRepositoryImpl(FirestoreService())),
        ),
      ],
      child: const NotesApp(),
    ),
  );
}
