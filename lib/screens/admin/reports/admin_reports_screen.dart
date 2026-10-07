import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/report.dart';
import '../../../models/user.dart';
import '../../../repositories/report_repository.dart';

class AdminReportsScreen extends StatefulWidget {
  final User admin;

  const AdminReportsScreen({super.key, required this.admin});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  static const _navy = Color(0xFF123D68);
  static const _blue = Color(0xFF1E5AA8);
  static const _green = Color(0xFF18A974);
  static const _orange = Color(0xFFD89228);
  static const _muted = Color(0xFF71879A);
  static const _background = Color(0xFFF6F9FC);
  static const _border = Color(0xFFE6EDF3);

  final _repository = ReportRepository();
  final _searchController = TextEditingController();
  List<Report> _reports = const [];
  ReportCounts? _counts;
  bool _loading = true;
  String? _error;
  String _statusFilter = 'all';
  String _relatedFilter = 'all';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query != _query && mounted) setState(() => _query = query);
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>([
        _repository.getAllReports(),
        _repository.getReportCounts(),
      ]);
      if (!mounted) return;
      setState(() {
        _reports = values[0] as List<Report>;
        _counts = values[1] as ReportCounts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les signalements.';
      });
    }
  }

  List<Report> get _visibleReports => _reports
      .where((report) {
        if (_statusFilter != 'all' && report.status != _statusFilter) {
          return false;
        }
        if (_relatedFilter == 'user' && report.reportedUserId == null) {
          return false;
        }
        if (_relatedFilter == 'trip' && report.tripId == null) {
          return false;
        }
        if (_query.isEmpty) return true;
        final haystack = [
          report.reporterName,
          report.reporterEmail,
          report.reportedUserName,
          report.reportedUserEmail,
          report.reason,
          report.description,
          report.tripDeparture,
          report.tripDestination,
        ].whereType<String>().join(' ').toLowerCase();
        return haystack.contains(_query);
      })
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final counts =
        _counts ??
        const ReportCounts(total: 0, pending: 0, reviewed: 0, resolved: 0);
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: RefreshIndicator(
          color: _blue,
          onRefresh: _load,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Signalements',
                                style: TextStyle(
                                  color: _navy,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Suivez et traitez les alertes de la communauté',
                                style: TextStyle(color: _muted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Actualiser',
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded, color: _blue),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        _statCard(
                          'Total',
                          counts.total,
                          Icons.flag_outlined,
                          _blue,
                        ),
                        _statCard(
                          'En attente',
                          counts.pending,
                          Icons.schedule_rounded,
                          _orange,
                        ),
                        _statCard(
                          'Examinés',
                          counts.reviewed,
                          Icons.fact_check_outlined,
                          const Color(0xFF7A63A8),
                        ),
                        _statCard(
                          'Résolus',
                          counts.resolved,
                          Icons.check_circle_outline_rounded,
                          _green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Auteur, utilisateur, motif ou trajet',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: _muted,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: _border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _filterStrip(
                      [
                        ('all', 'Tous'),
                        ('pending', 'En attente'),
                        ('reviewed', 'Examinés'),
                        ('resolved', 'Résolus'),
                      ],
                      _statusFilter,
                      (value) => setState(() => _statusFilter = value),
                    ),
                    const SizedBox(height: 8),
                    _filterStrip(
                      [
                        ('all', 'Tous les signalements'),
                        ('user', 'Utilisateur concerné'),
                        ('trip', 'Trajet concerné'),
                      ],
                      _relatedFilter,
                      (value) => setState(() => _relatedFilter = value),
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 72),
                        child: Center(
                          child: CircularProgressIndicator(color: _blue),
                        ),
                      )
                    else if (_error != null)
                      _stateMessage(
                        Icons.cloud_off_outlined,
                        _error!,
                        'Réessayer',
                        _load,
                      )
                    else if (_visibleReports.isEmpty)
                      _stateMessage(
                        Icons.outlined_flag_rounded,
                        _reports.isEmpty
                            ? 'Aucun signalement enregistré.'
                            : 'Aucun signalement ne correspond aux filtres.',
                        'Actualiser',
                        _load,
                      )
                    else
                      ..._visibleReports.map(_reportCard),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, int value, IconData icon, Color color) =>
      Container(
        width: (MediaQuery.sizeOf(context).width - 45) / 2,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: .035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _filterStrip(
    List<(String, String)> options,
    String selected,
    ValueChanged<String> onSelected,
  ) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(right: 7),
            child: ChoiceChip(
              label: Text(option.$2),
              selected: selected == option.$1,
              onSelected: (_) => onSelected(option.$1),
              selectedColor: const Color(0xFFEAF3FC),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected == option.$1
                    ? const Color(0xFFBCD4ED)
                    : _border,
              ),
              labelStyle: TextStyle(
                color: selected == option.$1 ? _blue : _muted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    ),
  );

  Widget _reportCard(Report report) => Container(
    margin: const EdgeInsets.only(bottom: 11),
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
    child: InkWell(
      onTap: () => _openDetails(report.id),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report.reason.isEmpty
                        ? 'Motif non renseigné'
                        : report.reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _statusBadge(report.status),
              ],
            ),
            const SizedBox(height: 11),
            _meta(
              Icons.person_outline_rounded,
              'Auteur : ${_person(report.reporterName)}',
            ),
            if (report.reportedUserId != null) ...[
              const SizedBox(height: 7),
              _meta(
                Icons.person_search_outlined,
                'Concerné : ${_person(report.reportedUserName)}',
              ),
            ],
            if (report.tripId != null) ...[
              const SizedBox(height: 7),
              _meta(Icons.route_outlined, _tripLabel(report)),
            ],
            const SizedBox(height: 9),
            Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 14, color: _muted),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    _dateTime(report.createdAt),
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ),
                const Text(
                  'Détails',
                  style: TextStyle(
                    color: _blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 3),
                const Icon(Icons.chevron_right_rounded, size: 17, color: _blue),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _meta(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 15, color: _muted),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );

  Widget _statusBadge(String status) {
    final (label, color, background) = switch (status) {
      'pending' => ('En attente', _orange, const Color(0xFFFFF5E8)),
      'reviewed' => ('Examiné', _blue, const Color(0xFFEAF3FC)),
      'resolved' => ('Résolu', _green, const Color(0xFFEAF8F1)),
      _ => ('Autre', _muted, const Color(0xFFF0F3F6)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _stateMessage(
    IconData icon,
    String title,
    String action,
    VoidCallback onTap,
  ) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 58),
    child: Column(
      children: [
        Icon(icon, size: 42, color: const Color(0xFF9AAEBC)),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, fontWeight: FontWeight.w600),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    ),
  );

  Future<void> _openDetails(int reportId) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AdminReportDetailsScreen(
          reportId: reportId,
          onStatusUpdated: _load,
        ),
      ),
    );
    if (mounted) await _load();
  }

  String _person(String? value) => value?.trim().isNotEmpty == true
      ? value!.trim()
      : 'Utilisateur introuvable';

  String _tripLabel(Report report) {
    final departure = report.tripDeparture?.trim();
    final destination = report.tripDestination?.trim();
    if (departure?.isNotEmpty == true && destination?.isNotEmpty == true) {
      return '$departure → $destination';
    }
    return 'Trajet introuvable';
  }

  String _dateTime(String value) {
    final date = DateTime.tryParse(value);
    return date == null
        ? 'Date inconnue'
        : DateFormat('dd MMM yyyy • HH:mm', 'fr_FR').format(date);
  }
}

class AdminReportDetailsScreen extends StatefulWidget {
  final int reportId;
  final VoidCallback onStatusUpdated;

  const AdminReportDetailsScreen({
    super.key,
    required this.reportId,
    required this.onStatusUpdated,
  });

  @override
  State<AdminReportDetailsScreen> createState() =>
      _AdminReportDetailsScreenState();
}

class _AdminReportDetailsScreenState extends State<AdminReportDetailsScreen> {
  static const _navy = Color(0xFF123D68);
  static const _blue = Color(0xFF1E5AA8);
  static const _muted = Color(0xFF71879A);
  static const _background = Color(0xFFF6F9FC);

  final _repository = ReportRepository();
  Report? _report;
  bool _loading = true;
  bool _updating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await _repository.getReportById(widget.reportId);
      if (!mounted) return;
      setState(() {
        _report = report;
        _loading = false;
        if (report == null) _error = 'Ce signalement est introuvable.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger ce signalement.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    appBar: AppBar(
      backgroundColor: _background,
      foregroundColor: _navy,
      elevation: 0,
      title: const Text(
        'Détail du signalement',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: _blue))
        : _error != null
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: const TextStyle(color: _muted)),
                TextButton(onPressed: _load, child: const Text('Réessayer')),
              ],
            ),
          )
        : _report == null
        ? const SizedBox.shrink()
        : _content(_report!),
  );

  Widget _content(Report report) => ListView(
    padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
    children: [
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report.reason.isEmpty
                        ? 'Motif non renseigné'
                        : report.reason,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _statusBadge(report.status),
              ],
            ),
            const SizedBox(height: 12),
            _line(Icons.schedule_outlined, _dateTime(report.createdAt)),
            if (report.description?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 13),
              const Text(
                'Description',
                style: TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                report.description!.trim(),
                style: const TextStyle(
                  color: _muted,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 13),
      _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personnes concernées',
              style: TextStyle(
                color: _navy,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            _line(
              Icons.person_outline_rounded,
              'Auteur : ${_person(report.reporterName)}',
            ),
            if (report.reporterEmail?.trim().isNotEmpty == true)
              _line(Icons.email_outlined, report.reporterEmail!.trim()),
            if (report.reportedUserId != null) ...[
              const SizedBox(height: 7),
              _line(
                Icons.person_search_outlined,
                'Utilisateur signalé : ${_person(report.reportedUserName)}',
              ),
              if (report.reportedUserEmail?.trim().isNotEmpty == true)
                _line(Icons.email_outlined, report.reportedUserEmail!.trim()),
            ],
          ],
        ),
      ),
      if (report.tripId != null) ...[
        const SizedBox(height: 13),
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trajet lié',
                style: TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              _line(Icons.route_outlined, _tripLabel(report)),
              if (report.tripDate?.isNotEmpty == true)
                _line(Icons.calendar_month_outlined, _date(report.tripDate!)),
              if (report.tripTime?.isNotEmpty == true)
                _line(Icons.access_time_rounded, report.tripTime!),
            ],
          ),
        ),
      ],
      const SizedBox(height: 18),
      if (report.status == 'pending')
        _statusAction(
          label: 'Marquer comme examiné',
          nextStatus: 'reviewed',
          icon: Icons.fact_check_outlined,
        )
      else if (report.status == 'reviewed')
        _statusAction(
          label: 'Marquer comme résolu',
          nextStatus: 'resolved',
          icon: Icons.check_circle_outline_rounded,
        ),
    ],
  );

  Widget _statusAction({
    required String label,
    required String nextStatus,
    required IconData icon,
  }) => SizedBox(
    height: 50,
    child: FilledButton.icon(
      onPressed: _updating ? null : () => _confirmStatusChange(nextStatus),
      icon: _updating
          ? const SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 19),
      label: Text(_updating ? 'Mise à jour…' : label),
      style: FilledButton.styleFrom(
        backgroundColor: _blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );

  Future<void> _confirmStatusChange(String status) async {
    final label = status == 'reviewed' ? 'examiné' : 'résolu';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          status == 'reviewed'
              ? 'Commencer l’examen ?'
              : 'Résoudre ce signalement ?',
        ),
        content: Text(
          'Le signalement sera marqué comme $label. Il restera conservé dans l’historique.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => _updating = true);
    try {
      await _repository.updateStatus(reportId: widget.reportId, status: status);
      if (!mounted) return;
      widget.onStatusUpdated();
      await _load();
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signalement marqué comme $label.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _updating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible de mettre à jour ce signalement. Actualisez et réessayez.',
          ),
        ),
      );
    }
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE6EDF3)),
      boxShadow: [
        BoxShadow(
          color: _navy.withValues(alpha: .03),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );

  Widget _line(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: _blue, size: 17),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: _muted, fontSize: 12, height: 1.35),
          ),
        ),
      ],
    ),
  );

  Widget _statusBadge(String status) {
    final (label, color, background) = switch (status) {
      'pending' => (
        'En attente',
        const Color(0xFFD89228),
        const Color(0xFFFFF5E8),
      ),
      'reviewed' => ('Examiné', _blue, const Color(0xFFEAF3FC)),
      'resolved' => (
        'Résolu',
        const Color(0xFF18A974),
        const Color(0xFFEAF8F1),
      ),
      _ => ('Autre', _muted, const Color(0xFFF0F3F6)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _person(String? value) => value?.trim().isNotEmpty == true
      ? value!.trim()
      : 'Utilisateur introuvable';
  String _tripLabel(Report report) {
    final departure = report.tripDeparture?.trim();
    final destination = report.tripDestination?.trim();
    return departure?.isNotEmpty == true && destination?.isNotEmpty == true
        ? '$departure → $destination'
        : 'Trajet introuvable';
  }

  String _dateTime(String value) {
    final date = DateTime.tryParse(value);
    return date == null
        ? 'Date inconnue'
        : DateFormat('dd MMM yyyy • HH:mm', 'fr_FR').format(date);
  }

  String _date(String value) {
    final date = DateTime.tryParse(value);
    return date == null
        ? value
        : DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }
}
