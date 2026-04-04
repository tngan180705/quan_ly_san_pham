import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // Import thư viện gây lỗi
import 'ui/login.dart'; // Đảm bảo bạn đã có file này trong thư mục lib/ui/

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
      home: LoginPage(), // Chuyển đến màn hình Login của bạn
    );
  }
}
