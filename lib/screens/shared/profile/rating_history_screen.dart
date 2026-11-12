import 'dart:io';

import 'package:flutter/material.dart';

import '../../../models/rating_history_entry.dart';
import '../../../repositories/rating_repository.dart';

class RatingHistoryScreen extends StatefulWidget {
  final int userId;

  const RatingHistoryScreen({super.key, required this.userId});

  @override
  State<RatingHistoryScreen> createState() => _RatingHistoryScreenState();
}

class _RatingHistoryScreenState extends State<RatingHistoryScreen>
    with SingleTickerProviderStateMixin {
  static const _blue = Color(0xFF123D68);
  static const _background = Color(0xFFF4FFFB);
  final _repository = RatingRepository();
  late final TabController _tabs;
  late Future<List<RatingHistoryEntry>> _received;
  late Future<List<RatingHistoryEntry>> _given;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  void _load() {
    _received = _repository.getRatingHistoryReceivedByUser(widget.userId);
    _given = _repository.getRatingHistoryGivenByUser(widget.userId);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _background,
    appBar: AppBar(
      backgroundColor: _background,
      foregroundColor: _blue,
      elevation: 0,
      title: const Text('Historique des évaluations'),
      bottom: TabBar(
        controller: _tabs,
        labelColor: _blue,
        indicatorColor: _blue,
        tabs: const [
          Tab(text: 'Avis reçus'),
          Tab(text: 'Avis donnés'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabs,
      children: [
        _buildList(_received, received: true),
        _buildList(_given, received: false),
      ],
    ),
  );

  Widget _buildList(
    Future<List<RatingHistoryEntry>> future, {
    required bool received,
  }) => FutureBuilder<List<RatingHistoryEntry>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Center(
          child: TextButton.icon(
            onPressed: () => setState(_load),
            icon: const Icon(Icons.refresh),
            label: const Text('Erreur de chargement. Réessayer'),
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final entries = snapshot.data!;
      if (entries.isEmpty) {
        return RatingHistoryEmptyState(received: received);
      }
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _RatingCard(
          entry: entries[index],
          date: _formatDate(entries[index].rating.createdAt),
        ),
      );
    },
  );

  String _formatDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    final local = parsed.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class RatingHistoryEmptyState extends StatelessWidget {
  final bool received;

  const RatingHistoryEmptyState({super.key, required this.received});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            received ? Icons.star_border_rounded : Icons.rate_review_outlined,
            size: 48,
            color: Colors.blueGrey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            received
                ? 'Vous n’avez pas encore reçu d’avis.'
                : 'Vous n’avez pas encore donné d’avis.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF123D68),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _RatingCard extends StatelessWidget {
  final RatingHistoryEntry entry;
  final String date;

  const _RatingCard({required this.entry, required this.date});

  @override
  Widget build(BuildContext context) {
    final rating = entry.rating;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _HistoryAvatar(image: entry.otherUserProfileImage),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  entry.otherUserName ?? 'Utilisateur',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF123D68),
                  ),
                ),
              ),
              Text(
                date,
                style: TextStyle(color: Colors.blueGrey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < rating.score
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                color: const Color(0xFFE2A631),
                size: 21,
              ),
            ),
          ),
          if (rating.comment?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(rating.comment!, style: const TextStyle(height: 1.35)),
          ],
          if ((entry.departure?.isNotEmpty == true) ||
              (entry.destination?.isNotEmpty == true)) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.route_rounded,
                  size: 17,
                  color: Color(0xFF547080),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${entry.departure ?? 'Départ'} → ${entry.destination ?? 'Destination'}'
                    '${entry.departureDate == null ? '' : ' · ${_tripDate(entry.departureDate!)}'}',
                    style: const TextStyle(
                      color: Color(0xFF547080),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _tripDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;
    return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }
}

class _HistoryAvatar extends StatelessWidget {
  final String? image;

  const _HistoryAvatar({this.image});

  @override
  Widget build(BuildContext context) {
    final path = image?.trim();
    final uri = path == null ? null : Uri.tryParse(path);
    final isNetwork =
        uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
    final isAsset = path?.startsWith('assets/') == true;
    ImageProvider? provider;
    if (path != null && path.isNotEmpty) {
      if (isNetwork) provider = NetworkImage(path);
      if (isAsset) provider = AssetImage(path);
      if (!isNetwork && !isAsset) provider = FileImage(File(path));
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: const Color(0xFFEAF3FC),
      backgroundImage: provider,
      child: provider == null
          ? const Icon(Icons.person, color: Color(0xFF123D68))
          : null,
    );
  }
}
