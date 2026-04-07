import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // THÊM MỚI
import 'vegetable_list.dart';
import 'vegetable_user_view.dart';
import 'forgot_password.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();

  final _hoTenController = TextEditingController();
  final _emailController = TextEditingController();
  final _sdtController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // --- CÁC HÀM VALIDATE GIỮ NGUYÊN THEO LOGIC CỦA BẠN ---
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Vui lòng nhập họ và tên';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập Email';
    if (!value.toLowerCase().endsWith('@gmail.com'))
      return 'Email phải có đuôi @gmail.com';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập số điện thoại';
    if (!RegExp(r'^0\d{9}$').hasMatch(value))
      return 'SĐT phải có 10 số và bắt đầu bằng số 0';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
    RegExp regex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$');
    if (!regex.hasMatch(value)) return 'Mật khẩu sai định dạng yêu cầu';
    return null;
  }

  // --- HÀM XỬ LÝ CHÍNH (ĐÃ CẬP NHẬT FIREBASE AUTH) ---
  void _handleAuth() async {
    if (_formKey.currentState!.validate()) {
      String email = _emailController.text.trim().toLowerCase();
      String password = _passwordController.text;

      if (!isLogin) {
        // --- LOGIC ĐĂNG KÝ ---
        if (password != _confirmPasswordController.text) {
          _showSnackBar("Mật khẩu xác nhận không khớp", Colors.red);
          return;
        }

        try {
          // 1. Tạo tài khoản trên Firebase Authentication
          UserCredential userCredential = await FirebaseAuth.instance
              .createUserWithEmailAndPassword(email: email, password: password);

          // 2. Phân quyền theo logic của bạn
          String role = (email == "admin@gmail.com") ? "admin" : "user";

          // 3. Lưu thông tin vào Firestore (Dùng UID của Auth làm ID document cho chuẩn)
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'uid': userCredential.user!.uid,
                'ho_ten': _hoTenController.text.trim(),
                'email': email,
                'so_dien_thoai': _sdtController.text.trim(),
                'role': role,
                // Không nên lưu password vào đây nữa để bảo mật, Auth đã giữ rồi
              });

          _showSnackBar("Đăng ký thành công tài khoản $role!", Colors.green);
          setState(() => isLogin = true);
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            _showSnackBar("Email này đã được sử dụng", Colors.orange);
          } else {
            _showSnackBar("Lỗi: ${e.message}", Colors.red);
          }
        }
      } else {
        // --- LOGIC ĐĂNG NHẬP ---
        try {
          // 1. Đăng nhập bằng Firebase Auth (Sẽ nhận mật khẩu mới đổi từ Gmail)
          UserCredential userCredential = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);

          // 2. Lấy thông tin Role và Name từ Firestore dựa trên UID
          var userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (userDoc.exists) {
            String role = userDoc.data()?['role'] ?? 'user';
            String fetchedName = userDoc.data()?['ho_ten'] ?? 'Người dùng';

            _showSnackBar("Chào mừng $fetchedName ($role)!", Colors.green);

            // 3. Điều hướng dựa trên Role theo logic của bạn
            if (role == 'admin') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => VegetableList(userName: fetchedName),
                ),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      VegetableUserView(userName: fetchedName),
                ),
              );
            }
          }
        } on FirebaseAuthException catch (e) {
          _showSnackBar("Sai Email hoặc mật khẩu", Colors.red);
        } catch (e) {
          _showSnackBar("Lỗi hệ thống: $e", Colors.red);
        }
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLogin ? "ĐĂNG NHẬP" : "ĐĂNG KÝ TÀI KHOẢN",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Image.network(
                    'https://cdn-icons-png.flaticon.com/512/2329/2329813.png',
                    height: 80,
                  ),
                  const SizedBox(height: 20),

                  if (!isLogin) ...[
                    _buildTextField(
                      _hoTenController,
                      "Họ và Tên",
                      Icons.person,
                      _validateName,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildTextField(
                    _emailController,
                    "Gmail (@gmail.com)",
                    Icons.email,
                    _validateEmail,
                  ),
                  const SizedBox(height: 16),

                  if (!isLogin) ...[
                    _buildTextField(
                      _sdtController,
                      "Số điện thoại",
                      Icons.phone,
                      _validatePhone,
                      isPhone: true,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildTextField(
                    _passwordController,
                    "Mật khẩu",
                    Icons.lock,
                    _validatePassword,
                    isPass: true,
                  ),

                  if (!isLogin) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      _confirmPasswordController,
                      "Xác nhận mật khẩu",
                      Icons.lock_reset,
                      null,
                      isPass: true,
                    ),
                  ],

                  if (isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ForgotPasswordPage(),
                          ),
                        ),
                        child: const Text(
                          "Quên mật khẩu?",
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isLogin ? "ĐĂNG NHẬP" : "ĐĂNG KÝ",
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),

                  TextButton(
                    onPressed: () {
                      _formKey.currentState?.reset();
                      setState(() => isLogin = !isLogin);
                    },
                    child: Text(
                      isLogin
                          ? "Chưa có tài khoản? Đăng ký ngay"
                          : "Đã có tài khoản? Đăng nhập",
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    String? Function(String?)? validator, {
    bool isPass = false,
    bool isPhone = false,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: isPass,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.green),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
