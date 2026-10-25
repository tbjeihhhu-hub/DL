import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DeliveryIraqApp());
}

const Color gold = Color(0xFFFFC928);
const Color dark = Color(0xFF101010);
const Color panel = Color(0xFF1D1D1D);

class DeliveryIraqApp extends StatelessWidget {
  const DeliveryIraqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'دلفري العراق',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: gold,
          brightness: Brightness.dark,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white12),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPage();
        }

        if (snapshot.data == null) {
          return const LoginPage();
        }

        return ProfilePage(user: snapshot.data!);
      },
    );
  }
}

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: gold),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formKey = GlobalKey<FormState>();

  final name = TextEditingController();
  final phone = TextEditingController();
  final governorate = TextEditingController();
  final area = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  String role = 'customer';
  bool isRegister = false;
  bool loading = false;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    governorate.dispose();
    area.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      if (isRegister) {
        final result = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text.trim(),
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(result.user!.uid)
            .set({
          'name': name.text.trim(),
          'phone': phone.text.trim(),
          'governorate': governorate.text.trim(),
          'area': area.text.trim(),
          'email': email.text.trim(),
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'active': true,
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ، حاول مرة ثانية';

      if (e.code == 'email-already-in-use') {
        message = 'هذا البريد مسجل سابقاً';
      } else if (e.code == 'weak-password') {
        message = 'كلمة المرور ضعيفة، استخدم 6 أحرف أو أكثر';
      } else if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'البريد أو كلمة المرور غير صحيحة';
      } else if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صحيح';
      } else if (e.code == 'network-request-failed') {
        message = 'تأكد من اتصال الإنترنت';
      }

      showMessage(message);
    } catch (e) {
      showMessage('تعذر إكمال العملية. تأكد من إعداد Firebase وقواعد البيانات.');
    }

    if (mounted) {
      setState(() => loading = false);
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget field(
    String label,
    TextEditingController controller, {
    bool secret = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        obscureText: secret,
        keyboardType: keyboard,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.edit, color: gold),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'هذا الحقل مطلوب';
          }

          if (controller == phone && value.trim().length < 10) {
            return 'أدخل رقم هاتف صحيح';
          }

          if (controller == password && value.trim().length < 6) {
            return 'كلمة المرور 6 أحرف على الأقل';
          }

          if (controller == email && !value.contains('@')) {
            return 'أدخل بريد إلكتروني صحيح';
          }

          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: formKey,
              child: Column(
                children: [
                  const Icon(
                    Icons.delivery_dining,
                    color: gold,
                    size: 85,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'دلفري العراق',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: gold,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'طلبك يوصل لباب بيتك',
                    style: TextStyle(color: Colors.white60),
                  ),
                  const SizedBox(height: 30),

                  Text(
                    isRegister ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 22),

                  if (isRegister) ...[
                    field('الاسم الكامل', name),
                    field(
                      'رقم الهاتف',
                      phone,
                      keyboard: TextInputType.phone,
                    ),
                    field('المحافظة', governorate),
                    field('المنطقة أو القضاء', area),

                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'نوع الحساب',
                        style: TextStyle(color: gold, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: roleButton(
                            'زبون',
                            'customer',
                            Icons.person,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: roleButton(
                            'مندوب',
                            'courier',
                            Icons.delivery_dining,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                  ],

                  field(
                    'البريد الإلكتروني',
                    email,
                    keyboard: TextInputType.emailAddress,
                  ),
                  field('كلمة المرور', password, secret: true),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    height: 53,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: loading ? null : submit,
                      child: loading
                          ? const CircularProgressIndicator(
                              color: Colors.black,
                            )
                          : Text(
                              isRegister ? 'إنشاء الحساب' : 'دخول',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  TextButton(
                    onPressed: loading
                        ? null
                        : () {
                            setState(() {
                              isRegister = !isRegister;
                            });
                          },
                    child: Text(
                      isRegister
                          ? 'عندي حساب، تسجيل الدخول'
                          : 'ما عندي حساب، إنشاء حساب جديد',
                      style: const TextStyle(color: gold),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Text(
                    'تطوير وبرمجة: علاوي ال حمادي',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'للشكاوى والتواصل عبر واتساب',
                    style: TextStyle(color: Colors.white54),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      showMessage(
                        'زر واتساب سيتم ربطه في مرحلة التواصل',
                      );
                    },
                    icon: const Icon(Icons.chat, color: gold),
                    label: const Text(
                      '07880254887',
                      style: TextStyle(color: gold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget roleButton(String title, String value, IconData icon) {
    final selected = role == value;

    return InkWell(
      onTap: () => setState(() => role = value),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: selected ? gold.withOpacity(0.15) : panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? gold : Colors.white12,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? gold : Colors.white70,
              size: 30,
            ),
            const SizedBox(height: 7),
            Text(
              title,
              style: TextStyle(
                color: selected ? gold : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatelessWidget {
  final User user;

  const ProfilePage({super.key, required this.user});

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'دلفري العراق',
          style: TextStyle(color: gold, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: logout,
            icon: const Icon(Icons.logout),
            tooltip: 'تسجيل الخروج',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingPage();
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('لم يتم العثور على بيانات الحساب'),
            );
          }

          final data =
              snapshot.data!.data() as Map<String, dynamic>;

          final isCourier = data['role'] == 'courier';

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Icon(
                    isCourier
                        ? Icons.delivery_dining
                        : Icons.person,
                    color: gold,
                    size: 90,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    isCourier ? 'واجهة المندوب' : 'واجهة الزبون',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: gold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  infoTile('الاسم', data['name']),
                  infoTile('رقم الهاتف', data['phone']),
                  infoTile('المحافظة', data['governorate']),
                  infoTile('المنطقة', data['area']),
                  infoTile('البريد الإلكتروني', data['email']),
                  const SizedBox(height: 20),
                  const Text(
                    'تطوير وبرمجة علاوي ال حمادي',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget infoTile(String title, dynamic value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: const TextStyle(color: gold),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? '',
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}