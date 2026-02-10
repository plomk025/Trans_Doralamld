import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageManagementPage extends StatefulWidget {
  const ImageManagementPage({Key? key}) : super(key: key);

  @override
  _ImageManagementPageState createState() => _ImageManagementPageState();
}

class _ImageManagementPageState extends State<ImageManagementPage>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  List<String> imageUrls = [];
  bool _isLoading = false;
  bool _isUploading = false;
  late AnimationController _animationController;

  // Paleta de colores moderna
  static const Color primaryBusBlue = Color(0xFF940016);
  static const Color accentOrange = Color(0xFFEA580C);
  static const Color darkNavy = Color(0xFF0F172A);
  static const Color lightBg = Color(0xFFF1F5F9);
  static const Color textGray = Color(0xFF475569);
  static const Color successGreen = Color(0xFF059669);
  static const Color accentRed = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    fetchImageUrls();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      _animationController.forward();
    }
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      _animationController.forward();
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      _showSnackBar('Por favor selecciona una imagen primero', accentOrange);
      return;
    }

    setState(() {
      _isUploading = true;
    });

    final storageRef = FirebaseStorage.instance.ref();
    final imageRef = storageRef
        .child('informacion/${DateTime.now().millisecondsSinceEpoch}.jpg');

    try {
      await imageRef.putFile(_selectedImage!);
      final imageUrl = await imageRef.getDownloadURL();
      setState(() {
        imageUrls.insert(0, imageUrl);
        _selectedImage = null;
        _isUploading = false;
      });
      _animationController.reverse();
      _showSnackBar('¡Imagen subida exitosamente!', successGreen);
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showSnackBar('Error al subir la imagen', accentRed);
      print('Error al subir la imagen: $e');
    }
  }

  Future<void> fetchImageUrls() async {
    setState(() {
      _isLoading = true;
    });

    final storageRef = FirebaseStorage.instance.ref();
    final imageFolderRef = storageRef.child('informacion');

    try {
      final listResult = await imageFolderRef.listAll();
      imageUrls.clear();

      for (final item in listResult.items) {
        final imageUrl = await item.getDownloadURL();
        imageUrls.add(imageUrl);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error al cargar las imágenes', accentRed);
      print('Error al obtener las URLs de las imágenes: $e');
    }
  }

  Future<void> changeImage(String oldImageUrl) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        final storageRef = FirebaseStorage.instance.refFromURL(oldImageUrl);
        await storageRef.putFile(File(pickedFile.path));
        final newImageUrl = await storageRef.getDownloadURL();
        setState(() {
          final index = imageUrls.indexOf(oldImageUrl);
          if (index != -1) {
            imageUrls[index] = newImageUrl;
          }
        });
        _showSnackBar('¡Imagen actualizada!', successGreen);
      } catch (e) {
        _showSnackBar('Error al cambiar la imagen', accentRed);
        print('Error al cambiar la imagen: $e');
      }
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    final confirm = await _showConfirmDialog(
      '¿Eliminar imagen?',
      '¿Estás seguro de que deseas eliminar esta imagen? Esta acción no se puede deshacer.',
    );

    if (confirm == true) {
      try {
        final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await storageRef.delete();
        setState(() {
          imageUrls.remove(imageUrl);
        });
        _showSnackBar('Imagen eliminada', successGreen);
      } catch (e) {
        _showSnackBar('Error al eliminar la imagen', accentRed);
        print('Error al eliminar la imagen: $e');
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == successGreen
                  ? Icons.check_circle_outline
                  : color == accentOrange
                      ? Icons.info_outline
                      : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: accentRed,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: darkNavy,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: textGray,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: textGray,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentRed,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Eliminar',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 248, 255),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _buildHeader(context),
          ),
          SliverToBoxAdapter(
            child: _isLoading ? _buildLoadingState() : _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 243, 248, 255),
            Color.fromARGB(255, 245, 249, 255)
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(0, 255, 255, 255),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color.fromARGB(0, 255, 255, 255)
                                    .withOpacity(0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF940016),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GESTIÓN DE IMÁGENES',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: darkNavy,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            'Galería de información',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: textGray,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: fetchImageUrls,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color.fromARGB(0, 255, 255, 255),
                            const Color.fromARGB(0, 255, 255, 255)
                                .withOpacity(0.9)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(0, 255, 255, 255)
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFF940016),
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Galería de Imágenes',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: darkNavy,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Administra las imágenes informativas de la aplicación',
                style: TextStyle(
                  fontSize: 14,
                  color: textGray,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _buildStatChip(Icons.verified_rounded, 'Seguro'),
                  const SizedBox(width: 10),
                  _buildStatChip(Icons.cloud_upload_rounded, 'Cloud'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: primaryBusBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBusBlue.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: primaryBusBlue, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primaryBusBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryBusBlue),
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Cargando imágenes...',
              style: TextStyle(
                fontSize: 14,
                color: textGray,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estadísticas
          _buildStatsCard(),
          const SizedBox(height: 20),

          // Sección de carga
          _buildUploadSection(),
          const SizedBox(height: 20),

          // Galería
          _buildGallerySection(),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBusBlue, primaryBusBlue.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBusBlue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL DE IMÁGENES',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${imageUrls.length}',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.photo_library_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accentOrange, accentOrange.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_photo_alternate_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agregar Nueva Imagen',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: darkNavy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Selecciona desde galería o toma una foto',
                    style: TextStyle(
                      fontSize: 12,
                      color: textGray,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryBusBlue,
                    side: BorderSide(color: primaryBusBlue, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Galería',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _takePhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBusBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    shadowColor: primaryBusBlue.withOpacity(0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Cámara',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                          });
                          _animationController.reverse();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [accentRed, accentRed.withOpacity(0.9)],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentRed.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: successGreen.withOpacity(0.6),
                ),
                child: _isUploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Subiendo...',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload_rounded, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Subir Imagen',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Galería',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: darkNavy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  imageUrls.isEmpty
                      ? 'No hay imágenes disponibles'
                      : '${imageUrls.length} ${imageUrls.length == 1 ? 'imagen' : 'imágenes'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            if (imageUrls.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBusBlue, primaryBusBlue.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBusBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  '${imageUrls.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (imageUrls.isEmpty)
          _buildEmptyState()
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              final imageUrl = imageUrls[index];
              return _buildImageCard(imageUrl);
            },
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: lightBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: textGray,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay imágenes disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: darkNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sube tu primera imagen para comenzar',
              style: TextStyle(
                fontSize: 13,
                color: textGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: lightBg,
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(primaryBusBlue),
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: lightBg,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          size: 40,
                          color: textGray.withOpacity(0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error al cargar',
                          style: TextStyle(
                            fontSize: 11,
                            color: textGray,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: lightBg,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => changeImage(imageUrl),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 16, color: primaryBusBlue),
                          SizedBox(width: 6),
                          Text(
                            'Editar',
                            style: TextStyle(
                              fontSize: 12,
                              color: primaryBusBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => deleteImage(imageUrl),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: accentRed,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Eliminar',
                            style: TextStyle(
                              fontSize: 12,
                              color: accentRed,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
