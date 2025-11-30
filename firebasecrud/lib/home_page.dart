import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'services/crud_services.dart';
import 'services/auth_service.dart';
import 'login_page.dart';
import 'cloudinary_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CrudServices service = CrudServices();
  final AuthService _authService = AuthService();
  final TextEditingController nameCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  bool _showFavoritesOnly = false;
  final ImagePicker _picker = ImagePicker();
  String? _imageUrl;

  @override
  void dispose() {
    nameCtrl.dispose();
    qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      final bytes = await pickedFile.readAsBytes();
      final url = await CloudinaryService.uploadBytes(bytes, pickedFile.name);
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image upload failed: $e')));
    }
  }

  void openAddDialog() {
    nameCtrl.clear();
    qtyCtrl.clear();
    _imageUrl = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pickAndUploadImage,
              icon: const Icon(Icons.image),
              label: const Text('Choose Image'),
            ),
            if (_imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Image.network(_imageUrl!, height: 80, fit: BoxFit.cover),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                try {
                  await service.addItem(
                    nameCtrl.text,
                    qtyCtrl.text,
                    imageUrl: _imageUrl,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding item: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void openEditDialog(QueryDocumentSnapshot item) {
    nameCtrl.text = item['name'];
    qtyCtrl.text = item['quantity'];
    final existingImage = (item['imageUrl'] ?? '').toString();
    _imageUrl = existingImage.isEmpty ? null : existingImage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: qtyCtrl,
              decoration: const InputDecoration(labelText: 'Quantity'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pickAndUploadImage,
              icon: const Icon(Icons.image),
              label: const Text('Change Image'),
            ),
            if (_imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Image.network(_imageUrl!, height: 80, fit: BoxFit.cover),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isNotEmpty && qtyCtrl.text.isNotEmpty) {
                try {
                  await service.updateItem(
                    item.id,
                    nameCtrl.text,
                    qtyCtrl.text,
                    imageUrl: _imageUrl,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating item: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FireBaseCrud-Culaba'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _authService.signOut();

              if (!mounted) return;

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (route) => false,
              );
            },
          ),
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _showFavoritesOnly ? Colors.red : null,
            ),
            onPressed: () {
              setState(() {
                _showFavoritesOnly = !_showFavoritesOnly;
              });
            },
            tooltip: 'Filter Favorites',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _showFavoritesOnly
            ? service.getFavoriteItemsStream()
            : service.getItemsStream(),
        builder: (context, snapshot) {
          try {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No data available'));
            }

            final docs = snapshot.data!.docs;

            if (docs.isEmpty) {
              return Center(
                child: Text(
                  _showFavoritesOnly
                      ? 'No favorite items found'
                      : 'No items found',
                ),
              );
            }

            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final item = docs[index];
                final data = item.data() as Map<String, dynamic>?;

                final String name = (data?['name'] ?? '').toString();
                final String quantity = (data?['quantity'] ?? '').toString();
                final bool isFavorite = (data?['isFavorite'] as bool?) ?? false;
                final String imageUrl = (data?['imageUrl'] ?? '').toString();

                return ListTile(
                  leading: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(name.isEmpty ? 'Unnamed item' : name),
                  subtitle: Text(
                    quantity.isEmpty ? 'No quantity set' : 'Qty: $quantity',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : null,
                        ),
                        onPressed: () async {
                          try {
                            await service.toggleFavorite(item.id, !isFavorite);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error toggling favorite: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => openEditDialog(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          try {
                            await service.deleteItem(item.id);
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error deleting item: $e'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          } catch (e) {
            return Center(child: Text('Stream error: $e'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
