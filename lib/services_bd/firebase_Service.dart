import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

FirebaseFirestore db = FirebaseFirestore.instance;

// CRUD READ
Future<List> getGastos() async {
  List lisgastos = [];
  CollectionReference collectionReferenceGastos = db.collection('gastos');
  QuerySnapshot queryGastos = await collectionReferenceGastos.get();

  for (var doc in queryGastos.docs) {
    final Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
    final gastos = {
      'id': doc.id,
      'name': docData['name'],
      'fecha': docData['fecha'],
      'cantidad': docData['cantidad'],
      'tipo': docData['tipo'],
    };
    lisgastos.add(gastos);
  }

  return lisgastos;
}

Future<Map<String, dynamic>> getRandomConsejo() async {
  List<Map<String, dynamic>> consejos = [];
  CollectionReference collectionReferenceConsejos = db.collection('consejos');
  // Abre todos los datos de la colección
  QuerySnapshot queryConsejos = await collectionReferenceConsejos.get();
// Mensaje de depuración
  print('Número de documentos recuperados: ${queryConsejos.docs.length}');

  queryConsejos.docs.forEach((documento) {
    print('Documento: ${documento.data()}'); // Mensaje de depuración
    consejos.add(documento.data() as Map<String, dynamic>);
  });

  if (consejos.isEmpty) {
    return {}; // Retorna un mapa vacío si no hay consejos
  }

  // Retorna un consejo aleatorio de la lista
  final randomIndex = Random().nextInt(consejos.length);
  return consejos[randomIndex];
}
