import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminFirebaseScreen extends StatefulWidget {
  const AdminFirebaseScreen({Key? key}) : super(key: key);

  @override
  _AdminFirebaseScreenState createState() => _AdminFirebaseScreenState();
}

class _AdminFirebaseScreenState extends State<AdminFirebaseScreen>
    with SingleTickerProviderStateMixin {
  final Color primaryColor = const Color(0xFFA51444);
  final Color secondaryColor = const Color(0xFFB98C65);
  final Color accentColor = const Color(0xFF2D3142);

  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Controladores para Información de Contacto
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  final _whatsappController = TextEditingController();

  // Controladores para Redes Sociales
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _tiktokController = TextEditingController();
  final _youtubeController = TextEditingController();

  // Controladores para Horarios
  final _horarioDiaController = TextEditingController();
  final _horarioHorasController = TextEditingController();

  // Controladores para Servicios
  final _servicioNombreController = TextEditingController();
  final _servicioDescripcionController = TextEditingController();
  final _servicioIconoController = TextEditingController();
  final _servicioColorController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadContactData();
    _loadSocialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _whatsappController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _youtubeController.dispose();
    _horarioDiaController.dispose();
    _horarioHorasController.dispose();
    _servicioNombreController.dispose();
    _servicioDescripcionController.dispose();
    _servicioIconoController.dispose();
    _servicioColorController.dispose();
    super.dispose();
  }

  Future<void> _loadContactData() async {
    try {
      final doc =
          await _firestore.collection('configuracion').doc('contacto').get();
      if (doc.exists) {
        final data = doc.data()!;
        _telefonoController.text = data['telefono'] ?? '';
        _emailController.text = data['email'] ?? '';
        _direccionController.text = data['direccion'] ?? '';
        _whatsappController.text = data['whatsapp'] ?? '';
        setState(() {});
      }
    } catch (e) {
      _showErrorSnackBar('Error al cargar contacto: $e');
    }
  }

  Future<void> _loadSocialData() async {
    try {
      final doc = await _firestore
          .collection('configuracion')
          .doc('redes_sociales')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _facebookController.text = data['facebook'] ?? '';
        _instagramController.text = data['instagram'] ?? '';
        _tiktokController.text = data['tiktok'] ?? '';
        _youtubeController.text = data['youtube'] ?? '';
        setState(() {});
      }
    } catch (e) {
      _showErrorSnackBar('Error al cargar redes sociales: $e');
    }
  }

  Future<void> _saveContactInfo() async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('configuracion').doc('contacto').set({
        'telefono': _telefonoController.text.trim(),
        'email': _emailController.text.trim(),
        'direccion': _direccionController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'actualizado': FieldValue.serverTimestamp(),
      });
      _showSuccessSnackBar('Información de contacto guardada correctamente');
    } catch (e) {
      _showErrorSnackBar('Error al guardar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSocialLinks() async {
    setState(() => _isLoading = true);
    try {
      await _firestore.collection('configuracion').doc('redes_sociales').set({
        'facebook': _facebookController.text.trim(),
        'instagram': _instagramController.text.trim(),
        'tiktok': _tiktokController.text.trim(),
        'youtube': _youtubeController.text.trim(),
        'whatsapp': _whatsappController.text.trim(),
        'actualizado': FieldValue.serverTimestamp(),
      });
      _showSuccessSnackBar('Redes sociales guardadas correctamente');
    } catch (e) {
      _showErrorSnackBar('Error al guardar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addHorario() async {
    if (_horarioDiaController.text.isEmpty ||
        _horarioHorasController.text.isEmpty) {
      _showErrorSnackBar('Complete todos los campos');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore.collection('horarios').get();
      final orden = snapshot.docs.length + 1;

      await _firestore.collection('horarios').add({
        'dia': _horarioDiaController.text.trim(),
        'horas': _horarioHorasController.text.trim(),
        'orden': orden,
        'activo': true,
        'creado': FieldValue.serverTimestamp(),
      });

      _horarioDiaController.clear();
      _horarioHorasController.clear();
      _showSuccessSnackBar('Horario agregado correctamente');
    } catch (e) {
      _showErrorSnackBar('Error al agregar horario: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteHorario(String id) async {
    try {
      await _firestore.collection('horarios').doc(id).delete();
      _showSuccessSnackBar('Horario eliminado');
    } catch (e) {
      _showErrorSnackBar('Error al eliminar: $e');
    }
  }

  Future<void> _addServicio() async {
    if (_servicioNombreController.text.isEmpty ||
        _servicioDescripcionController.text.isEmpty) {
      _showErrorSnackBar('Complete nombre y descripción');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore.collection('servicios').get();
      final orden = snapshot.docs.length + 1;

      await _firestore.collection('servicios').add({
        'nombre': _servicioNombreController.text.trim(),
        'descripcion': _servicioDescripcionController.text.trim(),
        'icono': _servicioIconoController.text.trim().isEmpty
            ? 'check_circle'
            : _servicioIconoController.text.trim(),
        'color': _servicioColorController.text.trim().isEmpty
            ? '#4CAF50'
            : _servicioColorController.text.trim(),
        'orden': orden,
        'activo': true,
        'creado': FieldValue.serverTimestamp(),
      });

      _servicioNombreController.clear();
      _servicioDescripcionController.clear();
      _servicioIconoController.clear();
      _servicioColorController.clear();
      _showSuccessSnackBar('Servicio agregado correctamente');
    } catch (e) {
      _showErrorSnackBar('Error al agregar servicio: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteServicio(String id) async {
    try {
      await _firestore.collection('servicios').doc(id).delete();
      _showSuccessSnackBar('Servicio eliminado');
    } catch (e) {
      _showErrorSnackBar('Error al eliminar: $e');
    }
  }

  Future<void> _uploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      setState(() => _isLoading = true);

      final File file = File(image.path);
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = _storage.ref().child('informacion/$fileName.jpg');

      await ref.putFile(file);

      _showSuccessSnackBar('Imagen subida correctamente');
    } catch (e) {
      _showErrorSnackBar('Error al subir imagen: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración Firebase'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.contact_phone), text: 'Contacto'),
            Tab(icon: Icon(Icons.share), text: 'Redes Sociales'),
            Tab(icon: Icon(Icons.schedule), text: 'Horarios'),
            Tab(icon: Icon(Icons.miscellaneous_services), text: 'Servicios'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildContactTab(),
          _buildSocialTab(),
          _buildHorariosTab(),
          _buildServiciosTab(),
        ],
      ),
    );
  }

  Widget _buildContactTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Información de Contacto'),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _telefonoController,
            label: 'Teléfono',
            icon: Icons.phone,
            hint: '+593998486809',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email,
            hint: 'info@transdoramald.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _whatsappController,
            label: 'WhatsApp',
            icon: Icons.phone_android,
            hint: '+593998486809',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _direccionController,
            label: 'Dirección',
            icon: Icons.location_on,
            hint: 'Calles Arellano y Junín, Ibarra',
            maxLines: 2,
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveContactInfo,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(_isLoading ? 'Guardando...' : 'Guardar Contacto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _buildSectionTitle('Imágenes del Carrusel'),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.image, color: primaryColor),
              title: const Text('Subir Imagen'),
              subtitle:
                  const Text('Las imágenes se guardan en Storage/informacion'),
              trailing: Icon(Icons.upload, color: primaryColor),
              onTap: _uploadImage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Redes Sociales'),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _facebookController,
            label: 'Facebook',
            icon: Icons.facebook,
            hint: 'https://facebook.com/transdoramald',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _instagramController,
            label: 'Instagram',
            icon: Icons.camera_alt,
            hint: 'https://instagram.com/transdoramald',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _tiktokController,
            label: 'TikTok',
            icon: Icons.video_library,
            hint: 'https://tiktok.com/@transdoramald',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _youtubeController,
            label: 'YouTube',
            icon: Icons.play_circle,
            hint: 'https://youtube.com/@transdoramald',
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveSocialLinks,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.save),
              label:
                  Text(_isLoading ? 'Guardando...' : 'Guardar Redes Sociales'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorariosTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Agregar Horario'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _horarioDiaController,
                label: 'Día(s)',
                icon: Icons.calendar_today,
                hint: 'Ej: Lunes a Viernes',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _horarioHorasController,
                label: 'Horario',
                icon: Icons.access_time,
                hint: 'Ej: 8:00 AM - 12:00 PM',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addHorario,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Horario'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                _firestore.collection('horarios').orderBy('orden').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: primaryColor));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No hay horarios registrados'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryColor,
                        child: Text(
                          '${data['orden']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(data['dia'] ?? ''),
                      subtitle: Text(data['horas'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteHorario(doc.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildServiciosTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.grey[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Agregar Servicio'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _servicioNombreController,
                label: 'Nombre del Servicio',
                icon: Icons.label,
                hint: 'Ej: Transporte Interprovincial',
              ),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _servicioDescripcionController,
                label: 'Descripción',
                icon: Icons.description,
                hint: 'Descripción del servicio',
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _servicioIconoController,
                      label: 'Ícono (opcional)',
                      icon: Icons.star,
                      hint: 'check_circle',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _servicioColorController,
                      label: 'Color (opcional)',
                      icon: Icons.color_lens,
                      hint: '#4CAF50',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addServicio,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar Servicio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream:
                _firestore.collection('servicios').orderBy('orden').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(color: primaryColor));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('No hay servicios registrados'));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: primaryColor,
                        child: Text(
                          '${data['orden']}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(data['nombre'] ?? ''),
                      subtitle: Text(data['descripcion'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteServicio(doc.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: accentColor,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
