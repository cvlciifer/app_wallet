import 'package:flutter/material.dart';

enum Category {
  comidaBebida,
  comprasPersonales,
  salud,
  hogarVivienda,
  transporte,
  vehiculos,
  ocioEntretenimiento,
  serviciosCuentas,
}

extension CategoryX on Category {
  String get displayName {
    switch (this) {
      case Category.comidaBebida:
        return 'Comida y Bebida';
      case Category.comprasPersonales:
        return 'Compras Personales';
      case Category.salud:
        return 'Salud';
      case Category.hogarVivienda:
        return 'Hogar y Vivienda';
      case Category.transporte:
        return 'Transporte';
      case Category.vehiculos:
        return 'Vehículos';
      case Category.ocioEntretenimiento:
        return 'Ocio y entretenimiento';
      case Category.serviciosCuentas:
        return 'Servicios y cuentas';
    }
  }
}

const categoryIcons = {
  Category.comidaBebida: Icons.lunch_dining,
  Category.comprasPersonales: Icons.shopping_bag,
  Category.salud: Icons.health_and_safety,
  Category.hogarVivienda: Icons.home,
  Category.transporte: Icons.directions_bus,
  Category.vehiculos: Icons.directions_car,
  Category.ocioEntretenimiento: Icons.sports_esports,
  Category.serviciosCuentas: Icons.receipt_long,
};

class Subcategory {
  final String id; // machine id
  final String name; // display name
  final IconData icon;
  final Category parent;

  const Subcategory({required this.id, required this.name, required this.icon, required this.parent});
}

const Map<Category, List<Subcategory>> subcategoriesByCategory = {
  Category.comidaBebida: [
    Subcategory(id: 'bar_cafe', name: 'Bar / café', icon: Icons.local_cafe, parent: Category.comidaBebida),
    Subcategory(id: 'restaurante', name: 'Restaurante', icon: Icons.restaurant, parent: Category.comidaBebida),
    Subcategory(
        id: 'supermercado', name: 'Supermercado', icon: Icons.local_grocery_store, parent: Category.comidaBebida),
    Subcategory(id: 'delivery', name: 'Delivery', icon: Icons.delivery_dining, parent: Category.comidaBebida),
    Subcategory(id: 'snacks', name: 'Snacks', icon: Icons.fastfood, parent: Category.comidaBebida),
    Subcategory(id: 'almuerzo_trabajo', name: 'Almuerzo trabajo', icon: Icons.work, parent: Category.comidaBebida),
  ],
  Category.comprasPersonales: [
    Subcategory(id: 'ninos', name: 'Niños', icon: Icons.child_care, parent: Category.comprasPersonales),
    Subcategory(id: 'hogar', name: 'Hogar', icon: Icons.chair, parent: Category.comprasPersonales),
    Subcategory(
        id: 'electronica', name: 'Electrónica', icon: Icons.electrical_services, parent: Category.comprasPersonales),
    Subcategory(id: 'joyas', name: 'Joyas', icon: Icons.watch, parent: Category.comprasPersonales),
    Subcategory(id: 'mascotas', name: 'Mascotas', icon: Icons.pets, parent: Category.comprasPersonales),
    Subcategory(
        id: 'papeleria', name: 'Papelería / Herramientas', icon: Icons.menu_book, parent: Category.comprasPersonales),
    Subcategory(id: 'regalos', name: 'Regalos', icon: Icons.card_giftcard, parent: Category.comprasPersonales),
    Subcategory(id: 'ropa', name: 'Ropa / Calzado', icon: Icons.checkroom, parent: Category.comprasPersonales),
    Subcategory(id: 'salud_belleza', name: 'Salud / Belleza', icon: Icons.spa, parent: Category.comprasPersonales),
    Subcategory(id: 'ocio', name: 'Ocio', icon: Icons.weekend, parent: Category.comprasPersonales),
    Subcategory(
        id: 'tiendas_online', name: 'Tiendas online', icon: Icons.shopping_cart, parent: Category.comprasPersonales),
  ],
  Category.salud: [
    Subcategory(id: 'farmacia', name: 'Farmacia', icon: Icons.local_pharmacy, parent: Category.salud),
    Subcategory(id: 'arriendo_hipoteca', name: 'Arriendo / Hipoteca', icon: Icons.home_work, parent: Category.salud),
    Subcategory(id: 'mantenimiento', name: 'Mantenimiento', icon: Icons.build, parent: Category.salud),
    Subcategory(id: 'seguros', name: 'Seguros', icon: Icons.health_and_safety, parent: Category.salud),
    Subcategory(id: 'servicios', name: 'Servicios', icon: Icons.miscellaneous_services, parent: Category.salud),
  ],
  Category.hogarVivienda: [
    Subcategory(id: 'cuentas', name: 'Cuentas', icon: Icons.receipt, parent: Category.hogarVivienda),
    Subcategory(
        id: 'arriendo_hipoteca', name: 'Arriendo / Hipoteca', icon: Icons.home_work, parent: Category.hogarVivienda),
    Subcategory(id: 'mantenimiento', name: 'Mantenimiento', icon: Icons.build, parent: Category.hogarVivienda),
    Subcategory(id: 'seguros', name: 'Seguros', icon: Icons.shield, parent: Category.hogarVivienda),
    Subcategory(id: 'servicios', name: 'Servicios', icon: Icons.miscellaneous_services, parent: Category.hogarVivienda),
  ],
  Category.transporte: [
    Subcategory(id: 'avion', name: 'Avión', icon: Icons.flight, parent: Category.transporte),
    Subcategory(id: 'taxi_apps', name: 'Taxi / Apps', icon: Icons.local_taxi, parent: Category.transporte),
    Subcategory(id: 'publico', name: 'Público', icon: Icons.directions_bus, parent: Category.transporte),
    Subcategory(id: 'negocios', name: 'Negocios', icon: Icons.business, parent: Category.transporte),
  ],
  Category.vehiculos: [
    Subcategory(id: 'alquiler', name: 'Alquiler', icon: Icons.car_rental, parent: Category.vehiculos),
    Subcategory(id: 'combustible', name: 'Combustible', icon: Icons.local_gas_station, parent: Category.vehiculos),
    Subcategory(id: 'estacionamiento', name: 'Estacionamiento', icon: Icons.local_parking, parent: Category.vehiculos),
    Subcategory(id: 'mantenimiento', name: 'Mantenimiento', icon: Icons.build, parent: Category.vehiculos),
    Subcategory(id: 'seguro_auto', name: 'Seguro auto', icon: Icons.security, parent: Category.vehiculos),
    Subcategory(id: 'autopistas', name: 'Autopistas', icon: Icons.traffic, parent: Category.vehiculos),
    Subcategory(id: 'permiso_circ', name: 'Permiso circ.', icon: Icons.assignment, parent: Category.vehiculos),
    Subcategory(id: 'revision_tec', name: 'Revisión téc.', icon: Icons.build_circle, parent: Category.vehiculos),
    Subcategory(id: 'accesorios', name: 'Accesorios', icon: Icons.extension, parent: Category.vehiculos),
  ],
  Category.ocioEntretenimiento: [
    Subcategory(id: 'cultura', name: 'Cultura', icon: Icons.theater_comedy, parent: Category.ocioEntretenimiento),
    Subcategory(
        id: 'deporte', name: 'Deporte / Fitness', icon: Icons.fitness_center, parent: Category.ocioEntretenimiento),
    Subcategory(id: 'eventos', name: 'Eventos', icon: Icons.event, parent: Category.ocioEntretenimiento),
    Subcategory(id: 'streaming', name: 'Streaming', icon: Icons.tv, parent: Category.ocioEntretenimiento),
    Subcategory(id: 'vacaciones', name: 'Vacaciones', icon: Icons.beach_access, parent: Category.ocioEntretenimiento),
    Subcategory(
        id: 'juegos', name: 'Juegos / Apuestas', icon: Icons.videogame_asset, parent: Category.ocioEntretenimiento),
    Subcategory(id: 'libros', name: 'Libros / Audio', icon: Icons.book, parent: Category.ocioEntretenimiento),
    Subcategory(id: 'cursos', name: 'Cursos / Talleres', icon: Icons.school, parent: Category.ocioEntretenimiento),
  ],
  Category.serviciosCuentas: [
    Subcategory(id: 'electricidad', name: 'Electricidad', icon: Icons.bolt, parent: Category.serviciosCuentas),
    Subcategory(id: 'gas', name: 'Gas', icon: Icons.gas_meter, parent: Category.serviciosCuentas),
    Subcategory(id: 'agua', name: 'Agua', icon: Icons.water, parent: Category.serviciosCuentas),
    Subcategory(id: 'internet', name: 'Internet', icon: Icons.wifi, parent: Category.serviciosCuentas),
    Subcategory(id: 'telefono', name: 'Teléfono', icon: Icons.phone, parent: Category.serviciosCuentas),
    Subcategory(id: 'tv_cable', name: 'TV cable', icon: Icons.tv, parent: Category.serviciosCuentas),
    Subcategory(id: 'basura', name: 'Basura', icon: Icons.delete, parent: Category.serviciosCuentas),
    Subcategory(id: 'gastos_comunes', name: 'Gastos comunes', icon: Icons.apartment, parent: Category.serviciosCuentas),
    Subcategory(
        id: 'suscripciones', name: 'Suscripciones', icon: Icons.subscriptions, parent: Category.serviciosCuentas),
  ],
};
