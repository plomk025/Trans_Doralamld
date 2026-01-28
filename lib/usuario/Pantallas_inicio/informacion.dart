import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_storage/firebase_storage.dart';

class TransDoramaldHomeScreen extends StatefulWidget {
  const TransDoramaldHomeScreen({Key? key}) : super(key: key);

  @override
  _TransDoramaldHomeScreenState createState() =>
      _TransDoramaldHomeScreenState();
}

class _TransDoramaldHomeScreenState extends State<TransDoramaldHomeScreen>
    with TickerProviderStateMixin {
  final Color primaryColor = const Color(0xFF940016);
  final Color secondaryColor = const Color(0xFFB98C65);
  final Color accentColor = const Color(0xFF2D3142);

  AnimationController? _tabController;
  AnimationController? _fadeController;
  int _currentCarouselIndex = 0;
  int _selectedTab = 0;

  List<String> imgList = [];
  bool isLoadingImages = true;

  final Map<String, String> contactInfo = {
    'phone': '+593991967680',
    'email': 'info@transdoramald.com',
    'whatsapp': '+593991967680',
    'address': 'Calles Arellano y Junín, Tulcan',
  };

  @override
  void initState() {
    super.initState();
    _tabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController?.forward();
    _loadImagesFromFirebase();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _fadeController?.dispose();
    super.dispose();
  }

  Future<void> _loadImagesFromFirebase() async {
    if (!mounted) return;

    try {
      setState(() => isLoadingImages = true);

      final storageRef = FirebaseStorage.instance.ref().child('informacion');
      final listResult = await storageRef.listAll();

      List<String> urls = [];
      for (var item in listResult.items) {
        final ext = item.name.toLowerCase();
        if (ext.endsWith('.jpg') ||
            ext.endsWith('.jpeg') ||
            ext.endsWith('.png') ||
            ext.endsWith('.webp')) {
          final url = await item.getDownloadURL();
          urls.add(url);
        }
      }

      if (!mounted) return;
      setState(() {
        imgList = urls;
        isLoadingImages = false;
      });
    } catch (e) {
      debugPrint('Error al cargar imágenes: $e');
      if (!mounted) return;
      setState(() => isLoadingImages = false);
    }
  }

  Future<void> _launchUrl(String url,
      {LaunchMode mode = LaunchMode.externalApplication}) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: mode);
      }
    } catch (e) {
      debugPrint('Error al abrir URL: $e');
    }
  }

  void _changeTab(int index) {
    setState(() => _selectedTab = index);
    _fadeController?.reset();
    _fadeController?.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 243, 248, 255),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeroCarousel()),
          SliverToBoxAdapter(child: _buildCompanyStats()),
          SliverToBoxAdapter(child: _buildTabNavigation()),
          SliverToBoxAdapter(child: _buildTabContent()),
          SliverToBoxAdapter(child: _buildCTASection()),
          SliverToBoxAdapter(child: _buildProfessionalFooter()),
        ],
      ),
      floatingActionButton: _buildQuickActions(),
    );
  }

  Widget _buildHeroCarousel() {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            isLoadingImages
                ? _buildLoadingCarousel()
                : imgList.isEmpty
                    ? _buildEmptyCarousel()
                    : _buildImageCarousel(),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            if (!isLoadingImages && imgList.isNotEmpty)
              Positioned(
                bottom: 40,
                left: 40,
                right: 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Trans Doramald 2026',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Liderando el Transporte Rural ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildCarouselBadge(
                          Icons.shield_rounded,
                          'Seguridad Garantizada',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (!isLoadingImages && imgList.isNotEmpty)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: imgList.asMap().entries.map((entry) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _currentCarouselIndex == entry.key ? 32 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentCarouselIndex == entry.key
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCarousel() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: CircularProgressIndicator(color: primaryColor),
      ),
    );
  }

  Widget _buildEmptyCarousel() {
    return Container(
      color: Colors.grey[300],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 64, color: Colors.grey[600]),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadImagesFromFirebase,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return CarouselSlider(
      options: CarouselOptions(
        height: double.infinity,
        viewportFraction: 1.0,
        autoPlay: true,
        autoPlayInterval: const Duration(seconds: 5),
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        autoPlayCurve: Curves.easeInOutCubic,
        onPageChanged: (index, reason) {
          setState(() => _currentCarouselIndex = index);
        },
      ),
      items: imgList.map((url) {
        return Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(color: primaryColor),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.broken_image, size: 64),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildCompanyStats() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Nuestra Experiencia',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Contamos con años de experiencia brindando soluciones de transporte '
            'seguras, eficientes y confiables, comprometidos con la satisfacción '
            'de nuestros clientes.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabNavigation() {
    final tabs = [
      {'icon': Icons.info_outline, 'label': 'Empresa'},
      {'icon': Icons.workspace_premium, 'label': 'Servicios'},
      {'icon': Icons.schedule, 'label': 'Horarios'},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _selectedTab == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _changeTab(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [primaryColor, primaryColor.withOpacity(0.8)],
                        )
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      tabs[index]['icon'] as IconData,
                      color: isSelected ? Colors.white : Colors.grey[600],
                      size: 24,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tabs[index]['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Container(
        key: ValueKey(_selectedTab),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: _getTabContent(),
      ),
    );
  }

  Widget _getTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildEmpresaContent();
      case 1:
        return _buildServiciosContent();

      case 2:
        return _buildHorariosContent();
      default:
        return _buildEmpresaContent();
    }
  }

  Widget _buildEmpresaContent() {
    return Column(
      children: [
        _buildInfoCard(
          icon: Icons.rocket_launch_rounded,
          title: 'Nuestra Misión',
          description:
              'Proporcionar servicios de transporte eficiente, seguro y accesible en zonas rurales, utilizando tecnología innovadora para mejorar la experiencia del usuario y optimizar la gestión operativa.',
          color: primaryColor,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.visibility_rounded,
          title: 'Nuestra Visión',
          description:
              'Ser la cooperativa líder en digitalización del transporte rural, ofreciendo soluciones tecnológicas que permitan una movilidad sostenible, eficiente y de calidad para todas las comunidades.',
          color: secondaryColor,
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          icon: Icons.stars_rounded,
          title: 'Nuestros Valores',
          description:
              'Seguridad, Puntualidad, Innovación, Compromiso con el Cliente, Responsabilidad Social y Ambiental. Trabajamos cada día para mantener los más altos estándares de calidad en el servicio.',
          color: const Color(0xFF2196F3),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2D3142),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiciosContent() {
    final services = [
      {
        'icon': Icons.directions_bus_rounded,
        'title': 'Transporte Rural ',
        'features': [
          'Unidades modernas con aire acondicionado',
          'WiFi gratuito en todos los viajes',
          'Asientos ergonómicos y espaciosos',
          'Sistema de entretenimiento a bordo'
        ],
        'color': const Color(0xFF4CAF50),
      },
      {
        'icon': Icons.local_shipping_rounded,
        'title': 'Encomiendas Express',
        'features': [
          'Seguimiento en tiempo real',
          'Seguro incluido',
          'Entrega puerta a puerta',
          'Empaque profesional sin costo'
        ],
        'color': const Color(0xFF2196F3),
      },
      {
        'icon': Icons.phone_android_rounded,
        'title': 'Reservas Digitales',
        'features': [
          'App móvil intuitiva',
          'Boletos electrónicos',
          'Múltiples métodos de pago',
          'Confirmación instantánea'
        ],
        'color': const Color(0xFFFF9800),
      },
      {
        'icon': Icons.support_agent_rounded,
        'title': 'Soporte 24/7',
        'features': [
          'Atención inmediata por WhatsApp',
          'Call center multilingüe',
          'Chat en vivo',
          'Resolución rápida de problemas'
        ],
        'color': const Color(0xFF9C27B0),
      },
    ];

    return Column(
      children: services.map((service) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (service['color'] as Color).withOpacity(0.2),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (service['color'] as Color).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      service['icon'] as IconData,
                      color: service['color'] as Color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      service['title'] as String,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...(service['features'] as List<String>).map((feature) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: service['color'] as Color,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHorariosContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: Colors.white,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Horarios de Salida',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              _buildDiaHorario(
                'Lunes',
                '4:00 AM • 6:00 AM',
                '13:00 PM • 16:30 PM',
              ),
              _buildDiaHorario(
                'Martes',
                '4:00 AM • 7:00 AM',
                '14:00 PM • 16:00 PM',
              ),
              _buildDiaHorario(
                'Miércoles',
                '3:00 AM • 6:00 AM',
                '14:00 PM • 16:00 PM',
              ),
              _buildDiaHorario(
                'Jueves',
                '4:00 AM • 6:00 AM',
                '14:00 PM • 16:00 PM',
              ),
              _buildDiaHorario(
                'Viernes',
                '4:00 AM • 7:00 AM',
                '13:00 PM • 16:00 PM',
              ),
              _buildDiaHorario(
                'Sábado',
                '3:00 AM • 6:00 AM',
                '13:00 PM • 16:00 PM',
              ),
              _buildDiaHorario(
                'Domingo',
                '7:00 AM • 12:00 AM',
                '14:00 PM • 17:00 PM',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF25D366), width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.whatsapp,
                  color: Color(0xFF25D366),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Atención 24/7 por WhatsApp',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Estamos disponibles en cualquier momento',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDiaHorario(
    String dia,
    String manana,
    String tarde,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dia,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mañana: $manana',
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'Tarde: $tarde',
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildCTASection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accentColor, accentColor.withOpacity(0.9)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.phonelink_ring_rounded,
            color: Colors.white,
            size: 56,
          ),
          const SizedBox(height: 16),
          const Text(
            '¿Necesitas Información?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Nuestro equipo está listo para atenderte',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl('tel:${contactInfo['phone']}'),
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text(
                    'Llamar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl(
                    'https://wa.me/${contactInfo['whatsapp']!.replaceAll('+', '')}',
                  ),
                  icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
                  label: const Text(
                    'WhatsApp',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
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
        ],
      ),
    );
  }

  Widget _buildProfessionalFooter() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1d2e),
            const Color(0xFF0f1117),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryColor,
                                primaryColor.withOpacity(0.8)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Image(
                            image: AssetImage('assets/icon2.png'),
                            width: 32,
                            height: 32,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'TRANS DORAMALD',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Excelencia en transporte rural desde 2008. Comprometidos con la seguridad y comodidad de nuestros pasajeros.',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildFooterContact(
            Icons.location_on_rounded,
            'Dirección',
            contactInfo['address']!,
          ),
          const SizedBox(height: 12),
          _buildFooterContact(
            Icons.phone_rounded,
            'Teléfono',
            contactInfo['phone']!,
          ),
          const SizedBox(height: 12),
          _buildFooterContact(
            Icons.email_rounded,
            'Email',
            contactInfo['email']!,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '© ${DateTime.now().year} Trans Doramald',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    _buildSocialIconFooter(
                      FontAwesomeIcons.facebook,
                      () => _launchUrl('https://facebook.com'),
                    ),
                    const SizedBox(width: 12),
                    _buildSocialIconFooter(
                      FontAwesomeIcons.instagram,
                      () => _launchUrl('https://instagram.com'),
                    ),
                    const SizedBox(width: 12),
                    _buildSocialIconFooter(
                      FontAwesomeIcons.whatsapp,
                      () => _launchUrl(
                        'https://wa.me/${contactInfo['whatsapp']!.replaceAll('+', '')}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterContact(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 18),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialIconFooter(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: FaIcon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'whatsapp',
          backgroundColor: const Color(0xFF25D366),
          onPressed: () => _launchUrl(
            'https://wa.me/${contactInfo['whatsapp']!.replaceAll('+', '')}',
          ),
          child: const FaIcon(
            FontAwesomeIcons.whatsapp,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
