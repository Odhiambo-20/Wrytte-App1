import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/enrollment_draft.dart';

class EnrollmentUploadResult {
  const EnrollmentUploadResult({
    required this.ok,
    required this.message,
    required this.hashkey,
    this.rawBody,
    this.requestUrl,
    this.statusCode,
  });

  final bool ok;
  final String message;
  /// The hashkey returned by the server after running RetinaFace + AdaFace.
  /// Empty string if the request failed.
  final String hashkey;
  final String? rawBody;
  final String? requestUrl;
  final int? statusCode;
}

const _kEndpointPrefKey = 'enrollment_api_url';
const _kDevFallbackUrl  = 'http://192.168.100.157:8000/enroll';
const _kCompileTimeEndpoint = String.fromEnvironment(
  'ENROLLMENT_API_URL',
  defaultValue: _kDevFallbackUrl,
);

class BiometricEnrollmentApi {
  BiometricEnrollmentApi({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  String _cachedEndpoint = _kCompileTimeEndpoint;

  Future<String> getEndpoint() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kEndpointPrefKey) ?? '';
    if (saved.isNotEmpty) return saved;
    return _kCompileTimeEndpoint;
  }

  static Future<void> setEndpoint(String url) async {
    final prefs = await SharedPreferences.getInstance();
    if (url.isEmpty) {
      await prefs.remove(_kEndpointPrefKey);
    } else {
      await prefs.setString(_kEndpointPrefKey, url.trim());
    }
  }

  String get endpointSync => _cachedEndpoint;

  Future<void> loadEndpoint() async {
    _cachedEndpoint = await getEndpoint();
  }

  /// Sends [username], the raw [videoFile], and the original camera frame
  /// size ([frameWidth] x [frameHeight]) to the server.
  ///
  /// The server runs RetinaFace + AdaFace + LDPC and returns the hashkey.
  /// The frame size is stored in the enrollment JSON as "W X H".
  Future<EnrollmentUploadResult> uploadEnrollment({
    required EnrollmentDraft draft,
    required File videoFile,
    double frameWidth = 0,
    double frameHeight = 0,
  }) async {
    final url = await getEndpoint();
    _cachedEndpoint = url;

    if (url.isEmpty) {
      debugPrint('[EnrollmentApi] ERROR: No upload URL configured.');
      return const EnrollmentUploadResult(
        ok: false,
        hashkey: '',
        message:
            'No upload URL configured.\n\n'
            'Set one via --dart-define=ENROLLMENT_API_URL=http://...\n'
            'Or persist a URL in SharedPreferences (enrollment_api_url).',
        requestUrl: null,
        statusCode: null,
      );
    }

    debugPrint('[EnrollmentApi] POST → $url');
    debugPrint('[EnrollmentApi]   username     : ${draft.username}');
    debugPrint('[EnrollmentApi]   frame size   : '
        '${frameWidth.toInt()} X ${frameHeight.toInt()}');

    final filename = videoFile.uri.pathSegments.isNotEmpty
        ? videoFile.uri.pathSegments.last
        : 'enrollment.mp4';

    // ── Send frame dimensions as "W X H" strings so the server can store
    //    them verbatim in the enrollment JSON without any reformatting.
    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..fields['username']      = draft.username
      ..fields['frame_width']   = frameWidth.toInt().toString()
      ..fields['frame_height']  = frameHeight.toInt().toString();

    request.files.add(
      await http.MultipartFile.fromPath(
        'video',
        videoFile.path,
        filename: filename,
      ),
    );

    debugPrint('[EnrollmentApi] Sending video: $filename');
    final stopwatch = Stopwatch()..start();

    final streamed  = await _client.send(request);
    final response  = await http.Response.fromStream(streamed);

    stopwatch.stop();

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    debugPrint('[EnrollmentApi] Response ${response.statusCode} in '
        '${stopwatch.elapsedMilliseconds} ms');

    String message = ok
        ? 'Enrollment successful.'
        : 'Upload failed (HTTP ${response.statusCode}).';
    String hashkey = '';

    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;

        // ── Extract hashkey produced by the server pipeline ───────────────
        final serverHashkey = decoded['hashkey']?.toString() ?? '';
        if (serverHashkey.isNotEmpty) {
          hashkey = serverHashkey;
          debugPrint('[EnrollmentApi]   hashkey  : $hashkey');
        }

        // ── Extract human-readable message ────────────────────────────────
        final serverMessage = decoded['message']?.toString() ?? '';
        if (serverMessage.isNotEmpty) {
          message = serverMessage;
        }

        // ── On error, surface FastAPI detail ──────────────────────────────
        if (!ok) {
          if (response.statusCode == 409) {
            message = 'You already have an account. Please log in.';
          } else {
            final detail = decoded['detail'];
            if (detail != null) {
              final detailStr = detail is List
                  ? (detail as List)
                      .whereType<Map>()
                      .map((e) => e['msg']?.toString() ?? '')
                      .where((s) => s.isNotEmpty)
                      .join('; ')
                  : detail.toString();
              if (detailStr.isNotEmpty) {
                message = 'Upload failed (HTTP ${response.statusCode}): $detailStr';
              }
            }
          }
        }
      } catch (_) {
        if (!ok) {
          message = '${message.trim()} ${response.body}'.trim();
        }
      }
    }

    return EnrollmentUploadResult(
      ok: ok,
      message: message,
      hashkey: hashkey,
      rawBody: (ok || response.statusCode == 409) ? null : response.body,
      requestUrl: ok ? null : url,
      statusCode: response.statusCode,
    );
  }
}
