import 'package:flutter/material.dart';
import 'package:router_os_client/router_os_client.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() {
  runApp(const WiTbryApp());
}

class WiTbryApp extends StatelessWidget {
  const WiTbryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wi-Tbry',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        fontFamily: 'sans',
      ),
      home: const LoginPage(),
    );
  }
}

/* =========================
   LOGIN
========================= */

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final ip = TextEditingController(text: '10.10.10.1');
  final user = TextEditingController(text: 'admin');
  final pass = TextEditingController();

  bool hidePassword = true;
  bool loading = false;

  Future<void> connect() async {
    if (ip.text.trim().isEmpty || user.text.trim().isEmpty) {
      _message('أدخل عنوان الراوتر واسم المستخدم');
      return;
    }

    setState(() => loading = true);

    try {
      /*
       * هنا يتم إنشاء اتصال RouterOS.
       *
       * إذا كان إصدار router_os_client لديك يستخدم
       * API مختلفاً، عدّل دالة الاتصال فقط.
       */
      final client = RouterOSClient(
        address: ip.text.trim(),
        user: user.text.trim(),
        password: pass.text,
      );

      await client.connect();

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            client: client,
            routerIp: ip.text.trim(),
          ),
        ),
      );
    } catch (e) {
      _message('فشل الاتصال بالراوتر:\n$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  void dispose() {
    ip.dispose();
    user.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xff0D47A1),
              Color(0xff1976D2),
              Color(0xff42A5F5),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 45,
                      backgroundColor: Color(0xff1565C0),
                      child: Icon(
                        Icons.wifi,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 15),

                    const Text(
                      'Wi-Tbry',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const Text(
                      'MikroTik Hotspot Manager',
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 25),

                    TextField(
                      controller: ip,
                      decoration: const InputDecoration(
                        labelText: 'IP MikroTik',
                        hintText: '10.10.10.1',
                        prefixIcon: Icon(Icons.router),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: user,
                      decoration: const InputDecoration(
                        labelText: 'اسم المستخدم',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: pass,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        labelText: 'كلمة المرور',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(
                              () => hidePassword = !hidePassword,
                            );
                          },
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: FilledButton(
                        onPressed: loading ? null : connect,
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                'اتصال بالراوتر',
                                style: TextStyle(fontSize: 17),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* =========================
   DASHBOARD
========================= */

class DashboardPage extends StatefulWidget {
  final RouterOSClient client;
  final String routerIp;

  const DashboardPage({
    super.key,
    required this.client,
    required this.routerIp,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int index = 0;

  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      HomePage(client: widget.client),
      UsersPage(client: widget.client),
      OnlinePage(client: widget.client),
      SearchPage(client: widget.client),
      GenerateCardsPage(client: widget.client),
      SettingsPage(routerIp: widget.routerIp),
    ];
  }

  final titles = const [
    'الرئيسية',
    'الكروت',
    'المتصلون',
    'البحث',
    'إنشاء الكروت',
    'الإعدادات',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        centerTitle: true,
      ),

      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff0D47A1),
                      Color(0xff1976D2),
                    ],
                  ),
                ),
                child: const Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.wifi,
                        size: 42,
                        color: Color(0xff1565C0),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Wi-Tbry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              _item(0, Icons.dashboard, 'الرئيسية'),
              _item(1, Icons.confirmation_number, 'الكروت'),
              _item(2, Icons.people, 'المتصلون'),
              _item(3, Icons.search, 'البحث عن كرت'),
              _item(4, Icons.add_card, 'إنشاء الكروت'),
              _item(5, Icons.settings, 'الإعدادات'),

              const Spacer(),

              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('خروج'),
                onTap: () async {
                  await widget.client.disconnect();

                  if (!context.mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginPage(),
                    ),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),

      body: pages[index],
    );
  }

  Widget _item(
    int i,
    IconData icon,
    String title,
  ) {
    return ListTile(
      selected: index == i,
      leading: Icon(icon),
      title: Text(title),
      onTap: () {
        setState(() => index = i);
        Navigator.pop(context);
      },
    );
  }
}

/* =========================
   HOME
========================= */

class HomePage extends StatefulWidget {
  final RouterOSClient client;

  const HomePage({
    super.key,
    required this.client,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int users = 0;
  int online = 0;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final result = await widget.client.talk(
        '/ip/hotspot/user/print',
      );

      users = result.length;

      final active = await widget.client.talk(
        '/ip/hotspot/active/print',
      );

      online = active.length;
    } catch (_) {}

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(
                  icon: Icons.confirmation_number,
                  title: 'كل الكروت',
                  value: '$users',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  icon: Icons.people,
                  title: 'المتصلون',
                  value: '$online',
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 35,
              ),
              title: const Text('حالة MikroTik'),
              subtitle: const Text('الاتصال يعمل'),
              trailing: IconButton(
                onPressed: load,
                icon: const Icon(Icons.refresh),
              ),
            ),
          ),

          const SizedBox(height: 15),

          FilledButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GenerateCardsPage(
                    client: widget.client,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('إنشاء كروت جديدة'),
          ),

          if (loading)
            const Padding(
              padding: EdgeInsets.all(30),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

/* =========================
   STAT CARD
========================= */

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Icon(
              icon,
              size: 38,
              color: const Color(0xff1565C0),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* =========================
   HOTSPOT USERS
========================= */

class UsersPage extends StatefulWidget {
  final RouterOSClient client;

  const UsersPage({
    super.key,
    required this.client,
  });

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  List<Map<String, String>> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final result = await widget.client.talk(
        '/ip/hotspot/user/print',
      );

      users = result.map<Map<String, String>>((e) {
        return {
          'name': '${e['name'] ?? ''}',
          'profile': '${e['profile'] ?? 'default'}',
          'limit': '${e['limit-uptime'] ?? ''}',
          'disabled': '${e['disabled'] ?? 'false'}',
        };
      }).toList();
    } catch (_) {}

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> removeUser(String name) async {
    try {
      final result = await widget.client.talk(
        '/ip/hotspot/user/print',
        {'?name': name},
      );

      if (result.isNotEmpty) {
        await widget.client.talk(
          '/ip/hotspot/user/remove',
          {'.id': '${result.first['.id']}'},
        );
      }

      await load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.confirmation_number_outlined,
              size: 70,
              color: Colors.grey,
            ),
            const SizedBox(height: 15),
            const Text('لا توجد كروت'),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: load,
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: load,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: users.length,
        itemBuilder: (_, i) {
          final u = users[i];

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${i + 1}'),
              ),
              title: Text(u['name'] ?? ''),
              subtitle: Text(
                'Profile: ${u['profile']}\n'
                'المدة: ${u['limit']}',
              ),
              isThreeLine: true,
              trailing: PopupMenuButton(
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('حذف'),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete') {
                    removeUser(u['name'] ?? '');
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

/* =========================
   ONLINE
========================= */

class OnlinePage extends StatefulWidget {
  final RouterOSClient client;

  const OnlinePage({
    super.key,
    required this.client,
  });

  @override
  State<OnlinePage> createState() => _OnlinePageState();
}

class _OnlinePageState extends State<OnlinePage> {
  List<Map<String, String>> online = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);

    try {
      final result = await widget.client.talk(
        '/ip/hotspot/active/print',
      );

      online = result.map<Map<String, String>>((e) {
        return {
          'user': '${e['user'] ?? ''}',
          'address': '${e['address'] ?? ''}',
          'mac': '${e['mac-address'] ?? ''}',
          'uptime': '${e['uptime'] ?? ''}',
        };
      }).toList();
    } catch (_) {}

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (online.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 75,
              color: Colors.grey,
            ),
            const SizedBox(height: 12),
            const Text('لا يوجد متصلون حالياً'),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: load,
              icon: const Icon(Icons.refresh),
              label: const Text('تحديث'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: load,
      child: ListView.builder(
        itemCount: online.length,
        itemBuilder: (_, i) {
          final u = online[i];

          return Card(
            margin: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(
                  Icons.wifi,
                  color: Colors.white,
                ),
              ),
              title: Text(u['user'] ?? ''),
              subtitle: Text(
                '${u['address']}\n'
                '${u['mac']}\n'
                'Uptime: ${u['uptime']}',
              ),
              isThreeLine: true,
            ),
          );
        },
      ),
    );
  }
}

/* =========================
   SEARCH
========================= */

class SearchPage extends StatefulWidget {
  final RouterOSClient client;

  const SearchPage({
    super.key,
    required this.client,
  });

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final search = TextEditingController();

  Map<String, dynamic>? result;
  bool loading = false;

  Future<void> find() async {
    if (search.text.trim().isEmpty) return;

    setState(() => loading = true);

    try {
      final r = await widget.client.talk(
        '/ip/hotspot/user/print',
        {'?name': search.text.trim()},
      );

      if (r.isNotEmpty) {
        result = r.first;
      } else {
        result = null;
      }
    } catch (_) {
      result = null;
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: search,
            decoration: InputDecoration(
              labelText: 'رقم الكرت',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: find,
                icon: const Icon(Icons.search),
              ),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => find(),
          ),

          const SizedBox(height: 20),

          if (loading)
            const CircularProgressIndicator(),

          if (!loading && result != null)
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.confirmation_number,
                  size: 40,
                ),
                title: Text(
                  '${result!['name'] ?? ''}',
                ),
                subtitle: Text(
                  'Profile: ${result!['profile'] ?? ''}\n'
                  'Disabled: ${result!['disabled'] ?? ''}\n'
                  'Uptime: ${result!['limit-uptime'] ?? ''}',
                ),
              ),
            ),

          if (!loading &&
              result == null &&
              search.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('الكرت غير موجود'),
            ),
        ],
      ),
    );
  }
}

/* =========================
   GENERATE CARDS
========================= */

class GenerateCardsPage extends StatefulWidget {
  final RouterOSClient client;

  const GenerateCardsPage({
    super.key,
    required this.client,
  });

  @override
  State<GenerateCardsPage> createState() =>
      _GenerateCardsPageState();
}

class _GenerateCardsPageState
    extends State<GenerateCardsPage> {
  int quantity = 10;

  String profile = 'default';

  String duration = '1d';

  bool loading = false;

  final List<String> created = [];

  Future<void> generate() async {
    if (quantity < 1 || quantity > 5000) {
      _message('العدد يجب أن يكون من 1 إلى 5000');
      return;
    }

    setState(() => loading = true);

    created.clear();

    try {
      for (int i = 0; i < quantity; i++) {
        final now =
            DateTime.now().microsecondsSinceEpoch;

        final username =
            'TB${now.toString().substring(6)}$i';

        await widget.client.talk(
          '/ip/hotspot/user/add',
          {
            'name': username,
            'password': username,
            'profile': profile,
            'limit-uptime': duration,
          },
        );

        created.add(username);
      }

      _message(
        'تم إنشاء ${created.length} كرت',
      );
    } catch (e) {
      _message('حدث خطأ:\n$e');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  Future<void> exportPdf() async {
    if (created.isEmpty) {
      _message('أنشئ الكروت أولاً');
      return;
    }

    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        build: (context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('Wi-Tbry'),
            ),

            pw.Text('Hotspot Cards'),

            pw.SizedBox(height: 15),

            pw.Table.fromTextArray(
              headers: [
                'No',
                'Username',
                'Password',
              ],
              data: List.generate(
                created.length,
                (i) => [
                  '${i + 1}',
                  created[i],
                  created[i],
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => document.save(),
    );
  }

  void _message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء الكروت'),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              initialValue: profile,
              decoration: const InputDecoration(
                labelText: 'Profile',
                border: OutlineInputBorder(),
              ),
              items: const [
                'default',
                '1M',
                '2M',
                '5M',
                '10M',
                '20M',
              ]
                  .map(
                    (x) => DropdownMenuItem(
                      value: x,
                      child: Text(x),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => profile = v);
                }
              },
            ),

            const SizedBox(height: 15),

            DropdownButtonFormField<String>(
              initialValue: duration,
              decoration: const InputDecoration(
                labelText: 'مدة الكرت',
                border: OutlineInputBorder(),
              ),
              items: const [
                '1h',
                '6h',
                '12h',
                '1d',
                '3d',
                '7d',
                '30d',
              ]
                  .map(
                    (x) => DropdownMenuItem(
                      value: x,
                      child: Text(x),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => duration = v);
                }
              },
            ),

            const SizedBox(height: 15),

            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الكروت',
                hintText: '1 - 5000',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                quantity =
                    int.tryParse(v) ?? 10;
              },
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: FilledButton.icon(
                onPressed: loading ? null : generate,
                icon: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_card),
                label: const Text(
                  'إنشاء الكروت في MikroTik',
                ),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: OutlinedButton.icon(
                onPressed: exportPdf,
                icon: const Icon(
                  Icons.picture_as_pdf,
                ),
                label: const Text(
                  'تصدير PDF والطباعة',
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (created.isNotEmpty)
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text(
                        'تم إنشاء ${created.length} كرت',
                      ),
                    ),

                    ...created.take(30).map(
                      (e) => ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.confirmation_number,
                        ),
                        title: Text(e),
                        subtitle:
                            const Text('Password: نفس اسم المستخدم'),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/* =========================
   SETTINGS
========================= */

class SettingsPage extends StatelessWidget {
  final String routerIp;

  const SettingsPage({
    super.key,
    required this.routerIp,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.router),
            title: const Text('MikroTik'),
            subtitle: Text(routerIp),
          ),
        ),

        Card(
          child: ListTile(
            leading: const Icon(Icons.print),
            title: const Text('الطباعة'),
            subtitle: const Text(
              'إعدادات الطباعة وقوالب الكروت',
            ),
            onTap: () {},
          ),
        ),

        Card(
          child: ListTile(
            leading: const Icon(Icons.style),
            title: const Text('قالب الكرت'),
            subtitle: const Text(
              'اختيار شكل الكرت',
            ),
            onTap: () {},
          ),
        ),

        Card(
          child: ListTile(
            leading: const Icon(Icons.info),
            title: const Text('حول التطبيق'),
            subtitle: const Text(
              'Wi-Tbry - MikroTik Manager',
            ),
          ),
        ),
      ],
    );
  }
}<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET"/>

    <application
        android:label="Wi-Tbry"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">

            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"/>

            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>

        </activity>

        <meta-data
            android:name="flutterEmbedding"
            android:value="2"/>

    </application>
</manifest>name: wi_tbry

description: Wi-Tbry MikroTik Hotspot Manager

publish_to: "none"

version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  router_os_client: ^2.0.1
  pdf: ^3.11.3
  printing: ^5.13.4

  cupertino_icons: ^1.0.8

flutter:
  uses-material-design: true