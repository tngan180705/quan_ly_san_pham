import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_vegetable.dart';

class VegetableList extends StatefulWidget {
  final String userName;
  const VegetableList({super.key, required this.userName});

  @override
  _VegetableListState createState() => _VegetableListState();
}

class _VegetableListState extends State<VegetableList> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // HEADER & SEARCH
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.green,
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
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const Icon(Icons.eco, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 15),
                TextField(
                  onChanged: (value) =>
                      setState(() => searchText = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: "Tìm tên rau...",
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

          // BỘ LỌC (FILTER)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: typeFilter,
                    decoration: const InputDecoration(
                      labelText: "Loại",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    items: ["Tất cả", "Rau", "Củ", "Nấm"]
                        .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) => setState(() => typeFilter = v!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: priceFilter,
                    decoration: const InputDecoration(
                      labelText: "Giá tiền",
                      contentPadding: EdgeInsets.symmetric(horizontal: 10),
                    ),
                    items: ["Tất cả", "Dưới 20k", "Trên 20k"]
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setState(() => priceFilter = v!),
                  ),
                ),
              ],
            ),
          ),

          // DANH SÁCH SẢN PHẨM
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

                  // Logic lọc
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
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: _buildProductImage(data['hinhanh'] ?? ""),
                          ),
                        ),
                        title: Text(
                          "ID: ${data['idsanpham']} - ${data['tensp']}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Loại: ${data['loaisp']}"),
                            Text(
                              "${data['gia']}đ",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                // Logic chỉnh sửa sẽ thêm sau hoặc hướng tới trang Edit
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(context, doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddVegetable()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xóa?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('vegetables')
                  .doc(docId)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
