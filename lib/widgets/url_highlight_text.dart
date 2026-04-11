import 'package:flutter/material.dart';
import 'package:phishcatch/models/phish_flag.dart';
import 'package:phishcatch/theme/app_theme.dart';

class UrlHighlightText extends StatelessWidget {
  final String url;
  final List<PhishFlag> flags;

  const UrlHighlightText({
    super.key,
    required this.url,
    required this.flags,
  });

  @override
  Widget build(BuildContext context) {
    final normalStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: FontWeight.w400,
      fontSize: 13,
      fontFamily: 'monospace',
    );

    const highlightStyle = TextStyle(
      color: AppColors.dangerous,
      fontWeight: FontWeight.w700,
      fontSize: 13,
      fontFamily: 'monospace',
      backgroundColor: AppColors.dangerousLight,
    );

    final segments = flags
        .map(_segmentFor)
        .whereType<String>()
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();

    if (segments.isEmpty) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Text(url, style: normalStyle),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: RichText(
        text: TextSpan(
          children: _buildSpans(url, segments, normalStyle, highlightStyle),
        ),
      ),
    );
  }

  List<TextSpan> _buildSpans(
    String source,
    List<String> segments,
    TextStyle normal,
    TextStyle highlight,
  ) {
    final usedSegments = <String>{};
    final matches = <_SegmentMatch>[];

    for (final segment in segments) {
      if (usedSegments.contains(segment)) {
        continue;
      }
      final index = source.indexOf(segment);
      if (index >= 0) {
        matches.add(_SegmentMatch(start: index, end: index + segment.length));
        usedSegments.add(segment);
      }
    }

    if (matches.isEmpty) {
      return [TextSpan(text: source, style: normal)];
    }

    matches.sort((a, b) => a.start.compareTo(b.start));

    final filtered = <_SegmentMatch>[];
    var lastEnd = -1;
    for (final match in matches) {
      if (match.start >= lastEnd) {
        filtered.add(match);
        lastEnd = match.end;
      }
    }

    final spans = <TextSpan>[];
    var cursor = 0;

    for (final match in filtered) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: source.substring(cursor, match.start), style: normal));
      }
      spans.add(TextSpan(text: source.substring(match.start, match.end), style: highlight));
      cursor = match.end;
    }

    if (cursor < source.length) {
      spans.add(TextSpan(text: source.substring(cursor), style: normal));
    }

    return spans;
  }

  String? _segmentFor(PhishFlag flag) {
    final dynamic raw = flag;
    try {
      final String? segment = raw.urlSegment as String?;
      if (segment != null && segment.isNotEmpty) {
        return segment;
      }
    } catch (_) {
      // Fall back to current model field below.
    }
    return flag.evidence;
  }
}

class _SegmentMatch {
  final int start;
  final int end;

  const _SegmentMatch({required this.start, required this.end});
}

