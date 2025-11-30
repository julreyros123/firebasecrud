import 'package:cloud_firestore/cloud_firestore.dart';

class CrudServices {
  final CollectionReference _items = FirebaseFirestore.instance.collection(
    'items',
  );

  Stream<QuerySnapshot> getItemsStream() {
    return _items.orderBy('name').snapshots();
  }

  Future<void> addItem(String name, String quantity, {String? imageUrl}) {
    return _items.add({
      'name': name,
      'quantity': quantity,
      'imageUrl': imageUrl ?? '',
      'isFavorite': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateItem(
    String id,
    String name,
    String quantity, {
    bool? isFavorite,
    String? imageUrl,
  }) {
    final Map<String, dynamic> updateData = {
      'name': name,
      'quantity': quantity,
    };
    if (isFavorite != null) {
      updateData['isFavorite'] = isFavorite;
    }
    if (imageUrl != null) {
      updateData['imageUrl'] = imageUrl;
    }
    return _items.doc(id).update(updateData);
  }

  Future<void> deleteItem(String id) {
    return _items.doc(id).delete();
  }

  Stream<QuerySnapshot> getFavoriteItemsStream() {
    return _items.where('isFavorite', isEqualTo: true).snapshots();
  }

  Future<void> toggleFavorite(String id, bool isFavorite) async {
    try {
      await _items.doc(id).update({'isFavorite': isFavorite});
    } catch (e) {
      await _items.doc(id).set({
        'isFavorite': isFavorite,
      }, SetOptions(merge: true));
    }
  }
}
