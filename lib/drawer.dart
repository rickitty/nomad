import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:price_book/config.dart';
import 'package:price_book/keys.dart';
import 'package:price_book/pages/admin/markets_page.dart';
import 'package:price_book/pages/admin/task_create_page.dart';
import 'package:price_book/pages/admin/task_list_page.dart';
import 'package:price_book/pages/login_screen.dart';
import 'package:price_book/pages/my_profile_page.dart';
import 'package:price_book/pages/worker/worker_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Drawer(child: Center(child: CircularProgressIndicator()));
        }

        return Drawer(
          child: ListView(
            children: [
              DrawerHeader(
                child: Text(menu.tr(), style: TextStyle(fontSize: 22)),
              ),
              // if (role == 'admin')
              //   ListTile(
              //     leading: const Icon(Icons.assignment_add),
              //     title: Text(assigningObjects.tr()),
              //     onTap: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(builder: (_) => AdminAssignPage()),
              //       );
              //     },
              //   ),
              // if (role == 'admin')
              ListTile(
                leading: const Icon(Icons.task),
                title: Text("Мои задачи"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => WorkerPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_box),
                title: Text("Create task"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CreateTaskPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.store),
                title: Text("Markets"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => MarketsPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text("Смена статуса задач"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TaskListPage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.vpn_key),
                title: Text("Update Token"),
                onTap: () async {
                  final TextEditingController tokenController =
                      TextEditingController();

                  final newToken = await showDialog<String>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Enter new token"),
                      content: TextField(
                        controller: tokenController,
                        decoration: const InputDecoration(
                          hintText: "Bearer token",
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(
                            context,
                            tokenController.text.trim(),
                          ),
                          child: const Text("Save"),
                        ),
                      ],
                    ),
                  );

                  if (newToken != null && newToken.isNotEmpty) {
                    await Config.updateToken(newToken);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Token updated!")),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(Icons.person),
                title: Text(myProfile.tr()),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyProfilePage()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(changeLanguage.tr()),
                onTap: () => _showLanguageDialog(context),
              ),
              // if (role == 'worker')
              //   ListTile(
              //     leading: const Icon(Icons.admin_panel_settings),
              //     title: Text(becomeAnAdmin.tr()),
              //     onTap: () => _becomeAdmin(context),
              //   ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(logout.tr()),
                onTap: () => _logout(context),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(selectLanguage.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ListTile(
            //   title: Text("Қазақша"),
            //   onTap: () {
            //     context.setLocale(Locale('kz'));
            //     Navigator.pop(context);
            //   },
            // ),
            ListTile(
              title: Text("English"),
              onTap: () {
                context.setLocale(Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text("Русский"),
              onTap: () {
                context.setLocale(Locale('ru'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // Future<void> _becomeAdmin(BuildContext context) async {
  //   final TextEditingController passwordController = TextEditingController();

  //   final enteredPassword = await showDialog<String>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text(enterAdminPassword.tr()),
  //       content: TextField(
  //         controller: passwordController,
  //         obscureText: true,
  //         decoration: InputDecoration(hintText: password.tr()),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context),
  //           child: Text(cancel.tr()),
  //         ),
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(context, passwordController.text);
  //           },
  //           child: Text(confirm.tr()),
  //         ),
  //       ],
  //     ),
  //   );

  //   if (enteredPassword == null) return;

  //   final adminDoc = await FirebaseFirestore.instance
  //       .collection("system")
  //       .doc("admin")
  //       .get();

  //   if (!adminDoc.exists) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(const SnackBar(content: Text("Admin password not found")));
  //     return;
  //   }

  //   final firestorePassword = adminDoc.data()?["password"];

  //   if (enteredPassword != firestorePassword) {
  //     ScaffoldMessenger.of(
  //       context,
  //     ).showSnackBar(SnackBar(content: Text(incorrectPassword.tr())));
  //     return;
  //   }

  //   final uid = FirebaseAuth.instance.currentUser!.uid;

  //   await FirebaseFirestore.instance.collection("users").doc(uid).update({
  //     "role": "admin",
  //   });

  //   final token = await FirebaseAuth.instance.currentUser!.getIdToken();

  //   final response = await http.post(
  //     Uri.parse("http://localhost:3000/api/user/makeAdmin"),
  //     headers: {
  //       "Authorization": "Bearer $token",
  //       "Content-Type": "application/json",
  //     },
  //   );

  //   if (response.statusCode != 200) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text("MongoDB error: ${response.body}")),
  //     );
  //     return;
  //   }

  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString("role", "admin");

  //   Navigator.pushReplacement(
  //     context,
  //     MaterialPageRoute(builder: (_) => const AdminPage()),
  //   );
  // }
}
