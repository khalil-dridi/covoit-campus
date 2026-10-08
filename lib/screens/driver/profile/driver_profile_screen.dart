import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../models/vehicle.dart';
import '../../../repositories/driver_profile_repository.dart';
import '../../../repositories/user_repository.dart';
import '../../../repositories/vehicle_repository.dart';
import '../../login/login_screen.dart';
import '../../../utils/logout_flow.dart';

class DriverProfileScreen extends StatefulWidget {
  final User user;

  const DriverProfileScreen({super.key, required this.user});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  static const Color primaryBlue = Color(0xFF123D68);
  static const Color secondaryBlue = Color(0xFF1E5AA8);
  static const Color green = Color(0xFF20B978);
  static const Color background = Color(0xFFF4FFFB);
  static const Color textGrey = Color(0xFF547080);
  static const Color lightBlue = Color(0xFFEAF3FC);
  static const Color lightGreen = Color(0xFFE8F8F1);
  static const Color lightOrange = Color(0xFFFFF1E6);

  final VehicleRepository _vehicleRepository = VehicleRepository();
  final DriverProfileRepository _profileRepository = DriverProfileRepository();

  late String _fullName;
  late String _phone;
  late String _university;
  Vehicle? _vehicle;
  DriverProfileStats? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fullName = widget.user.fullName;
    _phone = widget.user.phone ?? '';
    _university = widget.user.university ?? '';
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final userId = widget.user.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final values = await Future.wait<Object?>([
        _vehicleRepository.getVehicleForUser(userId),
        _profileRepository.getStats(userId),
      ]);
      if (!mounted) return;
      setState(() {
        _vehicle = values[0] as Vehicle?;
        _stats = values[1] as DriverProfileStats;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Impossible de charger toutes les données du profil.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 15),
              _buildIdentity(),
              const SizedBox(height: 20),
              _sectionHeading('Mon activité'),
              _buildStatistics(),
              const SizedBox(height: 20),
              _buildPersonalInformation(),
              const SizedBox(height: 15),
              _buildVehicleSection(),
              const SizedBox(height: 15),
              _buildDriverModeCard(),
              const SizedBox(height: 15),
              _buildAccountActions(),
              const SizedBox(height: 14),
              _buildSecurityFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) => Row(
    children: [
      _headerButton(
        icon: Icons.arrow_back_rounded,
        onTap: () => Navigator.of(context).maybePop(),
      ),
      const Spacer(),
      const Text(
        'Mon profil',
        style: TextStyle(
          color: primaryBlue,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
      const Spacer(),
      _headerButton(
        icon: Icons.settings_outlined,
        onTap: () => _showInfoDialog(
          title: 'Paramètres',
          message: 'Les paramètres généraux seront disponibles ici.',
          icon: Icons.settings_outlined,
        ),
      ),
    ],
  );

  Widget _headerButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, color: primaryBlue, size: 22),
        ),
      ),
    );
  }

  Widget _buildIdentity() {
    final imagePath = widget.user.profileImage?.trim();
    final imageUri = imagePath == null ? null : Uri.tryParse(imagePath);
    final isNetworkImage =
        imageUri != null &&
        (imageUri.scheme == 'http' || imageUri.scheme == 'https');
    final isAssetImage = imagePath?.startsWith('assets/') == true;
    Widget avatar = _avatarFallback();
    if (imagePath != null && imagePath.isNotEmpty && isNetworkImage) {
      avatar = Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _avatarFallback(),
      );
    } else if (imagePath != null && imagePath.isNotEmpty && isAssetImage) {
      avatar = Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _avatarFallback(),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      decoration: _cardDecoration(radius: 22),
      child: Center(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),
                  child: ClipOval(child: avatar),
                ),
                Positioned(
                  right: -1,
                  bottom: 1,
                  child: Material(
                    color: secondaryBlue,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _showInfoDialog(
                        title: 'Photo de profil',
                        message:
                            'Vous pourrez bientôt choisir une photo depuis '
                            'la galerie ou prendre une nouvelle photo.',
                        icon: Icons.camera_alt_outlined,
                      ),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: secondaryBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: background, width: 4),
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _fullName,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: primaryBlue,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            _verificationBadge(),
            const SizedBox(height: 6),
            Text(
              widget.user.email,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textGrey.withValues(alpha: 0.75),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      title,
      style: const TextStyle(
        color: primaryBlue,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _avatarFallback() => Container(
    color: lightBlue,
    alignment: Alignment.center,
    child: const Icon(Icons.person_rounded, color: secondaryBlue, size: 58),
  );

  Widget _verificationBadge() {
    final verified = widget.user.isVerified;
    final color = verified ? green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? Icons.verified_rounded : Icons.error_outline_rounded,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 6),
          Text(
            verified ? 'Conducteur vérifié' : 'Email non vérifié',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics() {
    final stats = _stats;
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.star_rounded,
            color: const Color(0xFFE6AC35),
            value: stats?.rating?.toStringAsFixed(1) ?? '—',
            title: 'Note',
            subtitle: stats == null || stats.ratingCount == 0
                ? 'Aucune donnée disponible'
                : '(${stats.ratingCount} avis)',
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _statCard(
            icon: Icons.route_rounded,
            color: secondaryBlue,
            value: stats?.completedTrips.toString() ?? '—',
            title: 'Trajets',
            subtitle: 'trajets réalisés',
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _statCard(
            icon: Icons.eco_rounded,
            color: green,
            value: '—',
            title: 'CO₂ évité',
            subtitle: 'Aucune donnée disponible',
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String value,
    required String title,
    required String subtitle,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: _cardDecoration(radius: 17),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: primaryBlue,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: textGrey,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textGrey.withValues(alpha: 0.62),
              fontSize: 8.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return _sectionCard(
      title: 'Informations personnelles',
      icon: Icons.person_rounded,
      action: 'Modifier',
      onAction: () => _editPersonalInformation(),
      children: [
        _informationRow(
          icon: Icons.person_outline_rounded,
          label: 'Nom complet',
          value: _fullName,
          onTap: _editPersonalInformation,
        ),
        _divider(),
        _informationRow(
          icon: Icons.email_outlined,
          label: 'Email',
          value: widget.user.email,
          trailing: Icon(
            widget.user.isVerified
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            color: widget.user.isVerified ? green : Colors.red,
            size: 18,
          ),
        ),
        _divider(),
        _informationRow(
          icon: Icons.phone_outlined,
          label: 'Téléphone',
          value: _phone.trim().isEmpty ? 'Non renseigné' : _phone,
          onTap: _editPersonalInformation,
        ),
        _divider(),
        _informationRow(
          icon: Icons.school_outlined,
          label: 'Université',
          value: _university.trim().isEmpty ? 'Non renseignée' : _university,
          onTap: _editPersonalInformation,
        ),
      ],
    );
  }

  Future<void> _editPersonalInformation() async {
    final result = await showDialog<_EditedUserInfo>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PersonalInfoDialog(
        fullName: _fullName,
        phone: _phone,
        university: _university,
      ),
    );
    if (!mounted || result == null) return;
    final userId = widget.user.id;
    if (userId == null) {
      _showMessage('Impossible d’identifier votre compte.');
      return;
    }

    try {
      final rows = await UserRepository().updateUserProfile(
        userId: userId,
        fullName: result.fullName,
        phone: result.phone,
        university: result.university,
      );
      if (!mounted) return;
      if (rows == 0) throw StateError('No user row updated');
      setState(() {
        _fullName = result.fullName;
        _phone = result.phone;
        _university = result.university;
      });
      _showMessage('Informations enregistrées.');
    } catch (_) {
      if (mounted) _showMessage('Impossible d’enregistrer vos informations.');
    }
  }

  Widget _buildVehicleSection() {
    final vehicle = _vehicle;
    return _sectionCard(
      title: 'Mon véhicule',
      icon: Icons.directions_car_rounded,
      action: vehicle == null ? 'Ajouter' : 'Modifier',
      onAction: () => _editVehicle(vehicle),
      children: [
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(22),
            child: Center(child: CircularProgressIndicator(color: green)),
          )
        else if (vehicle == null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
            child: Column(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: lightBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car_outlined,
                    color: secondaryBlue,
                    size: 29,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pas encore de véhicule',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Ajoutez votre véhicule pour préparer vos trajets.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: textGrey.withValues(alpha: 0.75),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 13),
                _primaryButton(
                  icon: Icons.add_rounded,
                  label: 'Ajouter un véhicule',
                  onPressed: () => _editVehicle(null),
                ),
              ],
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 11),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.directions_car_filled_rounded,
                    color: secondaryBlue,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${vehicle.brand} ${vehicle.model}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${vehicle.seats} places',
                        style: const TextStyle(color: textGrey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _informationRow(
            icon: Icons.directions_car_outlined,
            label: 'Marque',
            value: vehicle.brand,
          ),
          _divider(),
          _informationRow(
            icon: Icons.car_repair_outlined,
            label: 'Modèle',
            value: vehicle.model,
          ),
          _divider(),
          _informationRow(
            icon: Icons.palette_outlined,
            label: 'Couleur',
            value: _optionalValue(vehicle.color, 'Non renseignée'),
          ),
          _divider(),
          _informationRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Immatriculation',
            value: vehicle.licensePlate,
          ),
          _divider(),
          _informationRow(
            icon: Icons.event_seat_outlined,
            label: 'Nombre de places',
            value: '${vehicle.seats} places',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
            child: OutlinedButton.icon(
              onPressed: () => _confirmDeleteVehicle(vehicle),
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('Supprimer le véhicule'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFE53935),
                side: const BorderSide(color: Color(0xFFF1CDCD)),
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _editVehicle(Vehicle? vehicle) async {
    final result = await showDialog<_VehicleFormResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VehicleDialog(vehicle: vehicle),
    );
    if (!mounted || result == null) return;
    final userId = widget.user.id;
    if (userId == null) {
      _showMessage('Impossible d’identifier votre compte.');
      return;
    }

    late final Vehicle savedVehicle;
    try {
      if (vehicle == null) {
        final vehicleId = await _vehicleRepository.createVehicle(
          Vehicle(
            userId: userId,
            brand: result.brand,
            model: result.model,
            color: result.color,
            licensePlate: result.licensePlate,
            seats: result.seats,
          ),
        );
        if (vehicleId <= 0) {
          throw StateError('SQLite did not return a valid vehicle ID.');
        }
        savedVehicle = Vehicle(
          id: vehicleId,
          userId: userId,
          brand: result.brand,
          model: result.model,
          color: result.color,
          licensePlate: result.licensePlate,
          seats: result.seats,
          createdAt: DateTime.now().toIso8601String(),
        );
      } else {
        final updatedRows = await _vehicleRepository.updateVehicle(
          Vehicle(
            id: vehicle.id,
            userId: userId,
            brand: result.brand,
            model: result.model,
            color: result.color,
            licensePlate: result.licensePlate,
            seats: result.seats,
          ),
        );
        if (updatedRows == 0) {
          throw StateError('No vehicle row was updated.');
        }
        savedVehicle = Vehicle(
          id: vehicle.id,
          userId: userId,
          brand: result.brand,
          model: result.model,
          color: result.color,
          licensePlate: result.licensePlate,
          seats: result.seats,
          createdAt: vehicle.createdAt,
        );
      }
    } catch (error, stackTrace) {
      debugPrint('VEHICLE PROFILE SAVE ERROR: $error');
      debugPrint('$stackTrace');
      if (mounted) _showMessage('Impossible d’enregistrer le véhicule.');
      return;
    }

    if (!mounted) return;
    setState(() => _vehicle = savedVehicle);
    try {
      await _refreshVehicle();
    } catch (error, stackTrace) {
      debugPrint('VEHICLE PROFILE REFRESH ERROR: $error');
      debugPrint('$stackTrace');
    }
    if (mounted) _showMessage('Véhicule enregistré.');
  }

  Future<void> _confirmDeleteVehicle(Vehicle vehicle) async {
    final confirmed = await _showConfirmationDialog(
      title: 'Supprimer ce véhicule ?',
      message: 'Cette action supprimera les informations de votre véhicule.',
      icon: Icons.delete_outline_rounded,
      iconColor: const Color(0xFFE53935),
      cancelText: 'Annuler',
      confirmText: 'Supprimer',
    );
    if (!mounted || confirmed != true || vehicle.id == null) return;

    try {
      final rows = await _vehicleRepository.deleteVehicle(
        vehicle.id!,
        widget.user.id ?? -1,
      );
      if (!mounted) return;
      if (rows == 0) throw StateError('No vehicle row deleted');
      setState(() => _vehicle = null);
      _showMessage('Véhicule supprimé.');
    } catch (_) {
      if (mounted) {
        _showMessage(
          'Impossible de supprimer ce véhicule. Vérifiez qu’aucun trajet '
          'n’y est associé.',
        );
      }
    }
  }

  Future<void> _refreshVehicle() async {
    final userId = widget.user.id;
    if (userId == null) return;
    final vehicle = await _vehicleRepository.getVehicleForUser(userId);
    if (!mounted) return;
    setState(() => _vehicle = vehicle);
  }

  Widget _buildDriverModeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: lightGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: green.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.directions_car_rounded, color: green),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode conducteur actif',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Vous pouvez publier et gérer vos trajets.',
                      style: TextStyle(color: textGrey, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          _primaryButton(
            icon: Icons.swap_horiz_rounded,
            label: 'Revenir en mode passager',
            onPressed: _requestPassengerMode,
          ),
        ],
      ),
    );
  }

  Future<void> _requestPassengerMode() async {
    final confirmed = await _showConfirmationDialog(
      title: 'Revenir en mode passager ?',
      message:
          'Votre rôle va être modifié. Vous serez déconnecté pour appliquer '
          'le nouvel espace passager.',
      icon: Icons.person_rounded,
      iconColor: secondaryBlue,
      cancelText: 'Annuler',
      confirmText: 'Continuer',
    );
    if (!mounted || confirmed != true) return;
    final userId = widget.user.id;
    if (userId == null) {
      _showMessage('Impossible d’identifier votre compte.');
      return;
    }

    try {
      final rows = await UserRepository().updateUserRole(userId, 'passenger');
      if (!mounted) return;
      if (rows == 0) throw StateError('No user row updated');
      _showForcedLogoutDialog();
    } catch (_) {
      if (mounted) _showMessage('Impossible de modifier votre rôle.');
    }
  }

  void _showForcedLogoutDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _dialogSurface(
            icon: Icons.logout_rounded,
            iconColor: secondaryBlue,
            title: 'Déconnexion requise',
            message:
                'Votre rôle a été modifié avec succès. Pour appliquer votre '
                'nouvel espace utilisateur, vous devez vous déconnecter puis '
                'vous reconnecter.',
            actions: [
              _primaryButton(
                icon: Icons.logout_rounded,
                label: 'Se déconnecter',
                onPressed: () {
                  final navigator = Navigator.of(dialogContext);
                  navigator.pop();
                  navigator.pushAndRemoveUntil<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountActions() {
    return _sectionCard(
      title: 'Déconnexion',
      icon: Icons.logout_rounded,
      children: [
        _accountAction(
          icon: Icons.logout_rounded,
          title: 'Se déconnecter',
          subtitle: 'Quitter votre session actuelle.',
          color: const Color(0xFFE96A2C),
          tileColor: lightOrange,
          onTap: _confirmLogout,
        ),
      ],
    );
  }

  Future<void> _confirmLogout() async {
    await LogoutFlow.confirmAndLogout(context);
  }

  Widget _accountAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color tileColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: tileColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textGrey.withValues(alpha: 0.75),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: textGrey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityFooter() => Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.verified_user_outlined,
          color: textGrey.withValues(alpha: 0.5),
          size: 15,
        ),
        const SizedBox(width: 6),
        Text(
          'Vos données restent protégées',
          style: TextStyle(
            color: textGrey.withValues(alpha: 0.55),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _sectionCard({
    required String title,
    required IconData icon,
    String? action,
    VoidCallback? onAction,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(radius: 22),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 11),
            child: Row(
              children: [
                Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    color: lightBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: secondaryBlue, size: 21),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (action != null)
                  TextButton.icon(
                    onPressed: onAction,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: Text(action),
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      textStyle: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5ECE9)),
          ...children,
        ],
      ),
    );
  }

  Widget _informationRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: lightBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: secondaryBlue, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(
                color: textGrey.withValues(alpha: 0.88),
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: primaryBlue,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 6), trailing],
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: textGrey,
                    size: 19,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: row),
    );
  }

  Widget _divider() => const Padding(
    padding: EdgeInsets.only(left: 62),
    child: Divider(height: 1, color: Color(0xFFE5ECE9)),
  );

  Widget _primaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration({required double radius}) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFE1ECE8)),
    boxShadow: [
      BoxShadow(
        color: primaryBlue.withValues(alpha: 0.04),
        blurRadius: 16,
        offset: const Offset(0, 6),
      ),
    ],
  );

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required String cancelText,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: _dialogSurface(
          icon: icon,
          iconColor: iconColor,
          title: title,
          message: message,
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textGrey,
                      side: const BorderSide(color: Color(0xFFD8E6E1)),
                      minimumSize: const Size.fromHeight(47),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(cancelText),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: iconColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(47),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(confirmText),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog({
    required String title,
    required String message,
    required IconData icon,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: _dialogSurface(
          icon: icon,
          iconColor: secondaryBlue,
          title: title,
          message: message,
          actions: [
            _primaryButton(
              icon: Icons.check_rounded,
              label: 'Compris',
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogSurface({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required List<Widget> actions,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(27),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 30),
          ),
          const SizedBox(height: 17),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: primaryBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textGrey.withValues(alpha: 0.84),
              fontSize: 12.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          ...actions,
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
    );
  }

  String _optionalValue(String? value, String fallback) =>
      value?.trim().isNotEmpty == true ? value!.trim() : fallback;
}

class _EditedUserInfo {
  final String fullName;
  final String phone;
  final String university;

  const _EditedUserInfo(this.fullName, this.phone, this.university);
}

class _PersonalInfoDialog extends StatefulWidget {
  final String fullName;
  final String phone;
  final String university;

  const _PersonalInfoDialog({
    required this.fullName,
    required this.phone,
    required this.university,
  });

  @override
  State<_PersonalInfoDialog> createState() => _PersonalInfoDialogState();
}

class _PersonalInfoDialogState extends State<_PersonalInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _universityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.fullName);
    _phoneController = TextEditingController(text: widget.phone);
    _universityController = TextEditingController(text: widget.university);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _universityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _ProfileEditDialogFrame(
        title: 'Modifier mes informations',
        icon: Icons.person_outline_rounded,
        formKey: _formKey,
        fields: [
          _field(
            'Nom complet',
            _nameController,
            validator: (value) => value == null || value.trim().isEmpty
                ? 'Le nom complet est obligatoire.'
                : null,
          ),
          _field(
            'Téléphone',
            _phoneController,
            keyboardType: TextInputType.phone,
          ),
          _field('Université', _universityController),
        ],
        onCancel: () => Navigator.of(context).pop(),
        onSave: () {
          if (!_formKey.currentState!.validate()) return;
          Navigator.of(context).pop(
            _EditedUserInfo(
              _nameController.text.trim(),
              _phoneController.text.trim(),
              _universityController.text.trim(),
            ),
          );
        },
      ),
    );
  }
}

class _VehicleFormResult {
  final String brand;
  final String model;
  final String? color;
  final String licensePlate;
  final int seats;

  const _VehicleFormResult({
    required this.brand,
    required this.model,
    required this.color,
    required this.licensePlate,
    required this.seats,
  });
}

class _VehicleDialog extends StatefulWidget {
  final Vehicle? vehicle;

  const _VehicleDialog({this.vehicle});

  @override
  State<_VehicleDialog> createState() => _VehicleDialogState();
}

class _VehicleDialogState extends State<_VehicleDialog> {
  static const _colors = [
    'Blanc',
    'Noir',
    'Gris',
    'Bleu',
    'Rouge',
    'Vert',
    'Autre',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _brandController;
  late final TextEditingController _modelController;
  late final TextEditingController _plateController;
  late int _seats;
  String? _color;

  @override
  void initState() {
    super.initState();
    _brandController = TextEditingController(text: widget.vehicle?.brand ?? '');
    _modelController = TextEditingController(text: widget.vehicle?.model ?? '');
    _plateController = TextEditingController(
      text: widget.vehicle?.licensePlate ?? '',
    );
    _seats = widget.vehicle?.seats ?? 2;
    final initialColor = widget.vehicle?.color;
    _color = _colors.contains(initialColor) ? initialColor : null;
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _ProfileEditDialogFrame(
        title: widget.vehicle == null
            ? 'Ajouter un véhicule'
            : 'Modifier le véhicule',
        icon: Icons.directions_car_rounded,
        formKey: _formKey,
        fields: [
          _field('Marque', _brandController, validator: _required),
          _field('Modèle', _modelController, validator: _required),
          DropdownButtonFormField<String>(
            initialValue: _color,
            decoration: _inputDecoration('Couleur', Icons.palette_outlined),
            items: _colors
                .map(
                  (color) => DropdownMenuItem(value: color, child: Text(color)),
                )
                .toList(),
            onChanged: (value) => setState(() => _color = value),
          ),
          _field(
            'Immatriculation',
            _plateController,
            textCapitalization: TextCapitalization.characters,
            validator: _required,
          ),
          _seatPicker(),
        ],
        onCancel: () => Navigator.of(context).pop(),
        onSave: () {
          if (!_formKey.currentState!.validate() || _seats < 2 || _seats > 8) {
            return;
          }
          Navigator.of(context).pop(
            _VehicleFormResult(
              brand: _brandController.text.trim(),
              model: _modelController.text.trim(),
              color: _color,
              licensePlate: _plateController.text.trim().toUpperCase(),
              seats: _seats,
            ),
          );
        },
      ),
    );
  }

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? 'Ce champ est obligatoire.'
      : null;

  Widget _seatPicker() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Nombre de places',
            style: TextStyle(
              color: _DriverProfileScreenState.textGrey,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Retirer une place',
          onPressed: _seats > 2 ? () => setState(() => _seats--) : null,
          icon: const Icon(Icons.remove_circle_outline_rounded),
        ),
        Text(
          '$_seats',
          style: const TextStyle(
            color: _DriverProfileScreenState.primaryBlue,
            fontWeight: FontWeight.w800,
          ),
        ),
        IconButton(
          tooltip: 'Ajouter une place',
          onPressed: _seats < 8 ? () => setState(() => _seats++) : null,
          icon: const Icon(Icons.add_circle_outline_rounded),
        ),
      ],
    );
  }
}

class _ProfileEditDialogFrame extends StatelessWidget {
  final String title;
  final IconData icon;
  final GlobalKey<FormState> formKey;
  final List<Widget> fields;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _ProfileEditDialogFrame({
    required this.title,
    required this.icon,
    required this.formKey,
    required this.fields,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: _DriverProfileScreenState.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: _DriverProfileScreenState.secondaryBlue,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _DriverProfileScreenState.primaryBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 17),
              ...fields.map(
                (field) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: field,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _DriverProfileScreenState.textGrey,
                        minimumSize: const Size.fromHeight(46),
                        side: const BorderSide(color: Color(0xFFD8E6E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _DriverProfileScreenState.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _field(
  String label,
  TextEditingController controller, {
  TextInputType? keyboardType,
  TextCapitalization textCapitalization = TextCapitalization.words,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    textCapitalization: textCapitalization,
    validator: validator,
    style: const TextStyle(
      color: _DriverProfileScreenState.primaryBlue,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    decoration: _inputDecoration(label, Icons.edit_outlined),
  );
}

InputDecoration _inputDecoration(String label, IconData icon) =>
    InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon,
        color: _DriverProfileScreenState.secondaryBlue,
        size: 19,
      ),
      filled: true,
      fillColor: const Color(0xFFF7FAF9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDCE7E3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDCE7E3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: _DriverProfileScreenState.secondaryBlue,
          width: 1.3,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.3),
      ),
    );
