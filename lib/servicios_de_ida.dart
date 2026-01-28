import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

Future<List<Map<String, dynamic>>> getPersona() async {
  List<Map<String, dynamic>> personas = [];
  CollectionReference collectionReferencePersona =
      db.collection('paradas_salida_tulcan');

  QuerySnapshot queryPersona = await collectionReferencePersona.get();

  for (var documento in queryPersona.docs) {
    final Map<String, dynamic> data = documento.data() as Map<String, dynamic>;
    final persona = {
      'nombre': data['nombre'],
      'precio': data['precio'] ??
          0.0, // Añadir el precio con un valor por defecto de 0.0 si no existe
      'uid': documento.id,
    };
    personas.add(persona);
  }

  return personas;
}

Future<void> agregarpersona(String nombre, double precio) async {
  await db
      .collection('paradas_salida_tulcan')
      .add({'nombre': nombre, 'precio': precio});
}

Future<void> updatePersona(String uid, String newName, double newPrice) async {
  await db.collection('paradas_salida_tulcan').doc(uid).update({
    'nombre': newName,
    'precio': newPrice,
  });
}
