import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false; // Biến để hiện vòng quay load khi đang gửi mail

  // Hàm xử lý chính
  Future<void> _sendResetPasswordEmail() async {
    String email = _emailController.text.trim().toLowerCase();

    // 1. Kiểm tra định dạng Email cơ bản
    if (email.isEmpty || !email.contains("@")) {
      _showMsg("Vui lòng nhập một địa chỉ Email hợp lệ!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Kiểm tra xem Email có tồn tại trong bảng 'users' của Firestore không
      // Bước này để đảm bảo chỉ người dùng của app mới nhận được mail
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userQuery.docs.isEmpty) {
        _showMsg("Email này chưa được đăng ký trong hệ thống!", Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // 3. Gửi Email đặt lại mật khẩu thật từ Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      // 4. Thông báo thành công
      _showMsg(
        "Đã gửi liên kết đổi mật khẩu vào Email của bạn. Kiểm tra cả hòm thư rác nhé!",
        Colors.green,
      );

      // Đợi 3 giây rồi quay lại màn hình Đăng nhập
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) Navigator.pop(context);
      });
    } on FirebaseAuthException catch (e) {
      // Bắt các lỗi từ Firebase (Ví dụ: quá nhiều yêu cầu, email bị chặn...)
      _showMsg("Lỗi Firebase: ${e.message}", Colors.red);
    } catch (e) {
      _showMsg("Lỗi hệ thống: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Khôi phục mật khẩu"),
        backgroundColor: Colors.green,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_reset_rounded, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text(
              "Nhập Email của bạn bên dưới để nhận liên kết đặt lại mật khẩu mới qua Gmail.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
            SizedBox(height: 30),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Địa chỉ Email",
                hintText: "example@gmail.com",
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 25),
            _isLoading
                ? CircularProgressIndicator(color: Colors.green)
                : ElevatedButton(
                    onPressed: _sendResetPasswordEmail,
                    child: Text(
                      "GỬI YÊU CẦU",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
