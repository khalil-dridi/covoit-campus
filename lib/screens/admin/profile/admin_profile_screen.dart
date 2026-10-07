import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/user.dart';
import '../../../repositories/user_repository.dart';
import '../../../utils/password_hasher.dart';
import '../../login/login_screen.dart';

class AdminProfileScreen extends StatefulWidget {
  final User admin;
  final ValueChanged<User> onUserUpdated;

  const AdminProfileScreen({
    super.key,
    required this.admin,
    required this.onUserUpdated,
  });

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  static const _navy = Color(0xFF123D68);
  static const _blue = Color(0xFF1E5AA8);
  static const _green = Color(0xFF18A974);
  static const _muted = Color(0xFF71879A);
  static const _background = Color(0xFFF6F9FC);
  static const _border = Color(0xFFE6EDF3);

  final UserRepository _repository = UserRepository();
  User? _admin;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final id = widget.admin.id;
      final user = id == null ? null : await _repository.getUserById(id);
      if (!mounted) return;
      if (user == null || user.role != 'admin') {
        setState(() {
          _admin = null;
          _loading = false;
          _error = 'Le compte administrateur est introuvable.';
        });
        return;
      }
      setState(() {
        _admin = user;
        _loading = false;
      });
      widget.onUserUpdated(user);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger le profil. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = _admin;
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _blue))
            : _error != null
            ? _errorView()
            : RefreshIndicator(
                color: _blue,
                onRefresh: _loadProfile,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 30),
                  children: [
                    const Text(
                      'Mon profil',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Informations et sécurité du compte administrateur',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                    const SizedBox(height: 19),
                    if (admin != null) ...[
                      _identityCard(admin),
                      const SizedBox(height: 15),
                      _sectionCard(
                        title: 'Informations du compte',
                        icon: Icons.badge_outlined,
                        action: TextButton.icon(
                          onPressed: () => _editProfile(admin),
                          icon: const Icon(Icons.edit_outlined, size: 17),
                          label: const Text('Modifier'),
                          style: TextButton.styleFrom(
                            foregroundColor: _blue,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        children: [
                          _infoRow(
                            Icons.person_outline_rounded,
                            'Nom complet',
                            admin.fullName,
                          ),
                          _divider(),
                          _infoRow(
                            Icons.alternate_email_rounded,
                            'Adresse email',
                            admin.email,
                            trailing: _readOnlyTag(),
                          ),
                          if (_has(admin.phone)) ...[
                            _divider(),
                            _infoRow(
                              Icons.phone_outlined,
                              'Téléphone',
                              admin.phone!.trim(),
                            ),
                          ],
                          if (_has(admin.university)) ...[
                            _divider(),
                            _infoRow(
                              Icons.school_outlined,
                              'Université',
                              admin.university!.trim(),
                            ),
                          ],
                          _divider(),
                          _infoRow(
                            Icons.event_outlined,
                            'Membre depuis',
                            _date(admin.createdAt),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _sectionCard(
                        title: 'Sécurité',
                        icon: Icons.shield_outlined,
                        children: [
                          _infoRow(
                            admin.isVerified
                                ? Icons.verified_user_outlined
                                : Icons.mark_email_unread_outlined,
                            'Vérification email',
                            admin.isVerified
                                ? 'Adresse vérifiée'
                                : 'Adresse non vérifiée',
                            valueColor: admin.isVerified
                                ? _green
                                : const Color(0xFFD89228),
                          ),
                          _divider(),
                          _infoRow(
                            Icons.lock_outline_rounded,
                            'Mot de passe',
                            'Modifié via une vérification sécurisée',
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 3, 14, 12),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _changePassword,
                                icon: const Icon(
                                  Icons.password_rounded,
                                  size: 18,
                                ),
                                label: const Text('Changer le mot de passe'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _blue,
                                  side: const BorderSide(color: _border),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(13),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _sectionCard(
                        title: 'Accès',
                        icon: Icons.admin_panel_settings_outlined,
                        children: [
                          _infoRow(
                            Icons.shield_rounded,
                            'Rôle',
                            'Administrateur',
                            valueColor: _blue,
                          ),
                          _divider(),
                          _infoRow(
                            Icons.circle,
                            'Compte',
                            admin.isActive ? 'Actif' : 'Inactif',
                            valueColor: admin.isActive ? _green : Colors.red,
                          ),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(14, 2, 14, 13),
                            child: Text(
                              'Le rôle et l’état de ce compte sont protégés depuis le profil.',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 11,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      _sectionCard(
                        title: 'Session',
                        icon: Icons.devices_outlined,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
                            child: Text(
                              'La connexion actuelle est conservée en mémoire jusqu’à la déconnexion.',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                          _divider(),
                          _actionRow(
                            icon: Icons.logout_rounded,
                            title: 'Se déconnecter',
                            subtitle: 'Fermer cette session et revenir à la connexion.',
                            onTap: _confirmLogout,
                            color: const Color(0xFFD87532),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _identityCard(User admin) {
    final name = admin.fullName.trim();
    final image = admin.profileImage?.trim();
    final uri = image == null ? null : Uri.tryParse(image);
    final networkImage =
        uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    final assetImage = image?.startsWith('assets/') == true;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: .04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEAF3FC),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: _blue.withValues(alpha: .12), blurRadius: 13),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: networkImage
                ? Image.network(
                    image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _initialsAvatar(initials),
                  )
                : assetImage
                ? Image.asset(
                    image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _initialsAvatar(initials),
                  )
                : _initialsAvatar(initials),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            admin.email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            alignment: WrapAlignment.center,
            children: [
              _badge(
                'Administrateur',
                _blue,
                const Color(0xFFEAF3FC),
                Icons.admin_panel_settings_rounded,
              ),
              _badge(
                admin.isActive ? 'Compte actif' : 'Compte inactif',
                admin.isActive ? _green : Colors.red,
                admin.isActive
                    ? const Color(0xFFEAF8F1)
                    : const Color(0xFFFFEEEE),
                Icons.circle,
              ),
              _badge(
                admin.isVerified ? 'Email vérifié' : 'Email non vérifié',
                admin.isVerified ? _green : const Color(0xFFD89228),
                admin.isVerified
                    ? const Color(0xFFEAF8F1)
                    : const Color(0xFFFFF5E8),
                admin.isVerified
                    ? Icons.verified_rounded
                    : Icons.mark_email_unread_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _initialsAvatar(String initials) => Center(
    child: Text(
      initials.isEmpty ? 'A' : initials,
      style: const TextStyle(
        color: _blue,
        fontSize: 26,
        fontWeight: FontWeight.w800,
      ),
    ),
  );

  Widget _badge(String label, Color color, Color background, IconData icon) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );

  Widget _sectionCard({
    required String title,
    required IconData icon,
    Widget? action,
    required List<Widget> children,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: _border),
      boxShadow: [
        BoxShadow(
          color: _navy.withValues(alpha: .03),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 8, 11),
          child: Row(
            children: [
              Container(
                width: 33,
                height: 33,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _blue, size: 18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              ?action,
            ],
          ),
        ),
        ...children,
      ],
    ),
  );

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color valueColor = _navy,
    Widget? trailing,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    child: Row(
      children: [
        Icon(icon, size: 18, color: _muted),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );

  Widget _readOnlyTag() => const Text(
    'Lecture seule',
    style: TextStyle(color: _muted, fontSize: 9, fontWeight: FontWeight.w700),
  );
  Widget _divider() => const Padding(
    padding: EdgeInsets.only(left: 42),
    child: Divider(height: 1, color: _border),
  );
  Widget _actionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
    leading: Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 20),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: _navy,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(color: _muted, fontSize: 11),
    ),
    trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
  );

  Widget _errorView() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_off_outlined, size: 42, color: _muted),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Une erreur est survenue.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loadProfile,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    ),
  );

  Future<void> _editProfile(User admin) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: admin.fullName);
    final phone = TextEditingController(text: admin.phone ?? '');
    final university = TextEditingController(text: admin.university ?? '');
    bool saving = false;
    String? saveError;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Modifier le profil',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _editField(
                      name,
                      'Nom complet',
                      Icons.person_outline_rounded,
                      validator: (v) => (v?.trim().length ?? 0) < 3
                          ? 'Saisissez au moins 3 caractères.'
                          : null,
                    ),
                    const SizedBox(height: 11),
                    _editField(
                      TextEditingController(text: admin.email),
                      'Email (lecture seule)',
                      Icons.email_outlined,
                      enabled: false,
                    ),
                    const SizedBox(height: 11),
                    _editField(
                      phone,
                      'Téléphone',
                      Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 11),
                    _editField(university, 'Université', Icons.school_outlined),
                    if (saveError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        saveError!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() {
                        saving = true;
                        saveError = null;
                      });
                      try {
                        final changed = await _repository.updateAdminProfile(
                          userId: admin.id!,
                          fullName: name.text,
                          phone: phone.text,
                          university: university.text,
                        );
                        if (changed != 1) {
                          throw StateError(
                            'Le profil n’a pas pu être mis à jour.',
                          );
                        }
                        final updated = await _repository.getUserById(
                          admin.id!,
                        );
                        if (updated == null || updated.role != 'admin') {
                          throw StateError(
                            'Le compte administrateur est introuvable.',
                          );
                        }
                        if (!mounted || !dialogContext.mounted) return;
                        setState(() => _admin = updated);
                        widget.onUserUpdated(updated);
                        Navigator.pop(dialogContext);
                        _message('Profil mis à jour.');
                      } catch (_) {
                        setDialogState(() {
                          saving = false;
                          saveError = 'Impossible d’enregistrer les modifications. Réessayez.';
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    phone.dispose();
    university.dispose();
  }

  Widget _editField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    bool enabled = true,
    TextInputType? keyboardType,
  }) => TextFormField(
    controller: controller,
    enabled: enabled,
    validator: validator,
    keyboardType: keyboardType,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 19),
      filled: true,
      fillColor: enabled ? Colors.white : const Color(0xFFF2F5F8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
    ),
  );

  Future<void> _changePassword() async {
    final formKey = GlobalKey<FormState>();
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();
    bool saving = false,
        showCurrent = false,
        showNext = false,
        showConfirm = false;
    String? saveError;
    final dialogRoute = DialogRoute<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text(
            'Changer le mot de passe',
            style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _passwordField(
                    current,
                    'Mot de passe actuel',
                    showCurrent,
                    (v) => setDialogState(() => showCurrent = v),
                  ),
                  const SizedBox(height: 11),
                  _passwordField(
                    next,
                    'Nouveau mot de passe',
                    showNext,
                    (v) => setDialogState(() => showNext = v),
                    validator: (v) => _validPassword(v ?? '') ? null : '8 caractères minimum, avec une lettre et un chiffre.',
                  ),
                  const SizedBox(height: 11),
                  _passwordField(
                    confirm,
                    'Confirmer le nouveau mot de passe',
                    showConfirm,
                    (v) => setDialogState(() => showConfirm = v),
                    validator: (v) => v == next.text
                        ? null
                        : 'Les mots de passe ne correspondent pas.',
                  ),
                  if (saveError != null) ...[
                    const SizedBox(height: 9),
                    Text(
                      saveError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      final id = _admin?.id;
                      if (id == null) {
                        setDialogState(
                          () =>
                              saveError = 'Compte administrateur indisponible.',
                        );
                        return;
                      }
                      setDialogState(() {
                        saving = true;
                        saveError = null;
                      });
                      try {
                        final changed = await _repository.changeAdminPassword(
                          userId: id,
                          currentPasswordHash: hashPassword(current.text),
                          newPasswordHash: hashPassword(next.text),
                        );
                        if (!dialogContext.mounted) return;
                        if (!changed) {
                          setDialogState(() {
                            saving = false;
                            saveError = 'Mot de passe actuel incorrect ou compte indisponible.';
                          });
                          return;
                        }
                        if (!dialogContext.mounted) return;
                        Navigator.of(dialogContext).pop(true);
                      } catch (_) {
                        if (!dialogContext.mounted) return;
                        setDialogState(() {
                          saving = false;
                          saveError = 'Impossible de modifier le mot de passe. Réessayez.';
                        });
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 17,
                      height: 17,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Mettre à jour'),
            ),
          ],
        ),
      ),
    );
    final navigator = Navigator.of(context);
    final changed = await navigator.push<bool>(dialogRoute);
    await dialogRoute.completed;
    current.dispose();
    next.dispose();
    confirm.dispose();
    if (!mounted || changed != true) return;

    final id = _admin?.id;
    if (id == null) return;
    try {
      final updatedAdmin = await _repository.getUserById(id);
      if (!mounted) return;
      if (updatedAdmin != null && updatedAdmin.role == 'admin') {
        setState(() => _admin = updatedAdmin);
        widget.onUserUpdated(updatedAdmin);
      }
      _message('Mot de passe modifié avec succès.');
    } catch (_) {
      if (mounted) {
        _message(
          'Mot de passe modifié, mais le profil n’a pas pu être actualisé.',
        );
      }
    }
  }

  Widget _passwordField(
    TextEditingController controller,
    String label,
    bool visible,
    ValueChanged<bool> toggle, {
    String? Function(String?)? validator,
  }) => TextFormField(
    controller: controller,
    obscureText: !visible,
    validator:
        validator ??
        (v) => (v?.isNotEmpty ?? false) ? null : 'Ce champ est obligatoire.',
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 19),
      suffixIcon: IconButton(
        onPressed: () => toggle(!visible),
        icon: Icon(
          visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        ),
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
    ),
  );

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: Color(0xFFD87532)),
        title: const Text(
          'Se déconnecter ?',
          style: TextStyle(color: _navy, fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Votre session sera fermée et vous reviendrez à l’écran de connexion.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Rester connecté'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD87532),
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _message(String value) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
  bool _has(String? value) => value?.trim().isNotEmpty == true;
  bool _validPassword(String value) =>
      value.length >= 8 &&
      RegExp(r'[A-Za-z]').hasMatch(value) &&
      RegExp(r'[0-9]').hasMatch(value);
  String _date(String value) {
    final date = DateTime.tryParse(value);
    return date == null
        ? value
        : DateFormat('dd MMMM yyyy', 'fr_FR').format(date);
  }
}
