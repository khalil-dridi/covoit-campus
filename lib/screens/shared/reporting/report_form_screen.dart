import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../models/user_profile_context.dart';
import '../../../repositories/report_repository.dart';

enum ReportFlow { passengerReportsDriver, driverReportsPassenger }

class ReportFormScreen extends StatefulWidget {
  final User reporter;
  final int? bookingId;
  final int? targetUserId;
  final UserProfileContext? profileContext;
  final ReportFlow flow;
  final String targetName;
  final String routeLabel;

  const ReportFormScreen({
    super.key,
    required this.reporter,
    this.bookingId,
    this.targetUserId,
    this.profileContext,
    required this.flow,
    required this.targetName,
    required this.routeLabel,
  });

  @override
  State<ReportFormScreen> createState() => _ReportFormScreenState();
}

class _ReportFormScreenState extends State<ReportFormScreen> {
  static const _navy = Color(0xFF123D68);
  static const _blue = Color(0xFF1E5AA8);
  static const _green = Color(0xFF18A974);
  static const _muted = Color(0xFF71879A);
  static const _background = Color(0xFFF6F9FC);

  static const _passengerReasons = [
    'Conducteur absent',
    'Comportement inapproprié',
    'Problème de sécurité',
    'Non-respect du trajet',
    'Problème avec le véhicule',
    'Autre',
  ];
  static const _driverReasons = [
    'Passager absent',
    'Comportement inapproprié',
    'Problème de sécurité',
    'Non-respect des consignes',
    'Problème de paiement',
    'Autre',
  ];

  final _repository = ReportRepository();
  final _descriptionController = TextEditingController();
  String? _reason;
  bool _saving = false;
  String? _error;

  List<String> get _reasons => widget.flow == ReportFlow.passengerReportsDriver
      ? _passengerReasons
      : _driverReasons;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    appBar: AppBar(
      backgroundColor: _background,
      foregroundColor: _navy,
      elevation: 0,
      title: const Text(
        'Signaler un problème',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
        children: [
          const Text(
            'Aidez-nous à comprendre la situation. Votre signalement sera transmis à l’équipe de modération.',
            style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          _contextCard(),
          const SizedBox(height: 18),
          const Text(
            'Motif *',
            style: TextStyle(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          DropdownButtonFormField<String>(
            initialValue: _reason,
            isExpanded: true,
            decoration: _inputDecoration(
              'Choisir un motif',
              Icons.flag_outlined,
            ),
            items: _reasons
                .map(
                  (reason) =>
                      DropdownMenuItem(value: reason, child: Text(reason)),
                )
                .toList(),
            onChanged: _saving
                ? null
                : (value) => setState(() {
                    _reason = value;
                    _error = null;
                  }),
          ),
          const SizedBox(height: 16),
          const Text(
            'Description (facultatif)',
            style: TextStyle(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          TextField(
            controller: _descriptionController,
            enabled: !_saving,
            minLines: 4,
            maxLines: 6,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: _inputDecoration(
              'Décrivez brièvement le problème',
              Icons.notes_outlined,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(
              _error!,
              style: const TextStyle(color: Color(0xFFB54747), fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _saving
                      ? null
                      : () => Navigator.of(context).maybePop(false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: Color(0xFFDCE7E3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 17),
                  label: Text(_saving ? 'Envoi…' : 'Envoyer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _contextCard() => Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: const Color(0xFFE6EDF3)),
      boxShadow: [
        BoxShadow(
          color: _navy.withValues(alpha: .035),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Concernant',
          style: TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.targetName.trim().isEmpty ? 'Utilisateur' : widget.targetName,
          style: const TextStyle(
            color: _navy,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.profileContext?.rideRequestId != null ? 'Demande de trajet' : 'Trajet',
          style: TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          (widget.profileContext?.routeLabel ?? widget.routeLabel).trim().isEmpty
              ? 'Trajet associé à la réservation'
              : (widget.profileContext?.routeLabel ?? widget.routeLabel),
          style: const TextStyle(
            color: _navy,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 19, color: _muted),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1E8EE)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1E8EE)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _blue, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
      );

  Future<void> _submit() async {
    if (_saving) return;
    final reason = _reason;
    if (reason == null || reason.trim().isEmpty) {
      setState(() => _error = 'Choisissez un motif avant l’envoi.');
      return;
    }
    final reporterId = widget.reporter.id;
    if (reporterId == null) {
      setState(() => _error = 'Impossible d’identifier votre compte.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (widget.profileContext != null && widget.targetUserId != null) {
        await _repository.createProfileReport(
          reporterId: reporterId,
          targetId: widget.targetUserId!,
          tripId: widget.profileContext!.tripId,
          bookingId: widget.profileContext!.bookingId ?? widget.bookingId,
          rideRequestId: widget.profileContext!.rideRequestId,
          contextLabel: widget.profileContext!.routeLabel,
          reason: reason,
          description: _descriptionController.text,
        );
      } else if (widget.flow == ReportFlow.passengerReportsDriver && widget.bookingId != null) {
        await _repository.createReportFromPassengerBooking(
          reporterId: reporterId,
          bookingId: widget.bookingId!,
          reason: reason,
          description: _descriptionController.text,
        );
      } else if (widget.flow == ReportFlow.driverReportsPassenger && widget.bookingId != null) {
        await _repository.createReportFromDriverBooking(
          reporterId: reporterId,
          bookingId: widget.bookingId!,
          reason: reason,
          description: _descriptionController.text,
        );
      } else {
        throw StateError('Le contexte du signalement est indisponible.');
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ArgumentError catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message.toString();
      });
    } on StateError catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Le signalement n’a pas pu être envoyé. Réessayez.';
      });
    }
  }
}
