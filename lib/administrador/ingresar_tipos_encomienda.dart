// ============================================
// TAB: TIPOS DE ENCOMIENDA
// ============================================
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TiposEncomiendaTab extends StatefulWidget {
  const TiposEncomiendaTab({super.key});
  @override
  State<TiposEncomiendaTab> createState() => _TiposEncomiendaTabState();
}

class _TiposEncomiendaTabState extends State<TiposEncomiendaTab> {
  static const Color lightGray = Color(0xFFF7FAFC);
  static const Color mediumGray = Color(0xFF718096);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningRed = Color(0xFFEF4444);
  void _mostrarDialogoAgregar() {
    final tipoController = TextEditingController();
    final descripcionController = TextEditingController();
    final precioController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_box, color: accentBlue, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Nuevo Tipo de Encomienda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tipoController,
                decoration: InputDecoration(
                  labelText: 'Tipo *',
                  hintText: 'Ej: Documento, Paquete, Frágil',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.category, color: accentBlue),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descripcionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Descripción del tipo de encomienda',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.description, color: accentBlue),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: precioController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Precio Adicional *',
                  hintText: 'Ej: 5.00',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.attach_money, color: accentBlue),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: mediumGray)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (tipoController.text.isEmpty ||
                  precioController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Complete los campos obligatorios'),
                    backgroundColor: warningRed,
                  ),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('Tipo_encomienda')
                    .add({
                  'Tipo': tipoController.text.trim(),
                  'descripcion': descripcionController.text.trim(),
                  'precio_adicional': double.parse(precioController.text),
                  'activo': true,
                  'fecha_creacion': FieldValue.serverTimestamp(),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tipo de encomienda agregado exitosamente'),
                      backgroundColor: successGreen,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: warningRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditar(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final tipoController = TextEditingController(text: data['Tipo'] ?? '');
    final descripcionController =
        TextEditingController(text: data['descripcion'] ?? '');
    final precioController = TextEditingController(
        text: data['precio_adicional'] != null
            ? data['precio_adicional'].toString()
            : '0.0');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.edit, color: accentBlue, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Editar Tipo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tipoController,
                decoration: InputDecoration(
                  labelText: 'Tipo *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.category, color: accentBlue),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descripcionController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.description, color: accentBlue),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: precioController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Precio Adicional *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Icons.attach_money, color: accentBlue),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: mediumGray)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('Tipo_encomienda')
                    .doc(doc.id)
                    .update({
                  'Tipo': tipoController.text.trim(),
                  'descripcion': descripcionController.text.trim(),
                  'precio_adicional': double.parse(precioController.text),
                });

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tipo actualizado exitosamente'),
                      backgroundColor: successGreen,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: warningRed,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child:
                const Text('Actualizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Tipo_encomienda')
            .orderBy('Tipo')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final tipos = snapshot.data!.docs;

          if (tipos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 100, color: mediumGray.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No hay tipos de encomienda registrados',
                    style: TextStyle(fontSize: 16, color: mediumGray),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: tipos.length,
            itemBuilder: (context, index) {
              final tipo = tipos[index];
              final data = tipo.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.category, color: accentBlue, size: 28),
                  ),
                  title: Text(
                    data['Tipo'],
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      if (data['descripcion'] != null &&
                          data['descripcion'].isNotEmpty)
                        Text(
                          data['descripcion'],
                          style:
                              const TextStyle(color: mediumGray, fontSize: 13),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.attach_money,
                              size: 16, color: successGreen),
                          const SizedBox(width: 4),
                          Text(
                            '\$${(data['precio_adicional'] ?? 0.0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: successGreen,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: data['activo'] == true
                                  ? successGreen.withOpacity(0.1)
                                  : warningRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              data['activo'] == true ? 'Activo' : 'Inactivo',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: data['activo'] == true
                                    ? successGreen
                                    : warningRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.edit, size: 20, color: accentBlue),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                        onTap: () => Future.delayed(
                          Duration.zero,
                          () => _mostrarDialogoEditar(tipo),
                        ),
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(
                              data['activo'] == true
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              size: 20,
                              color: mediumGray,
                            ),
                            const SizedBox(width: 8),
                            Text(data['activo'] == true
                                ? 'Desactivar'
                                : 'Activar'),
                          ],
                        ),
                        onTap: () async {
                          await FirebaseFirestore.instance
                              .collection('Tipo_encomienda')
                              .doc(tipo.id)
                              .update({'activo': !(data['activo'] ?? false)});
                        },
                      ),
                      PopupMenuItem(
                        child: const Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: warningRed),
                            SizedBox(width: 8),
                            Text('Eliminar',
                                style: TextStyle(color: warningRed)),
                          ],
                        ),
                        onTap: () async {
                          await FirebaseFirestore.instance
                              .collection('Tipo_encomienda')
                              .doc(tipo.id)
                              .delete();
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoAgregar,
        backgroundColor: accentBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Agregar Tipo',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
