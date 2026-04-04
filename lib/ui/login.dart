import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();

  final _hoTenController = TextEditingController();
  final _sdtController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // 1. Kiểm tra Họ Tên (Không được bỏ trống)
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập họ và tên';
    }
    return null;
  }

  // 2. Kiểm tra SĐT (Không bỏ trống + Đúng định dạng)
  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập số điện thoại';
    }
    RegExp regex = RegExp(r'^0\d{9}$');
    if (!regex.hasMatch(value)) {
      return 'SĐT phải có 10 số và bắt đầu bằng số 0';
    }
    return null;
  }

  // 3. Kiểm tra Mật khẩu (Không bỏ trống + Đúng định dạng)
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    RegExp regex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$&*~]).{8,}$');
    if (!regex.hasMatch(value)) {
      return 'Mật khẩu sai định dạng yêu cầu';
    }
    return null;
  }

  void _handleAuth() async {
    // KÍCH HOẠT KIỂM TRA LỖI: Dòng này sẽ làm hiện chữ đỏ dưới các ô nhập
    if (_formKey.currentState!.validate()) {
      // Nếu tất cả các ô đều hợp lệ thì mới chạy vào đây
      if (!isLogin) {
        if (_passwordController.text != _confirmPasswordController.text) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Mật khẩu xác nhận không khớp"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        try {
          await FirebaseFirestore.instance.collection('users').add({
            'ho_ten': _hoTenController.text,
            'so_dien_thoai': _sdtController.text,
            'password': _passwordController.text,
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đăng ký thành công!"),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            isLogin = true;
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Lỗi hệ thống: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Logic Đăng nhập
        var user = await FirebaseFirestore.instance
            .collection('users')
            .where('so_dien_thoai', isEqualTo: _sdtController.text)
            .where('password', isEqualTo: _passwordController.text)
            .get();

        if (user.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Chào mừng ${user.docs.first['ho_ten']}!"),
              backgroundColor: Colors.green,
            ),
          );
          // Navigator.pushNamed(context, '/vegetable_list');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sai SĐT hoặc mật khẩu"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // Nếu có lỗi (để trống hoặc sai định dạng), Flutter sẽ tự hiện chữ đỏ bên dưới ô đó
      print("Form không hợp lệ");
    }
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
              key: _formKey, // Key này rất quan trọng để kích hoạt báo lỗi
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

                  if (!isLogin)
                    TextFormField(
                      controller: _hoTenController,
                      validator: _validateName, // Gán hàm kiểm tra lỗi vào đây
                      decoration: InputDecoration(
                        labelText: "Họ và Tên",
                        prefixIcon: const Icon(
                          Icons.person,
                          color: Colors.green,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  if (!isLogin) const SizedBox(height: 16),

                  TextFormField(
                    controller: _sdtController,
                    validator: _validatePhone, // Gán hàm kiểm tra lỗi vào đây
                    decoration: InputDecoration(
                      labelText: "Số điện thoại",
                      helperText: "VD: 0901234567",
                      prefixIcon: const Icon(Icons.phone, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    validator:
                        _validatePassword, // Gán hàm kiểm tra lỗi vào đây
                    decoration: InputDecoration(
                      labelText: "Mật khẩu",
                      helperText: !isLogin
                          ? "8 ký tự, có chữ Hoa, Số, Ký tự đặc biệt"
                          : null,
                      prefixIcon: const Icon(Icons.lock, color: Colors.green),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    obscureText: true,
                  ),

                  if (!isLogin) const SizedBox(height: 16),
                  if (!isLogin)
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: "Xác nhận mật khẩu",
                        prefixIcon: const Icon(
                          Icons.lock_reset,
                          color: Colors.green,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      obscureText: true,
                    ),

                  const SizedBox(height: 24),
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
                      _formKey.currentState
                          ?.reset(); // Xóa sạch lỗi cũ khi chuyển chế độ
                      setState(() {
                        isLogin = !isLogin;
                      });
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
}
