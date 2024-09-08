import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

FirebaseFirestore db = FirebaseFirestore.instance;

/* Future<List> getgastos() async {
  List NGastos = [];
  CollectionReference collectionReferenceNgastos = db.collection('gastos');
  //abre todos los datos de la tabla
  QuerySnapshot queryGastos = await collectionReferenceNgastos.get();

  queryGastos.docs.forEach((documento) {
    NGastos.add(documento.data());
  });
  return NGastos;
} */


Future<Map<String, dynamic>> getRandomConsejo() async {
  List<Map<String, dynamic>> consejos = [];
  CollectionReference collectionReferenceConsejos = db.collection('consejos');
  // Abre todos los datos de la colección
  QuerySnapshot queryConsejos = await collectionReferenceConsejos.get();

  print('Número de documentos recuperados: ${queryConsejos.docs.length}'); // Mensaje de depuración

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

