import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VegetableUserView extends StatefulWidget {
  final String userName;
  const VegetableUserView({super.key, required this.userName});

  @override
  _VegetableUserViewState createState() => _VegetableUserViewState();
}

class _VegetableUserViewState extends State<VegetableUserView> {
  String searchText = "";
  String priceFilter = "Tất cả";
  String typeFilter = "Tất cả";

  Widget _buildProductImage(String imageData) {
    if (imageData.isEmpty) return const Icon(Icons.image, color: Colors.grey);
    if (imageData.startsWith('http')) {
      return Image.network(
        imageData,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    }
    try {
      return Image.memory(
        base64Decode(imageData),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    } catch (e) {
      return const Icon(Icons.broken_image);
    }
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn muốn thoát ra màn hình đăng nhập?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/', (route) => false),
            child: const Text("Đồng ý", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 37, 124, 16),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Xin chào, ${widget.userName}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        // ICON GIỎ HÀNG (Chỉ có ở trang User)
                        IconButton(
                          icon: const Icon(
                            Icons.shopping_cart,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Tính năng giỏ hàng đang phát triển",
                                ),
                              ),
                            );
                          },
                        ),
                        // ICON LOGOUT
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () => _handleLogout(context),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                  onChanged: (value) =>
                      setState(() => searchText = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Tìm sản phẩm...",
                    prefixIcon: const Icon(Icons.search, color: Colors.green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // BỘ LỌC
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: typeFilter,
                    items: ["Tất cả", "Rau", "Củ", "Nấm"]
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => typeFilter = v!),
                    decoration: const InputDecoration(labelText: "Loại"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: priceFilter,
                    items: ["Tất cả", "Dưới 20k", "Trên 20k"]
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() => priceFilter = v!),
                    decoration: const InputDecoration(labelText: "Giá"),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vegetables')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                var docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  bool matchesName = data['tensp']
                      .toString()
                      .toLowerCase()
                      .contains(searchText);
                  bool matchesType =
                      typeFilter == "Tất cả" || data['loaisp'] == typeFilter;
                  int price = int.tryParse(data['gia'].toString()) ?? 0;
                  bool matchesPrice = true;
                  if (priceFilter == "Dưới 20k") matchesPrice = price < 20000;
                  if (priceFilter == "Trên 20k") matchesPrice = price >= 20000;
                  return matchesName && matchesType && matchesPrice;
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 60,
                            height: 60,
                            child: _buildProductImage(data['hinhanh'] ?? ""),
                          ),
                        ),
                        title: Text(
                          data['tensp'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text("${data['gia']}đ - ${data['loaisp']}"),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
