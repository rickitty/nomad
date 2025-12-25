import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:price_book/keys.dart';
import 'package:price_book/pages/admin/goods_page.dart';
import 'package:price_book/pages/admin/markets_page.dart';
import 'package:price_book/pages/admin/task_create_page.dart';
// import 'package:price_book/pages/admin/task_list_page.dart';
import 'package:price_book/pages/login_screen.dart';
import 'package:price_book/pages/worker/worker_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color kPrimaryColor = Color.fromRGBO(144, 202, 249, 1);

enum DrawerRoute { worker, markets, taskList, taskCreate, goods }

class AppDrawer extends StatelessWidget {
  final DrawerRoute current;

  const AppDrawer({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Drawer(
            child: Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
          );
        }

        return Drawer(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, const Color(0xFFF5F9FF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimaryColor, kPrimaryColor.withOpacity(0.9)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              'N',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'NOMAD',
                          style: textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          menu.tr(),
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),

                  _DrawerItem(
                    icon: Icons.task,
                    title: myTasks.tr(),
                    onTap: () {
                      Navigator.pop(context);
                      if (current == DrawerRoute.worker) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const WorkerPage()),
                      );
                    },
                  ),

                  _DrawerItem(
                    icon: Icons.add_box,
                    title: createATask.tr(),
                    onTap: () {
                      Navigator.pop(context);
                      if (current == DrawerRoute.taskCreate) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateTaskPage(),
                        ),
                      );
                    },
                  ),

                  _DrawerItem(
                    icon: Icons.store,
                    title: Markets.tr(),
                    onTap: () {
                      Navigator.pop(context);
                      if (current == DrawerRoute.markets) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MarketsPage()),
                      );
                    },
                  ),

                  // _DrawerItem(
                  //   icon: Icons.local_grocery_store_rounded,
                  //   title: goodsK.tr(),
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     if (current == DrawerRoute.goods) return;
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (_) => const GoodsPage()),
                  //     );
                  //   },
                  // ),

                  // _DrawerItem(
                  //   icon: Icons.edit,
                  //   title: statusSidebar.tr(),
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     if (current == DrawerRoute.taskList) return;
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (_) => const TaskListPage()),
                  //     );
                  //   },
                  // ),

                  // const Divider(height: 24, indent: 16, endIndent: 16),

                  // _DrawerItem(
                  //   icon: Icons.person,
                  //   title: myProfile.tr(),
                  //   onTap: () {
                  //     Navigator.pop(context);
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(
                  //         builder: (_) => const MyProfilePage(),
                  //       ),
                  //     );
                  //   },
                  // ),
                  _DrawerItem(
                    icon: Icons.language,
                    title: changeLanguage.tr(),
                    onTap: () {
                      Navigator.pop(context);
                      _showLanguageDialog(context);
                    },
                  ),

                  const SizedBox(height: 8),

                  _DrawerItem(
                    icon: Icons.logout,
                    title: logout.tr(),
                    isDestructive: true,
                    onTap: () => _logout(context),
                  ),

                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          selectLanguage.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("English"),
              onTap: () {
                context.setLocale(const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Русский"),
              onTap: () {
                context.setLocale(const Locale('ru'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text("Қазақша"),
              onTap: () {
                context.setLocale(const Locale('kz'));
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
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.white,
        elevation: 0.5,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.08)
                        : kPrimaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: isDestructive ? Colors.red : kPrimaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDestructive
                          ? Colors.red
                          : const Color(0xFF1F2933),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
