import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CW06',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snapshot.hasData)
          return HomePage();
        return AuthPage();
      },
    );
  }
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  Future<void> _register() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login/Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text('Login')),
            ElevatedButton(onPressed: _register, child: const Text('Register')),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final taskController = TextEditingController();
  final timeController = TextEditingController();

  void _signOut() async {
    await auth.signOut();
  }

  Future<void> _addTask() async {
    if (taskController.text.trim().isEmpty) return;
    await FirebaseFirestore.instance.collection('tasks').add({
      'name': taskController.text.trim(),
      'completed': false,
      'time': timeController.text.trim(),
      'userId': auth.currentUser?.uid,
    });
    taskController.clear();
    timeController.clear();
  }

  Future<void> _updateTask(String taskId, bool completed) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'completed': completed,
    });
  }

  Future<void> _deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
  }

  Stream<List<Task>> getTasks() {
    return FirebaseFirestore.instance
        .collection('tasks')
        .where('userId', isEqualTo: auth.currentUser?.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Task.fromFirestore(doc.id, doc.data()))
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = auth.currentUser?.email ?? "No Email";

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task List'),
        actions: [
          IconButton(onPressed: _signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Welcome, $userEmail', style: const TextStyle(fontSize: 18)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: taskController,
              decoration: const InputDecoration(labelText: 'Enter Task'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: timeController,
              decoration: const InputDecoration(labelText: 'Time (optional)'),
            ),
          ),
          ElevatedButton(
            onPressed: _addTask,
            child: const Text('Add Task'),
          ),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: getTasks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));

                final tasks = snapshot.data ?? [];

                if (tasks.isEmpty)
                  return const Center(child: Text('No tasks found.'));

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (_, index) {
                    final task = tasks[index];
                    return ListTile(
                      title: Text(task.name),
                      subtitle: task.time.isNotEmpty
                          ? Text('Time: ${task.time}')
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: task.completed,
                            onChanged: (value) {
                              _updateTask(task.id, value ?? false);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteTask(task.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Task {
  final String id;
  final String name;
  final bool completed;
  final String time;

  Task({required this.id, required this.name, required this.completed, required this.time});

  factory Task.fromFirestore(String id, Map<String, dynamic> data) {
    return Task(
      id: id,
      name: data['name'],
      completed: data['completed'],
      time: data['time'] ?? '',
    );
  }
}
