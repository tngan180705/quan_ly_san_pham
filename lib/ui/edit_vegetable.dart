import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditVegetable extends StatefulWidget {
  final String docId; // ID của document trên Firestore
  final Map<String, dynamic> currentData; // Dữ liệu hiện tại của sản phẩm

  const EditVegetable({
    super.key,
    required this.docId,
    required this.currentData,
  });

  @override
  _EditVegetableState createState() => _EditVegetableState();
}

class _EditVegetableState extends State<EditVegetable> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tenController;
  late TextEditingController _giaController;
  late String _loaiSelected;

  XFile? _imageFile;
  String _base64Image = "";
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Đổ dữ liệu cũ vào các ô nhập liệu
    _tenController = TextEditingController(text: widget.currentData['tensp']);
    _giaController = TextEditingController(
      text: widget.currentData['gia'].toString(),
    );
    _loaiSelected = widget.currentData['loaisp'];
    _base64Image = widget.currentData['hinhanh'];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 40, // Nén ảnh để chuỗi Base64 nhẹ hơn
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageFile = pickedFile;
        _base64Image = base64Encode(bytes);
      });
    }
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUpdating = true);

    try {
      // Sử dụng .update() thay vì .add()
      await FirebaseFirestore.instance
          .collection('vegetables')
          .doc(widget.docId)
          .update({
            'tensp': _tenController.text.trim(),
            'gia': int.parse(_giaController.text.trim()),
            'loaisp': _loaiSelected,
            'hinhanh': _base64Image,
            'updatedAt': FieldValue.serverTimestamp(), // Lưu vết thời gian sửa
          });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!")));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi cập nhật: $e")));
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chỉnh sửa sản phẩm"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Hiển thị ảnh cũ hoặc ảnh mới chọn
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.blueAccent.withOpacity(0.5),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _imageFile != null
                        ? Image.file(File(_imageFile!.path), fit: BoxFit.cover)
                        : (_base64Image.startsWith('http')
                              ? Image.network(_base64Image, fit: BoxFit.cover)
                              : Image.memory(
                                  base64Decode(_base64Image),
                                  fit: BoxFit.cover,
                                )),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Bấm vào ảnh để thay đổi",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _tenController,
                decoration: const InputDecoration(
                  labelText: "Tên sản phẩm",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? "Không được để trống" : null,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _giaController,
                decoration: const InputDecoration(
                  labelText: "Giá tiền",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Không được để trống" : null,
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

              _isUpdating
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _updateProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "CẬP NHẬT THÔNG TIN",
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
