import 'package:cloud_firestore/cloud_firestore.dart';

FirebaseFirestore db = FirebaseFirestore.instance;

Future<List> getgastos() async {
  List NGastos = [];
  CollectionReference collectionReferenceNgastos = db.collection('gastos');
  //abre todos los datos de la tabla
  QuerySnapshot queryGastos = await collectionReferenceNgastos.get();

  queryGastos.docs.forEach((documento) {
    NGastos.add(documento.data());
  });
  return NGastos;
}
