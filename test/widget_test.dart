import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const title = 'Sign up';

    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(title),
        ),
        body: ListView(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Inicio de sesión'),
            ),
            Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyHomePage(),
                    ),
                  );
                },
                child: Text('Iniciar Sesión'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _newUsernameController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  late Database _db;
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    initDB();
  }

  void initDB() async {
    _db = await openDatabase(
      join(await getDatabasesPath(), 'login_database.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT, password TEXT, photo TEXT)",
        );
      },
      version: 1,
    );
    checkAndInsertData();
    getUsers();
  }

  Future<void> checkAndInsertData() async {
    final count = Sqflite.firstIntValue(await _db.rawQuery('SELECT COUNT(*) FROM users'));
    if (count == 0) {
      await _db.transaction((txn) async {
        await txn.rawInsert(
          'INSERT INTO users(username, password, photo) VALUES(?,?,?)',
          ['John', '12345', 'default_photo.png'],
        );
        await txn.rawInsert(
          'INSERT INTO users(username, password, photo) VALUES(?,?,?)',
          ['Alice', '12345', 'default_photo.png'],
        );
      });
    }
  }

  Future<void> getUsers() async {
    final List<Map<String, dynamic>> userList = await _db.query('users');
    setState(() {
      users = userList;
    });
  }

  Future<void> _login(BuildContext context) async {
    final List<Map<String, dynamic>> usersResult = await _db.query(
      'users',
      where: 'username = ? AND password = ?',
      whereArgs: [_usernameController.text, _passwordController.text],
    );

    if (usersResult.isNotEmpty) {
      final String userPhotoPath = usersResult[0]['photo'] ?? 'default_photo.png';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => _UserListScreen(users: users, userPhotoPath: userPhotoPath)),
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Invalid username or password.'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Agregar Usuario'),
          content: Column(
            children: <Widget>[
              TextField(
                controller: _newUsernameController,
                decoration: InputDecoration(labelText: 'Nuevo Usuario'),
              ),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Contraseña'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text('Agregar'),
              onPressed: () {
                _addUser(context);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _addUser(BuildContext context) async {
    await _db.transaction((txn) async {
      await txn.rawInsert(
        'INSERT INTO users(username, password) VALUES(?,?)',
        [_newUsernameController.text, _newPasswordController.text],
      );
    });

    // Actualizar la lista de usuarios después de agregar uno nuevo
    getUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login users'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _login(context);
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddUserDialog(context);
        },
        tooltip: 'Agregar Usuario',
        child: Icon(Icons.add),
      ),
    );
  }
}

class _UserListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final String userPhotoPath;

  _UserListScreen({required this.users, required this.userPhotoPath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User List'),
      ),
      body: Column(
        children: [
          // Mostrar la imagen del usuario
          Image.file(
            File(userPhotoPath),
            height: 100,
            width: 100,
            fit: BoxFit.cover,
          ),
          // Mostrar la lista de usuarios
          Expanded(
            child: ListView.builder(
              itemCount: users.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text('Usuario'),
                  subtitle: Text(users[index]['username']),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Puedes agregar aquí la lógica que desees al presionar el botón flotante
        },
        tooltip: 'Agregar Usuario',
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              onPressed: () {
                Navigator.popUntil(context, ModalRoute.withName('/'));
              },
              icon: Icon(Icons.logout),
            ),
          ],
        ),
      ),
    );
  }
}
