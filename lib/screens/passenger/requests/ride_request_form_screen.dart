import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/user.dart';
import '../../../repositories/ride_request_repository.dart';

class RideRequestFormScreen extends StatefulWidget {
  final User user;

  const RideRequestFormScreen({super.key, required this.user});

  @override
  State<RideRequestFormScreen> createState() => _RideRequestFormScreenState();
}

class _RideRequestFormScreenState extends State<RideRequestFormScreen> {
  static const _blue = Color(0xFF123D68);
  static const _green = Color(0xFF20B978);
  static const _background = Color(0xFFF4FFFB);

  final _formKey = GlobalKey<FormState>();
  final _departureController = TextEditingController();
  final _destinationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _repository = RideRequestRepository();
  DateTime? _date;
  TimeOfDay? _time;
  int _seats = 1;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _departureController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      helpText: 'Date souhaitée',
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _chooseTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
      helpText: 'Heure souhaitée (facultatif)',
    );
    if (selected != null && mounted) setState(() => _time = selected);
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (_date == null) {
      setState(() => _error = 'Veuillez choisir une date souhaitée.');
      return;
    }
    final passengerId = widget.user.id;
    if (passengerId == null) {
      setState(
        () => _error = 'Votre session ne permet pas de publier cette demande.',
      );
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _repository.createRequest(
        passengerId: passengerId,
        departure: _departureController.text,
        destination: _destinationController.text,
        requestDate: DateFormat('yyyy-MM-dd').format(_date!),
        requestTime: _time == null
            ? null
            : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}',
        seatsRequested: _seats,
        description: _descriptionController.text,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: const Icon(Icons.check_circle_rounded, color: _green, size: 44),
          title: const Text('Demande publiée'),
          content: const Text(
            'Votre demande de covoiturage a bien été enregistrée.',
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _green),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Terminer'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error is ArgumentError || error is StateError
            ? error.toString().replaceFirst('Invalid argument(s): ', '')
            : 'La demande n’a pas pu être publiée. Réessayez.';
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    appBar: AppBar(
      backgroundColor: _background,
      foregroundColor: _blue,
      elevation: 0,
      title: const Text(
        'Publier une demande',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    body: SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Indiquez votre itinéraire et vos disponibilités. Les conducteurs pourront consulter votre demande.',
                style: TextStyle(color: _blue, height: 1.45),
              ),
            ),
            const SizedBox(height: 18),
            _textField(
              _departureController,
              label: 'Ville de départ',
              icon: Icons.trip_origin_rounded,
            ),
            const SizedBox(height: 13),
            _textField(
              _destinationController,
              label: 'Destination',
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 13),
            _pickerTile(
              icon: Icons.calendar_month_rounded,
              label: 'Date souhaitée',
              value: _date == null
                  ? 'Choisir une date'
                  : DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_date!),
              onTap: _chooseDate,
            ),
            const SizedBox(height: 13),
            _pickerTile(
              icon: Icons.schedule_rounded,
              label: 'Heure souhaitée',
              value: _time == null ? 'Facultative' : _time!.format(context),
              onTap: _chooseTime,
              trailing: _time == null
                  ? null
                  : IconButton(
                      onPressed: () => setState(() => _time = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_seat_outlined, color: _blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Places souhaitées',
                      style: TextStyle(
                        color: _blue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _seats > 1
                        ? () => setState(() => _seats--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  Text(
                    '$_seats',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    onPressed: _seats < 8
                        ? () => setState(() => _seats++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline, color: _green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _descriptionController,
              maxLength: 500,
              maxLines: 4,
              decoration: _decoration(
                'Informations complémentaires (facultatif)',
                Icons.notes_rounded,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 4),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _submitting ? 'Publication…' : 'Publier ma demande',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _textField(
    TextEditingController controller, {
    required String label,
    required IconData icon,
  }) => TextFormField(
    controller: controller,
    textCapitalization: TextCapitalization.words,
    validator: (value) => value == null || value.trim().isEmpty
        ? 'Ce champ est obligatoire.'
        : null,
    decoration: _decoration(label, icon),
  );

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _blue),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE6ECE9)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: _green, width: 1.5),
    ),
  );

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    Widget? trailing,
  }) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6ECE9)),
        ),
        child: Row(
          children: [
            Icon(icon, color: _blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF547080),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    ),
  );
}
