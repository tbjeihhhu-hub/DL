
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const gold = Color(0xFFFFC928);
const dark = Color(0xFF101010);
const panel = Color(0xFF202020);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DeliveryApp());
}

class DeliveryApp extends StatelessWidget {
  const DeliveryApp({super.key});

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
        appBarTheme: const AppBarTheme(
          backgroundColor: dark,
          foregroundColor: gold,
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
      builder: (context, auth) {
        if (auth.connectionState == ConnectionState.waiting) {
          return const LoadingPage();
        }

        if (auth.data == null) {
          return const LoginPage();
        }

        return UserHome(user: auth.data!);
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
  bool register = false;
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
      if (register) {
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
      String message = 'تعذر تسجيل الدخول';

      if (e.code == 'email-already-in-use') {
        message = 'هذا البريد مسجل سابقاً';
      } else if (e.code == 'weak-password') {
        message = 'كلمة المرور ضعيفة';
      } else if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        message = 'البريد أو كلمة المرور غير صحيحة';
      } else if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صحيح';
      }

      showMessage(message);
    } catch (e) {
      showMessage('حدث خطأ: $e');
    }

    if (mounted) setState(() => loading = false);
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
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: secret,
        keyboardType: type,
        textDirection: TextDirection.rtl,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return 'هذا الحقل مطلوب';
          }
          if (controller == password && v.length < 6) {
            return 'كلمة المرور 6 أحرف على الأقل';
          }
          if (controller == email && !v.contains('@')) {
            return 'البريد غير صحيح';
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
                    size: 85,
                    color: gold,
                  ),
                  const Text(
                    'دلفري العراق',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: gold,
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text(
                    register ? 'إنشاء حساب' : 'تسجيل الدخول',
                    style: const TextStyle(fontSize: 23),
                  ),
                  const SizedBox(height: 20),

                  if (register) ...[
                    field('الاسم الكامل', name),
                    field('رقم الهاتف', phone,
                        type: TextInputType.phone),
                    field('المحافظة', governorate),
                    field('المنطقة أو القضاء', area),

                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text('نوع الحساب',
                          style: TextStyle(color: gold)),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: ChoiceButton(
                            title: 'زبون',
                            selected: role == 'customer',
                            onTap: () =>
                                setState(() => role = 'customer'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ChoiceButton(
                            title: 'مندوب',
                            selected: role == 'courier',
                            onTap: () =>
                                setState(() => role = 'courier'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                  ],

                  field('البريد الإلكتروني', email,
                      type: TextInputType.emailAddress),
                  field('كلمة المرور', password, secret: true),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: loading ? null : submit,
                      child: loading
                          ? const CircularProgressIndicator()
                          : Text(register ? 'إنشاء الحساب' : 'دخول'),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => register = !register),
                    child: Text(
                      register
                          ? 'عندي حساب'
                          : 'إنشاء حساب جديد',
                      style: const TextStyle(color: gold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'تطوير وبرمجة علاوي ال حمادي',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChoiceButton extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const ChoiceButton({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: selected ? gold : Colors.white,
        side: BorderSide(
          color: selected ? gold : Colors.white24,
        ),
      ),
      onPressed: onTap,
      child: Text(title),
    );
  }
}

class UserHome extends StatelessWidget {
  final User user;

  const UserHome({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingPage();
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('بيانات الحساب غير موجودة')),
          );
        }

        final data =
            snapshot.data!.data() as Map<String, dynamic>;

        if (data['role'] == 'courier') {
          return CourierPage(user: user, profile: data);
        }

        return CustomerPage(user: user, profile: data);
      },
    );
  }
}

class CustomerPage extends StatefulWidget {
  final User user;
  final Map<String, dynamic> profile;

  const CustomerPage({
    super.key,
    required this.user,
    required this.profile,
  });

  @override
  State<CustomerPage> createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final description = TextEditingController();
  bool sending = false;

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  Future<void> sendOrder() async {
    final text = description.text.trim();

    if (text.isEmpty) {
      message('اكتب شنو تريد توصل أولاً');
      return;
    }

    setState(() => sending = true);

    try {
      await FirebaseFirestore.instance.collection('orders').add({
        'customerId': widget.user.uid,
        'customerName': widget.profile['name'],
        'customerPhone': widget.profile['phone'],
        'governorate': widget.profile['governorate'],
        'area': widget.profile['area'],
        'description': text,
        'courierId': null,
        'courierPhone': null,
        'courierName': null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
      });

      description.clear();
      message('تم إرسال طلبك بنجاح، ننتظر قبول المندوب');
    } catch (e) {
      message('تعذر إرسال الطلب: $e');
    }

    if (mounted) setState(() => sending = false);
  }

  void message(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دلفري العراق'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'أهلاً بيك 🌟',
            style: TextStyle(fontSize: 25, color: gold),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.profile['name']} - ${widget.profile['area']}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 22),

          const Text(
            'شنو تريد نوصّلك؟',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: description,
            minLines: 4,
            maxLines: 6,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'اكتب تفاصيل طلبك هنا...',
              filled: true,
              fillColor: panel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 15),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: sending ? null : sendOrder,
              icon: const Icon(Icons.send),
              label: Text(sending ? 'جاري الإرسال...' : 'إرسال الطلب'),
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
              ),
            ),
          ),

          const SizedBox(height: 30),
          const Text(
            'طلباتي',
            style: TextStyle(fontSize: 21, color: gold),
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('customerId', isEqualTo: widget.user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text('تعذر تحميل الطلبات');
              }
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: gold),
                );
              }

              final docs = snapshot.data!.docs.toList();
              docs.sort((a, b) {
                final at = (a.data() as Map<String, dynamic>)['createdAt'];
                final bt = (b.data() as Map<String, dynamic>)['createdAt'];
                if (at is Timestamp && bt is Timestamp) {
                  return bt.compareTo(at);
                }
                return 0;
              });

              if (docs.isEmpty) {
                return const Text('ما عندك طلبات حالياً');
              }

              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return OrderCard(
                    title: d['description'] ?? '',
                    status: d['status'] ?? 'pending',
                    subtitle: d['courierName'] == null
                        ? 'بانتظار قبول المندوب'
                        : 'المندوب: ${d['courierName']} - ${d['courierPhone']}',
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 25),
          const Text(
            'تطوير وبرمجة: علاوي ال حمادي',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class CourierPage extends StatelessWidget {
  final User user;
  final Map<String, dynamic> profile;

  const CourierPage({
    super.key,
    required this.user,
    required this.profile,
  });

  Future<void> acceptOrder(
    BuildContext context,
    DocumentReference ref,
  ) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final fresh = await transaction.get(ref);

        if (!fresh.exists) {
          throw Exception('الطلب لم يعد موجوداً');
        }

        final data = fresh.data() as Map<String, dynamic>;

        if (data['status'] != 'pending' ||
            data['courierId'] != null) {
          throw Exception('مندوب آخر قبل هذا الطلب');
        }

        if (data['governorate'] != profile['governorate'] ||
            data['area'] != profile['area']) {
          throw Exception('هذا الطلب خارج منطقتك');
        }

        transaction.update(ref, {
          'courierId': user.uid,
          'courierName': profile['name'],
          'courierPhone': profile['phone'],
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم قبول الطلب بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لم يتم قبول الطلب: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات المندوب'),
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const Text(
            'الطلبات الجديدة',
            style: TextStyle(
              fontSize: 25,
              color: gold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${profile['governorate']} - ${profile['area']}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 18),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('status', isEqualTo: 'pending')
                .where('governorate', isEqualTo: profile['governorate'])
                .where('area', isEqualTo: profile['area'])
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(
                  'تعذر تحميل الطلبات. إذا ظهر خطأ Index أرسل صورته.',
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: gold),
                );
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(25),
                  child: Text(
                    'ماكو طلبات جديدة بمنطقتك حالياً',
                    textAlign: TextAlign.center,
                  ),
                );
              }

              return Column(
                children: docs.map((doc) {
                  final d = doc.data() as Map<String, dynamic>;

                  return Card(
                    color: panel,
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'طلب جديد',
                            style: TextStyle(
                              color: gold,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text('التفاصيل: ${d['description'] ?? ''}'),
                          Text('الزبون: ${d['customerName'] ?? ''}'),
                          Text('رقم الزبون: ${d['customerPhone'] ?? ''}'),
                          Text('المحافظة: ${d['governorate'] ?? ''}'),
                          Text('المنطقة: ${d['area'] ?? ''}'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => acceptOrder(context, doc.reference),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gold,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('قبول الطلب'),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 25),
          const Text(
            'تطوير وبرمجة: علاوي ال حمادي',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54),
          ),
        ],
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  final String title;
  final String status;
  final String subtitle;

  const OrderCard({
    super.key,
    required this.title,
    required this.status,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final accepted = status == 'accepted';

    return Card(
      color: panel,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(title),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(subtitle),
        ),
        trailing: Icon(
          accepted ? Icons.check_circle : Icons.hourglass_top,
          color: accepted ? Colors.green : gold,
        ),
      ),
    );
  }
}
