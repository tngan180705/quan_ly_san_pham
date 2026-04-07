import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'ui/login.dart'; // Đảm bảo đường dẫn này đúng với dự án của bạn
import 'ui/forgot_password.dart';

void main() async {
  // BẮT BUỘC: Đảm bảo Flutter framework đã sẵn sàng
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Khởi tạo Firebase
    await Firebase.initializeApp();
    print("Kết nối Firebase thành công!");
  } catch (e) {
    print("Lỗi khởi tạo Firebase: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Quản Lý Rau Củ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),

      // 1. Đặt LoginPage làm trang khởi đầu
      initialRoute: '/',

      // 2. Khai báo danh mục các trang (Routes)
      // Điều này giúp hàm Logout gọi tên '/' để quay về trang chủ
      routes: {
        '/': (context) => LoginPage(),
        '/forgot_password': (context) => ForgotPasswordPage(),
        // Nếu bạn có thêm các trang khác, có thể khai báo thêm ở đây
      },
    );
  }
}
