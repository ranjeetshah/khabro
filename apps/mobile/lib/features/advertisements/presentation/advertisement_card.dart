import 'package:flutter/material.dart';

import '../data/advertisement_model.dart';
import '../data/impression_guard.dart';
import '../data/safe_url_launcher.dart';

class AdvertisementCard extends StatefulWidget {
  const AdvertisementCard({
    super.key,
    required this.advertisement,
    required this.onImpression,
    required this.onClick,
    this.compact = false,
    this.urlOpener,
  });

  final AdvertisementModel advertisement;
  final Future<void> Function(String id) onImpression;
  final Future<void> Function(String id) onClick;
  final bool compact;
  final UrlOpener? urlOpener;

  @override
  State<AdvertisementCard> createState() => _AdvertisementCardState();
}

class _AdvertisementCardState extends State<AdvertisementCard> {
  bool _opening = false;
  bool _impressionRecorded = false;
  String? _openError;

  @override
  void initState() {
    super.initState();
    _recordImpressionOnce();
  }

  void _recordImpressionOnce() {
    if (_impressionRecorded) return;
    if (!ImpressionGuard.instance.tryRecord(
      widget.advertisement.id,
      widget.advertisement.placement,
    )) {
      return;
    }
    _impressionRecorded = true;
    widget.onImpression(widget.advertisement.id);
  }

  Future<void> _openDestination() async {
    if (_opening) return;
    setState(() {
      _opening = true;
      _openError = null;
    });
    final opened = await openAdvertisementUrl(
      widget.advertisement.destinationUrl,
      opener: widget.urlOpener,
    );
    if (!mounted) return;
    setState(() {
      _opening = false;
      _openError = opened ? null : 'Couldn\'t open this advertisement.';
    });
    if (opened) {
      widget.onClick(widget.advertisement.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.advertisement;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: InkWell(
        onTap: _opening ? null : _openDestination,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Sponsored',
                      style: TextStyle(
                        color: Color(0xFFB26A00),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ad.advertiserName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.campaign_outlined,
                    color: Color(0xFF9CA3AF),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!widget.compact && ad.creativeUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    ad.creativeUrl,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _imagePlaceholder(),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                ad.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              if (ad.description != null && ad.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  ad.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ad.ctaLabel ?? 'Learn more',
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  if (_opening)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              if (_openError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _openError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 120,
      width: double.infinity,
      color: const Color(0xFFF3F4F6),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFF9CA3AF),
        size: 32,
      ),
    );
  }
}