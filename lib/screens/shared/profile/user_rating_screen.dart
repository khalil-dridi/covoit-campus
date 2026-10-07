import 'package:flutter/material.dart';

import '../../../models/user.dart';
import '../../../repositories/rating_repository.dart';

class UserRatingScreen extends StatefulWidget {
  final User reviewer;
  final User reviewed;
  final int tripId;

  const UserRatingScreen({
    super.key,
    required this.reviewer,
    required this.reviewed,
    required this.tripId,
  });

  @override
  State<UserRatingScreen> createState() => _UserRatingScreenState();
}

class _UserRatingScreenState extends State<UserRatingScreen> {
  static const _blue = Color(0xFF123D68);
  static const _green = Color(0xFF20B978);
  final _repository = RatingRepository();
  final _comment = TextEditingController();
  int _score = 0;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4FFFB),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF4FFFB),
      foregroundColor: _blue,
      elevation: 0,
      title: const Text('Évaluer'),
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Évaluer ${widget.reviewed.fullName}',
            style: const TextStyle(
              color: _blue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          Semantics(
            label: 'Note : $_score sur 5',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: _saving
                      ? null
                      : () => setState(() {
                          _score = index + 1;
                          _error = null;
                        }),
                  icon: Icon(
                    index < _score
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: const Color(0xFFE2A631),
                    size: 38,
                  ),
                  tooltip: '${index + 1} étoile${index == 0 ? '' : 's'}',
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _comment,
            enabled: !_saving,
            minLines: 4,
            maxLines: 6,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Votre commentaire (facultatif)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 15),
          FilledButton.icon(
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.publish_rounded),
            label: Text(_saving ? 'Publication…' : 'Publier l’évaluation'),
            style: FilledButton.styleFrom(
              backgroundColor: _green,
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _submit() async {
    if (_score < 1) {
      setState(() => _error = 'Choisissez une note de 1 à 5 étoiles.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.submitRating(
        tripId: widget.tripId,
        reviewerId: widget.reviewer.id!,
        reviewedId: widget.reviewed.id!,
        score: _score,
        comment: _comment.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error is StateError || error is ArgumentError
            ? error
                  .toString()
                  .replaceFirst('Bad state: ', '')
                  .replaceFirst('Invalid argument(s): ', '')
            : 'Impossible de publier cette évaluation.';
      });
    }
  }
}
