import 'dart:convert'; // Cần thiết để mã hóa Base64
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddVegetable extends StatefulWidget {
  const AddVegetable({super.key});

  @override
  _AddVegetableState createState() => _AddVegetableState();
}

class _AddVegetableState extends State<AddVegetable> {
  final _formKey = GlobalKey<FormState>();
  final _tenController = TextEditingController();
  final _giaController = TextEditingController();
  String _loaiSelected = "Rau";

  XFile? _imageFile;
  String _base64Image = ""; // Biến lưu chuỗi ảnh
  bool _isUploading = false;

  // Hàm chọn ảnh và chuyển sang Base64
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50, // Giảm chất lượng xuống 50% để chuỗi không quá dài
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _base64Image = base64Encode(bytes); // Chuyển ảnh thành chuỗi chữ
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate() || _base64Image.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chọn ảnh và điền đủ thông tin!"),
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Lấy danh sách để tính toán ID tự động tăng
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('vegetables')
          .get();
      int nextId = snapshot.docs.length + 1;

      await FirebaseFirestore.instance.collection('vegetables').add({
        'idsanpham': nextId, // ID tự động tăng
        'tensp': _tenController.text.trim(),
        'gia': int.parse(_giaController.text.trim()),
        'loaisp': _loaiSelected,
        'hinhanh': _base64Image,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print("Lỗi: $e");
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thêm Rau Củ Mới"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Khu vực chọn ảnh
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: _imageFile == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.green,
                            ),
                            Text("Bấm để chọn ảnh từ máy"),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            File(_imageFile!.path),
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _tenController,
                decoration: const InputDecoration(
                  labelText: "Tên sản phẩm",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Nhập tên sản phẩm" : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _giaController,
                decoration: const InputDecoration(
                  labelText: "Giá tiền (VNĐ)",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Nhập giá tiền" : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _loaiSelected,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ["Rau", "Củ", "Nấm"]
                    .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                    .toList(),
                onChanged: (v) => setState(() => _loaiSelected = v!),
              ),
              const SizedBox(height: 30),
              _isUploading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "LƯU SẢN PHẨM",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
