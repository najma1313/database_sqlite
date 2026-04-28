import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ListUserDataPage(),
    );
  }
}

class UserModel {
  int? id;
  String nama;
  int umur;

  UserModel({
    this.id,
    required this.nama,
    required this.umur,
  });

  Map<String, dynamic> toJson() => {
        "id": id,
        "nama": nama,
        "umur": umur,
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["id"],
      nama: json["nama"],
      umur: json["umur"],
    );
  }
}

class ListUserDataPage extends StatefulWidget {
  const ListUserDataPage({super.key});

  @override
  State<ListUserDataPage> createState() => _ListUserDataPageState();
}

class _ListUserDataPageState extends State<ListUserDataPage> {
  List<UserModel> userList = [];
  bool isLoading = true;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController umurController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    List data = userList.map((e) => e.toJson()).toList();
    await prefs.setString("users", jsonEncode(data));
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataString = prefs.getString("users");

    if (dataString != null) {
      List data = jsonDecode(dataString);
      userList = data.map((e) => UserModel.fromJson(e)).toList();
    }

    setState(() {
      isLoading = false;
    });
  }

  void form({int? id}) {
    if (id != null) {
      final user = userList.firstWhere((element) => element.id == id);
      nameController.text = user.nama;
      umurController.text = user.umur.toString();
    } else {
      nameController.clear();
      umurController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Nama"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: umurController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Umur"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final nama = nameController.text.trim();
                  final umur = int.tryParse(umurController.text) ?? 0;

                  if (nama.isEmpty || umur <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Nama dan umur harus valid"),
                      ),
                    );
                    return;
                  }

                  handleSave(id: id, nama: nama, umur: umur);
                },
                child: Text(id == null ? "Tambahkan" : "Perbaiki"),
              )
            ],
          ),
        );
      },
    );
  }

  void handleSave({
    int? id,
    required String nama,
    required int umur,
  }) {
    if (id != null) {
      final user = userList.firstWhere((element) => element.id == id);

      setState(() {
        user.nama = nama;
        user.umur = umur;
      });
    } else {
      final nextId = userList.isEmpty
          ? 1
          : userList
                  .map((e) => e.id ?? 0)
                  .reduce((a, b) => a > b ? a : b) +
              1;

      final newUser = UserModel(
        id: nextId,
        nama: nama,
        umur: umur,
      );

      setState(() {
        userList.add(newUser);
      });
    }

    saveData();
    Navigator.pop(context);
  }

  void delete(int id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Konfirmasi Hapus"),
          content:
              const Text("Apakah kamu yakin ingin menghapus user ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  userList.removeWhere((element) => element.id == id);
                });

                saveData();
                Navigator.pop(context);
              },
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    umurController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("List User"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: userList.length,
              itemBuilder: (context, index) {
                final user = userList[index];

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(user.nama),
                    subtitle: Text("Umur: ${user.umur}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () => form(id: user.id),
                          icon: const Icon(Icons.edit),
                        ),
                        IconButton(
                          onPressed: () {
                            if (user.id != null) {
                              delete(user.id!);
                            }
                          },
                          icon: const Icon(Icons.delete),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => form(),
        child: const Icon(Icons.add),
      ),
    );
  }
}