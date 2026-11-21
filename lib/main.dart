import 'dart:math';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:archive/archive.dart';

// ============================================================================
// KONFIGURASI
// ============================================================================
const String kSupabaseUrl = 'https://wvsjvvucoxchuauqjkut.supabase.co';
const String kSupabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Ind2c2p2dnVjb3hjaHVhdXFqa3V0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMxNjM5MjUsImV4cCI6MjEwODczOTkyNX0.iTDzpOxLgQCRiGqp6__Wn4VmrOhxJzVmVNs0Hz8vw04';
const String kApplicationId = 'com.hookify.app';
const String kOwnerWhatsApp = '6281554034879';
const int kTrialLimit = 3;

// ============================================================================
// TOKEN DESAIN (Blueprint Hookify v3, bagian Desain tab Kido Ads)
// ============================================================================
const Color kOrange = Color(0xFFFF5C1A);
const Color kOrange2 = Color(0xFFFF8A00);
const Color kInk = Color(0xFF16110C);
const Color kPaper = Color(0xFFFFFAF3);
const Color kLineLight = Color(0xFFEDE4D6);
const Color kMutedLight = Color(0xFF8A7C68);
const Color kDarkBg = Color(0xFF131110);
const Color kLogoBg = Color(0xFF0C1113);
const Color kLogoRed = Color(0xFFFA2F27);
const Color kDarkSurface = Color(0xFF1D1A16);
const Color kLineDark = Color(0xFF2C2721);
const Color kTextDark = Color(0xFFF5EFE6);
const Color kSuccess = Color(0xFF1E9E66);
const Color kWarning = Color(0xFFD97706);
const Color kDanger = Color(0xFFC62F2F);
const Cubic kCurve = Cubic(0.22, 1, 0.36, 1);

ThemeData buildHookifyTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: kOrange,
    onPrimary: Colors.white,
    secondary: kOrange2,
    onSecondary: Colors.white,
    error: kDanger,
    onError: Colors.white,
    surface: dark ? kDarkSurface : Colors.white,
    onSurface: dark ? kTextDark : kInk,
  );
  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? kDarkBg : kPaper,
    fontFamily: 'Inter',
    useMaterial3: true,
    textTheme: const TextTheme(
      headlineSmall: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 20),
      titleMedium: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
      bodyMedium: TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.5),
      bodyLarge: TextStyle(fontFamily: 'Inter', fontSize: 15.5, height: 1.55),
      labelSmall: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 12, letterSpacing: 1.2),
    ),
    dividerColor: dark ? kLineDark : kLineLight,
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? kDarkBg : kPaper,
      foregroundColor: dark ? kTextDark : kInk,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 20,
        color: dark ? kTextDark : kInk,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark ? kDarkSurface : kInk,
      contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Inter'),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

// ============================================================================
// MODEL RIWAYAT
// ============================================================================
class ScriptItem {
  final String id;
  final DateTime ts;
  final String niche;
  final String platform;
  final String duration;
  final String tone;
  final String prod;
  final String pain;
  final String offer;
  final bool premium;
  final String persona;
  final String creativity;
  final String customPrompt;
  Map<String, String> data;
  String body;
  bool fav;

  ScriptItem({
    required this.id,
    required this.ts,
    required this.niche,
    required this.platform,
    required this.duration,
    required this.tone,
    required this.prod,
    required this.pain,
    required this.offer,
    required this.premium,
    required this.persona,
    required this.creativity,
    required this.customPrompt,
    required this.data,
    required this.body,
    this.fav = false,
  });

  String get fullText {
    final b = StringBuffer();
    b.writeln('PLATFORM: $platform | NICHE: $niche');
    b.writeln('');
    b.writeln('3 VARIASI HOOK (A/B TESTING):');
    b.writeln('1. "${data['hook1']}"');
    b.writeln('2. "${data['hook2']}"');
    b.writeln('3. "${data['hook3']}"');
    b.writeln('');
    b.writeln('STRUKTUR SKRIP VIDEO:');
    b.write(body);
    b.writeln('');
    b.writeln('CAPTION & HASHTAG:');
    b.writeln('"${data['caption']}"');
    return b.toString();
  }

  void recompose() {
    body = HookDatabase.buildScriptBody(
      duration: duration,
      prod: prod,
      pain: pain,
      offer: offer,
      data: data,
      isYearlyOrLifetime: premium,
      targetPlatform: platform,
      customBrandPersona: persona,
      aiCreativityLevel: creativity,
      customSystemPrompt: customPrompt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ts': ts.toIso8601String(),
        'niche': niche,
        'platform': platform,
        'duration': duration,
        'tone': tone,
        'prod': prod,
        'pain': pain,
        'offer': offer,
        'premium': premium,
        'persona': persona,
        'creativity': creativity,
        'customPrompt': customPrompt,
        'data': data,
        'body': body,
        'fav': fav,
      };

  static ScriptItem fromJson(Map<String, dynamic> j) => ScriptItem(
        id: j['id'] as String,
        ts: DateTime.parse(j['ts'] as String),
        niche: j['niche'] as String,
        platform: j['platform'] as String,
        duration: j['duration'] as String,
        tone: j['tone'] as String,
        prod: j['prod'] as String,
        pain: j['pain'] as String,
        offer: j['offer'] as String,
        premium: j['premium'] as bool,
        persona: (j['persona'] ?? '') as String,
        creativity: (j['creativity'] ?? 'Normal (Balanced)') as String,
        customPrompt: (j['customPrompt'] ?? '') as String,
        data: Map<String, String>.from(j['data'] as Map),
        body: j['body'] as String,
        fav: (j['fav'] ?? false) as bool,
      );
}

// ============================================================================
// PENYIMPANAN + LISENSI SERVER
// ============================================================================
class AppStore extends ChangeNotifier {
  bool ready = false;
  String deviceId = '';
  String deviceLabel = '';

  String? licCode;
  String? licTier;
  DateTime? licExpiry;
  DateTime? lastCheck;
  bool onlineBlocked = false;
  String? licError;

  int trialUsed = 0;
  List<ScriptItem> history = [];
  String lastNiche = 'Beauty & Skincare';
  String lastPlatform = 'TikTok Video';
  ThemeMode themeMode = ThemeMode.system;

  bool get isPaid {
    if (licCode == null || licTier == null || licExpiry == null) return false;
    if (licExpiry!.isBefore(DateTime.now())) return false;
    return true;
  }

  bool get canGenerate => isPaid ? !onlineBlocked : trialLeft > 0;
  bool get isPremium => isPaid && (licTier == 'YR' || licTier == 'LIFE');
  int get trialLeft => max(0, kTrialLimit - trialUsed);

  Duration get offlineTolerance {
    if (licTier == 'LIFE') return const Duration(days: 30);
    return const Duration(hours: 72);
  }

  String get tierName {
    switch (licTier) {
      case 'MON':
        return 'Starter';
      case 'YR':
        return 'Pro Tahunan';
      case 'LIFE':
        return 'Agency Lifetime';
      default:
        return 'Mode Trial';
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    deviceId = await _deviceHash(prefs);
    try {
      final info = DeviceInfoPlugin();
      final a = await info.androidInfo;
      deviceLabel = '${a.manufacturer} ${a.model}';
    } catch (_) {
      deviceLabel = '';
    }
    licCode = prefs.getString('lic_code');
    licTier = prefs.getString('lic_tier');
    final exp = prefs.getString('lic_expiry');
    if (exp != null) licExpiry = DateTime.tryParse(exp);
    final lc = prefs.getString('lic_last_check');
    if (lc != null) lastCheck = DateTime.tryParse(lc);
    trialUsed = prefs.getInt('trial_used') ?? 0;
    lastNiche = prefs.getString('last_niche') ?? lastNiche;
    lastPlatform = prefs.getString('last_platform') ?? lastPlatform;
    final tm = prefs.getString('theme_mode');
    if (tm == 'light') themeMode = ThemeMode.light;
    if (tm == 'dark') themeMode = ThemeMode.dark;
    final raw = prefs.getString('history_v1');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        history = list
            .map((e) => ScriptItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      } catch (_) {
        history = [];
      }
    }
    ready = true;
    notifyListeners();
    if (isPaid || licCode != null) {
      refreshLicense();
    }
  }

  Future<String> _deviceHash(SharedPreferences prefs) async {
    String raw = '';
    try {
      final info = DeviceInfoPlugin();
      final a = await info.androidInfo;
      raw = a.id;
    } catch (_) {}
    if (raw.isEmpty) {
      raw = prefs.getString('fallback_device_id') ?? '';
      if (raw.isEmpty) {
        final rnd = Random.secure();
        raw = List.generate(24, (_) => rnd.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
        await prefs.setString('fallback_device_id', raw);
      }
    }
    return sha256.convert(utf8.encode('$raw$kApplicationId')).toString();
  }

  Future<Map<String, dynamic>> _rpc(String fn, Map<String, dynamic> body) async {
    final res = await http
        .post(
          Uri.parse('$kSupabaseUrl/rest/v1/rpc/$fn'),
          headers: {
            'apikey': kSupabaseAnonKey,
            'Authorization': 'Bearer $kSupabaseAnonKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('HTTP ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> _saveLicense(SharedPreferences prefs) async {
    if (licCode == null) {
      await prefs.remove('lic_code');
      await prefs.remove('lic_tier');
      await prefs.remove('lic_expiry');
      await prefs.remove('lic_last_check');
    } else {
      await prefs.setString('lic_code', licCode!);
      if (licTier != null) await prefs.setString('lic_tier', licTier!);
      if (licExpiry != null) await prefs.setString('lic_expiry', licExpiry!.toIso8601String());
      if (lastCheck != null) await prefs.setString('lic_last_check', lastCheck!.toIso8601String());
    }
  }

  /// Mengembalikan null bila sukses, atau pesan alasan bila gagal.
  Future<String?> activate(String code) async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final r = await _rpc('hookify_aktivasi', {
        'p_kode': code.trim().toUpperCase(),
        'p_device': deviceId,
        'p_label': deviceLabel,
      });
      if (r['ok'] == true) {
        licCode = code.trim().toUpperCase();
        licTier = r['tier'] as String?;
        licExpiry = r['kedaluwarsa'] != null ? DateTime.tryParse(r['kedaluwarsa'] as String) : null;
        lastCheck = DateTime.now();
        onlineBlocked = false;
        licError = null;
        await _saveLicense(prefs);
        notifyListeners();
        return null;
      }
      return _alasanText(r['alasan'] as String?);
    } catch (_) {
      return 'Tidak ada sambungan internet. Aktivasi butuh internet sekali.';
    }
  }

  String _alasanText(String? alasan) {
    switch (alasan) {
      case 'tidak_terdaftar':
        return 'Kode tidak terdaftar. Periksa lagi ejaan kodenya.';
      case 'dicabut':
        return 'Kode ini sudah dicabut. Hubungi admin lewat WhatsApp.';
      case 'hangus':
        return 'Masa aktif kode ini sudah selesai.';
      case 'dipakai_perangkat_lain':
        return 'Kode ini sudah aktif di HP lain. Satu kode untuk satu HP.';
      case 'terlalu_banyak_percobaan':
        return 'Terlalu banyak percobaan salah. Coba lagi satu jam lagi.';
      default:
        return 'Aktivasi gagal. Coba lagi.';
    }
  }

  Future<void> refreshLicense() async {
    if (licCode == null) return;
    final prefs = await SharedPreferences.getInstance();
    try {
      final r = await _rpc('hookify_cek', {
        'p_kode': licCode,
        'p_device': deviceId,
      });
      if (r['ok'] == true) {
        licTier = r['tier'] as String? ?? licTier;
        if (r['kedaluwarsa'] != null) {
          licExpiry = DateTime.tryParse(r['kedaluwarsa'] as String);
        }
        lastCheck = DateTime.now();
        onlineBlocked = false;
        licError = null;
      } else {
        licError = _alasanText(r['alasan'] as String?);
        if (r['alasan'] == 'dicabut' || r['alasan'] == 'hangus' || r['alasan'] == 'tidak_terdaftar') {
          licCode = null;
          licTier = null;
          licExpiry = null;
          lastCheck = null;
        }
      }
    } catch (_) {
      if (lastCheck != null && DateTime.now().difference(lastCheck!) > offlineTolerance) {
        onlineBlocked = true;
      }
    }
    await _saveLicense(prefs);
    notifyListeners();
  }

  Future<void> consumeTrial() async {
    trialUsed++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('trial_used', trialUsed);
    notifyListeners();
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('history_v1', jsonEncode(history.map((e) => e.toJson()).toList()));
  }

  Future<void> addHistory(ScriptItem item) async {
    history.insert(0, item);
    if (history.length > 50) history.removeRange(50, history.length);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> updateHistoryItem(ScriptItem item) async {
    await _saveHistory();
    notifyListeners();
  }

  Future<void> removeHistory(ScriptItem item) async {
    history.removeWhere((e) => e.id == item.id);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> restoreHistory(ScriptItem item, int index) async {
    history.insert(min(index, history.length), item);
    await _saveHistory();
    notifyListeners();
  }

  Future<void> setLastUsed(String niche, String platform) async {
    lastNiche = niche;
    lastPlatform = platform;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_niche', niche);
    await prefs.setString('last_platform', platform);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
    notifyListeners();
  }
}

// ============================================================================
// EKSPOR BERKAS (.txt dan .docx sungguhan)
// ============================================================================
String _xmlEscape(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

List<int> buildDocxBytes(String text) {
  final paragraphs = text
      .split('\n')
      .map((line) => line.isEmpty
          ? '<w:p/>'
          : '<w:p><w:r><w:t xml:space="preserve">${_xmlEscape(line)}</w:t></w:r></w:p>')
      .join();
  final document = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
      '<w:body>$paragraphs</w:body></w:document>';
  final contentTypes = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
      '<Default Extension="xml" ContentType="application/xml"/>'
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
      '</Types>';
  final rels = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
      '</Relationships>';
  final archive = Archive()
    ..addFile(ArchiveFile('[Content_Types].xml', contentTypes.length, utf8.encode(contentTypes)))
    ..addFile(ArchiveFile('_rels/.rels', rels.length, utf8.encode(rels)))
    ..addFile(ArchiveFile('word/document.xml', document.length, utf8.encode(document)));
  return ZipEncoder().encode(archive);
}

Future<void> shareScriptFile(BuildContext context, ScriptItem item, String format) async {
  try {
    final dir = await getTemporaryDirectory();
    final safeProd = item.prod.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').toLowerCase();
    final base = 'hookify-skrip-$safeProd-${item.id.substring(0, 6)}';
    File file;
    if (format == 'docx') {
      file = File('${dir.path}/$base.docx');
      await file.writeAsBytes(buildDocxBytes(item.fullText));
    } else {
      file = File('${dir.path}/$base.txt');
      await file.writeAsString(item.fullText);
    }
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Skrip Hookify: ${item.prod}',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat berkas: $e')),
      );
    }
  }
}

Future<void> openWhatsAppCheckout(String packageName, String price, String deviceShort) async {
  final message = Uri.encodeComponent(
      'Halo Admin Hookify, saya mau pesan paket *$packageName* seharga *$price*.\nKode perangkat saya: $deviceShort\nMohon panduan pembayarannya, terima kasih.');
  final url = Uri.parse('https://wa.me/$kOwnerWhatsApp?text=$message');
  try {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    await launchUrl(url, mode: LaunchMode.platformDefault);
  }
}
class HookDatabase {
  static const List<String> freeNiches = [
    'Beauty & Skincare',
    'Fashion & Outfit',
    'Kuliner & Snack',
    'Gadget & Tech',
    'Edukasi & Bisnis',
  ];

  static final Map<String, List<String>> allNiches = {
    'Beauty & Skincare': [
      'Sumpah ya, awalnya gue mikir {prodName} ini cuma overhyped doang, tapi pas dicoba...',
      'Stop beli skincare mahal kalau masalah {painPoint} lo belum pernah tuntas pake ini!',
      '3 Kesalahan fatal pas pake {prodName} yang bikin muka lo makin {painPoint}.',
      'Nyesel banget baru tau kalau {painPoint} bisa langsung beres cuma modal {prodName}.',
      'Rahasia MUA ternama ngatasin {painPoint} tanpa perlu perawatan jutaan rupiah.',
      'Jujur, ini penyelamat banget buat kulit yang gampang {painPoint} tiap salah pake produk.',
      'Gara-gara {prodName} ini, orang-orang kantor pada nanyain skincare routine gue sekarang!',
      'Udah coba berbagai cara buat atasin {painPoint}? Coba deh intip trik pakai {prodName} ini.',
    ],
    'Fashion & Outfit': [
      'Jangan pake {prodName} ini kalau lo gak mau ditanyain beli di mana mulu sama temen!',
      'Solusi buat lo yang sering mati gaya gara-gara bingung atasin {painPoint}.',
      'Gaya mahal modal hemat: Cara mix & match {prodName} biar gak keliatan {painPoint}.',
      'Penyelamat pas darurat mau OOTD tapi takut keliatan {painPoint} di badan.',
      'Satu-satunya {prodName} yang wajib ada di lemari lo kalau mau keliatan rapi instan.',
      'Bongkar rahasia tampil stylish seharian tanpa takut {painPoint} mengganggu.',
    ],
    'Kuliner & Snack': [
      'Peringatan! Makanan ini beneran bikin ketagihan dan bikin lupa sama {painPoint}.',
      'Nemuin hidden gem {prodName} yang rasanya beneran di luar nalar enaknya!',
      'Kalau lo lagi ngidam tapi takut {painPoint}, fix wajib banget cobain {prodName} ini.',
      'Jujur, ini pertama kalinya gue nemu {prodName} yang rasanya konsisten gak pernah gagal.',
      'Cobain sensasi {prodName} viral ini, beneran layak beli atau cuma fiktif?',
    ],
    'Gadget & Tech': [
      'Racun gadget minggu ini: {prodName} yang bikin masalah {painPoint} langsung tuntas.',
      'Fitur tersembunyi di {prodName} ini ternyata jarang banget orang tahu!',
      'Mending beli {prodName} daripada lo nyesel belakangan gara-gara {painPoint}.',
      'Review jujur {prodName} setelah 30 hari pemakaian intensif buat ngatasin {painPoint}.',
      'Gak perlu keluar budget mahal, {prodName} ini udah sangat cukup buat atasi {painPoint}.',
    ],
    'Edukasi & Bisnis': [
      'Alasan kenapa keuangan/omzet lo makin {painPoint} kalau gak mulai ubah strategi ini.',
      'Rahasia lepas dari jerat {painPoint} cuma bermodal konsisten pake {prodName}.',
      'Stop lakuin hal ini kalau lo gak mau terus-terusan terjebak di {painPoint}!',
      '3 Cara cerdas memanfaatkan {prodName} biar bisnis lo bebas dari {painPoint}.',
      'Trik simpel ala praktisi bisnis buat nyingkirin {painPoint} dalam waktu singkat.',
    ],
    'Home & Living': [
      'Rumah jadi jauh lebih rapi dan bebas dari {painPoint} cuma gara-gara satu barang ini!',
      'Nyesel banget baru nemu {prodName} ini pas rumah udah terlanjur {painPoint}.',
    ],
    'Kesehatan & Fitness': [
      'Stop maksain tubuh pas lagi {painPoint}, yuk mulai rutinitas sehat pake {prodName}.',
      'Rahasia badan tetap fit dan gak gampang {painPoint} meskipun aktivitas padat.',
    ],
    'Ibu & Anak / Parenting': [
      'Ibu-ibu wajib tau! Solusi paling ampuh pas anak rewel karena {painPoint} ya pakai ini.',
    ],
    'Otomotif & Aksesori': [
      'Kendaraan lo bakal jauh lebih awet dan gak gampang {painPoint} kalau rutin dirawat.',
    ],
    'Buku & Alat Tulis': [
      'Buku/alat tulis yang bener-bener ngerubah cara pandang gue pas ngadepin {painPoint}.',
    ],
    'Travel & Outdoor': [
      'Barang wajib yang harus ada di tas travel biar perjalanan liburan gak berantakan.',
    ],
    'Kebutuhan Anabul / Pets': [
      'Majikan auto nempel terus! Rahasia anabul bebas dari masalah {painPoint}.',
    ],
    'Mainan & Hobi': [
      'Koleksi unik {prodName} yang ampuh banget buat ngusir stres dan rasa bosan.',
    ],
    'Jasa & Layanan Digital': [
      'Cara cerdas memangkas waktu kerja dan bebas dari {painPoint} pakai sistem ini.',
    ],
    'Properti & Real Estate': [
      'Tips punya hunian impian tanpa perlu takut terjebak masalah {painPoint}.',
    ],
  };

  static final List<String> geminiMasterHooks = [
    'Jujur, gue tadinya skeptis banget sama {prodName}. Tapi setelah diuji coba buat ngatasin {painPoint}, hasilnya beneran di luar ekspektasi!',
    'Gak sengaja nemu {prodName} ini di FYP, dan ternyata jadi solusi paling gokil buat nyelesaiin {painPoint} tanpa ribet.',
    'Stop buang-buang waktu cari cara lain! Cukup 1 langkah pakai {prodName}, masalah {painPoint} langsung kelar hari ini juga.',
    'Pantesan produk ini viral di mana-mana. Rahasianya ada di cara kerja {prodName} yang langsung menyerang akar {painPoint}!',
  ];

  static final List<String> shopeeOptimizedHooks = [
    'Bukti nyata! Hasil pemakaian {prodName} selama 3 hari buat basmi {painPoint} beneran keliatan banget.',
    'Nggak usah ragu, {prodName} ini solusi paling worth it buat lo yang capek ngadepin {painPoint}.',
    'Spill produk andalan: {prodName} yang bantu beresin {painPoint} tanpa keluar banyak budget.',
  ];


  static final List<String> patternInterrupt = [
    'Stop scroll sebentar! Video ini khusus dibuat buat lo yang lagi ngadepin {painPoint}.',
    'Jangan diskip dulu! Ada fakta unik dan mengejutkan soal {prodName} yang harus lo tau.',
    'Satu hal krusial yang bikin orang selalu gagal pas berusaha ngatasin {painPoint}.',
    'Pernah gak sih merasa terjebak sama {painPoint}? Coba tonton video ini sampai habis.',
  ];

  static final List<String> urgencyHooks = [
    'Promo {offer} buat {prodName} sisa dikit banget hari ini, jangan sampai kehabisan!',
    'Spill racun checkout paling worth it: {prodName} lagi ngasih penawaran {offer}!',
    'Udah banyak yang ngeborong {prodName} mumpung lagi ada {offer}, lo kapan?',
  ];

  static final List<String> agitations = [
    'Jujur, ngadepin {painPoint} tuh bener-bener bikin ngabisin waktu dan nurunin produktivitas.',
    'Paling kesel gak sih kalau udah coba berbagai cara tapi {painPoint} tetap datang lagi?',
    'Kalau dibiarin terus, masalah {painPoint} ini bakal bikin pengeluaran makin bengkak.',
  ];

  static final List<String> ctaPool = [
    'Mumpung stok masih ada dan promo {offer} aktif, yuk langsung klik keranjang kuning sekarang sebelum kehabisan!',
    'Jangan tunggu sampai sold out ya! Amankan promo {offer} lewat link di bio sekarang juga.',
    'Stok terbatas banget hari ini! Buruan cek keranjang oren sebelum harganya normal kembali.',
    'Siapa di sini yang udah pernah cobain {prodName}? Coba komen jujur pengalaman kalian di bawah ya!',
    'Kira-kira produk apa lagi yang harus kita review jujur? Tulis di kolom komentar ya, jangan lupa tap keranjang!',
    'Buat yang penasaran sama solusi {painPoint}, langsung aja cek detail produknya di keranjang bawah ya.',
    'Yuk mulai beralih dan rasain sendiri perubahannya pakai {prodName}. Klik link di bio untuk info lengkapnya!',
    'Diskon spesial {offer} cuma berlaku hari ini! Jangan sia-siakan kesempatan, langsung checkout sekarang!',
    'Gak usah pikir panjang lagi, langsung bungkus {prodName} sekarang juga mumpung lagi ada penawaran spesial!',
  ];

  static final Map<String, List<String>> captionPool = {
    'Beauty & Skincare': [
      'Gara-gara ini muka jadi mulus lagi! Kalian udah pada cobain belum? Coba komen di bawah ya 👇 #skincareviral #reviewskincare #{prodName}',
      'Pantesan fyp mulu, ternyata emang se-ampuh itu buat ngatasi {painPoint}. Cek keranjang kuning ya! #{prodName} #skincaretiktok',
    ],
    'Fashion & Outfit': [
      'Spill OOTD murah tapi keliatan mahal banget! Dijamin gak bikin dompet jebol. Yuk checkout! #ootdhijab #{prodName} #outfitideas',
      'Solusi buat yang sering bingung pakai baju apa. Modelnya cakep banget dan nyaman dipakai seharian! #gayatiktok #{prodName}',
    ],
    'Kuliner & Snack': [
      'Beneran di luar nalar enaknya! Wajib banget stok ini di rumah biar gak kelaperan. #kulinerviral #{prodName} #snackviral',
    ],
    'Gadget & Tech': [
      'Rekomendasi gadget paling worth it tahun ini buat beresin {painPoint}. Langsung bungkus! #gadgetmurah #{prodName} #techindo',
    ],
    'Edukasi & Bisnis': [
      'Catat baik-baik rumus ini biar gak salah langkah lagi soal {painPoint}. Share ke temen kalian ya! #tipsbisnis #{prodName}',
    ],
    'Home & Living': [
      'Bikin rumah jadi rapi seketika tanpa ribet! Wajib punya satu di rumah. #homehacks #{prodName} #rumahidaman',
    ],
    'Kesehatan & Fitness': [
      'Badan jadi lebih enteng dan fit seharian. Yuk mulai jaga kesehatan dari sekarang! #sehatfit #{prodName}',
    ],
  };

  static Map<String, String> generateScriptData({
    required String niche,
    required String prodName,
    required String painPoint,
    required String offer,
    required String tone,
    required bool isYearlyOrLifetime,
    required String targetPlatform,
    required String customBrandPersona,
    required String aiCreativityLevel,
  }) {
    final random = Random();
    final pool = allNiches[niche] ?? allNiches['Beauty & Skincare']!;
    final capPool = captionPool[niche] ?? captionPool['Beauty & Skincare']!;

    String rawHook1;
    String rawHook2Extra;
    
    if (isYearlyOrLifetime) {
      if (targetPlatform == 'Shopee Video') {
        rawHook1 = shopeeOptimizedHooks[random.nextInt(shopeeOptimizedHooks.length)];
      } else {
        rawHook1 = geminiMasterHooks[random.nextInt(geminiMasterHooks.length)];
      }
      rawHook2Extra = geminiMasterHooks[random.nextInt(geminiMasterHooks.length)];
    } else {
      rawHook1 = pool[random.nextInt(pool.length)];
      rawHook2Extra = patternInterrupt[random.nextInt(patternInterrupt.length)];
    }

    String rawHook2 = rawHook2Extra;
    String rawHook3 = urgencyHooks[random.nextInt(urgencyHooks.length)];
    String rawAgitation = agitations[random.nextInt(agitations.length)];
    String rawCta = ctaPool[random.nextInt(ctaPool.length)];
    String rawCaption = capPool[random.nextInt(capPool.length)];

    if (tone == 'Hard-Selling') {
      rawHook1 = 'BURUAN CHECKOUT SEKARANG! Jangan biarkan {painPoint} bikin rugi terus kalau ada {prodName}!';
    } else if (tone == 'Storytelling Emosional') {
      rawHook1 = 'Dulu aku sempat stres banget gara-gara {painPoint}, sampai akhirnya takdir nemuin aku sama {prodName} ini...';
    }

    if (aiCreativityLevel.contains('High')) {
      rawHook1 = '🔥 [HIGH CONVERSION MODE] $rawHook1';
    }

    if (customBrandPersona.isNotEmpty && isYearlyOrLifetime) {
      rawHook1 = '[$customBrandPersona] $rawHook1';
    }

    final sanitizedProdTag = prodName.isEmpty ? 'ProdukIni' : prodName.replaceAll(RegExp(r'\s+'), '');

    return {
      'hook1': _cleanText(rawHook1, prodName, painPoint, offer),
      'hook2': _cleanText(rawHook2, prodName, painPoint, offer),
      'hook3': _cleanText(rawHook3, prodName, painPoint, offer),
      'agitation': _cleanText(rawAgitation, prodName, painPoint, offer),
      'cta': _cleanText(rawCta, prodName, painPoint, offer),
      'caption': _cleanText(rawCaption, prodName, painPoint, offer)
          .replaceAll('#{prodName}', '#$sanitizedProdTag'),
    };
  }

  static String _cleanText(String template, String prodName, String painPoint, String offer) {
    return template
        .replaceAll('{prodName}', prodName.isEmpty ? 'Produk Ini' : prodName)
        .replaceAll('{painPoint}', painPoint.isEmpty ? 'masalah ini' : painPoint)
        .replaceAll('{offer}', offer.isEmpty ? 'Promo Spesial' : offer);
  }

  static String buildScriptBody({
    required String duration,
    required String prod,
    required String pain,
    required String offer,
    required Map<String, String> data,
    required bool isYearlyOrLifetime,
    required String targetPlatform,
    required String customBrandPersona,
    required String aiCreativityLevel,
    required String customSystemPrompt,
  }) {
    final prodTxt = prod.isEmpty ? 'produk ini' : prod;
    final painTxt = pain.isEmpty ? 'masalah ini' : pain;

    String algorithmicInsight = isYearlyOrLifetime 
        ? '\n📊 [ALGORITHMIC ENGINE OPTIMIZED - $targetPlatform]:\n• Target Retensi Detik Pertama: Dioptimalkan untuk menaikkan Retention & Completion Rate.\n• Saran Visual (0.5s): ${targetPlatform == 'Shopee Video' ? 'Close-up langsung wujud produk & hasil nyata di layar.' : 'Quick movement / zoom-in wajah kaget untuk mencegah swipe.'}\n• Text On-Screen: Gunakan keyword pencarian SEO untuk $prodTxt.' 
        : '';

    String conversionBoosterNote = isYearlyOrLifetime 
        ? '\n💡 [GEMINI MASTER PROMPT ACTIVE]: Skrip diracik dengan psikologi audiens tinggi (~90% Natural Flow)${customBrandPersona.isNotEmpty ? ' | Persona: $customBrandPersona' : ''} | Kreativitas: $aiCreativityLevel${customSystemPrompt.isNotEmpty ? ' | Custom Prompt: $customSystemPrompt' : ''}.$algorithmicInsight' 
        : '';

    switch (duration) {
      case '20 Detik':
        return '''
• [00:00 - 00:03] FAST HOOK (A/B Test 1):
"${data['hook1']}"

• [00:03 - 00:12] PROBLEM & FAST DEMO:
"${data['agitation']} Tapi semenjak gue andelin $prodTxt, masalah $painTxt langsung beres seketika!"

• [00:12 - 00:20] CALL TO ACTION:
"${data['cta']}"
$conversionBoosterNote
''';
      case '60 Detik':
        return '''
• [00:00 - 00:05] HOOK UTAMA (A/B Test 1):
"${data['hook1']}"

• [00:05 - 00:15] AGITATION & EMPATHY:
"${data['agitation']}"

• [00:15 - 00:40] DEEP SOLUTION & DEMO:
"Solusi terbaiknya ada di $prodTxt. Berdasarkan pengalaman nyata, produk ini berhasil merontokkan $painTxt tanpa ribet sama sekali. Hasilnya beneran kerasa!"

• [00:40 - 00:55] SOCIAL PROOF & URGENCY:
"Udah banyak banget yang ngebuktiin sendiri keampuhannya. Jangan tunggu sampai kehabisan stok!"

• [00:55 - 01:00] CALL TO ACTION:
"${data['cta']}"
$conversionBoosterNote
''';
      case '30 Detik':
      default:
        return '''
• [00:00 - 00:03] OPENING HOOK (A/B Test 1):
"${data['hook1']}"

• [00:03 - 00:10] PROBLEM AGITATION:
"${data['agitation']}"

• [00:10 - 00:22] SOLUTION & FEATURE DEMO:
"Untungnya nemu $prodTxt ini. Cara pakainya gampang banget dan langsung ngasih hasil nyata."

• [00:22 - 00:30] CALL TO ACTION:
"${data['cta']}"
$conversionBoosterNote
''';
    }
  }
}


// ============================================================================
// LOGO KAIT (digambar sendiri, dipakai ikon dalam aplikasi + splash)
// ============================================================================
class HookWordmark extends StatelessWidget {
  final double fontSize;
  const HookWordmark({super.key, this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurface;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
          letterSpacing: 0.5,
          color: ink,
        ),
        children: const [
          TextSpan(text: 'HOOKIFY'),
          TextSpan(text: '.', style: TextStyle(color: kLogoRed)),
        ],
      ),
    );
  }
}

// ============================================================================
// KOMPONEN BERSAMA
// ============================================================================
class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB8A98F)
        : kMutedLight;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.4,
        color: muted,
      ),
    );
  }
}

class FlatCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const FlatCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: dark ? kDarkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: dark ? kLineDark : kLineLight),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? null
              : const LinearGradient(colors: [kOrange2, kOrange]),
          color: onPressed == null ? Theme.of(context).disabledColor : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}

void showHookSnack(BuildContext context, String message, {IconData? icon}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: kSuccess, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(child: Text(message)),
        ],
      ),
    ),
  );
}

Future<void> copyWithFeedback(BuildContext context, String text, String label) async {
  await Clipboard.setData(ClipboardData(text: text));
  HapticFeedback.lightImpact();
  if (context.mounted) {
    showHookSnack(context, '$label tersalin', icon: Icons.check_circle);
  }
}

String relativeTime(DateTime ts) {
  final diff = DateTime.now().difference(ts);
  if (diff.inMinutes < 1) return 'baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 7) return '${diff.inDays} hari lalu';
  return '${ts.day}/${ts.month}/${ts.year}';
}

String shortDevice(String deviceId) {
  if (deviceId.length <= 10) return deviceId;
  return '${deviceId.substring(0, 6)}…${deviceId.substring(deviceId.length - 4)}';
}

// ============================================================================
// SPLASH: LOGO ANIMASI DI DEPAN (seperti Osvyn, perintah Master)
// ============================================================================
class SplashGate extends StatefulWidget {
  final AppStore store;
  const SplashGate({super.key, required this.store});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ctrl.forward();
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _done = true);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _splashLetter(String ch, int index, double t, bool disableAnim) {
    final start = index * 0.07;
    final lt = disableAnim ? 1.0 : ((t - start) / 0.35).clamp(0.0, 1.0);
    final e = kCurve.transform(lt);
    return Opacity(
      opacity: e,
      child: Transform.translate(
        offset: Offset(0, 14 * (1 - e)),
        child: Text(
          ch,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 46,
            color: Colors.white,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_done && widget.store.ready) {
      return HomeShell(store: widget.store);
    }
    final disableAnim = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      backgroundColor: kLogoBg,
      body: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = disableAnim ? 1.0 : _ctrl.value;
          final dotT =
              disableAnim ? 1.0 : ((t - 0.62) / 0.3).clamp(0.0, 1.0);
          final dotE = kCurve.transform(dotT);
          final tagT =
              disableAnim ? 1.0 : ((t - 0.72) / 0.28).clamp(0.0, 1.0);
          const word = 'HOOKIFY';
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    for (var i = 0; i < word.length; i++)
                      _splashLetter(word[i], i, t, disableAnim),
                    Opacity(
                      opacity: dotE,
                      child: Transform.scale(
                        scale: 0.4 + 0.6 * dotE,
                        child: const Text(
                          '.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 46,
                            color: kLogoRed,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Opacity(
                  opacity: kCurve.transform(tagT) * 0.85,
                  child: const Text(
                    'Berhenti mikir kalimat pertama sendirian.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF9AA3A8),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ============================================================================
// RANGKA UTAMA: NAVIGASI BAWAH 4 TAB
// ============================================================================
class HomeShell extends StatefulWidget {
  final AppStore store;
  const HomeShell({super.key, required this.store});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (i == _index) return;
    if (MediaQuery.of(context).disableAnimations) {
      _pageController.jumpToPage(i);
    } else {
      _pageController.animateToPage(
        i,
        duration: const Duration(milliseconds: 320),
        curve: kCurve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final pages = [
      BerandaPage(store: widget.store, goGenerator: () => _go(1), goHarga: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => HargaPage(store: widget.store),
        ));
      }),
      GeneratorPage(store: widget.store),
      RiwayatPage(store: widget.store),
      AkunPage(store: widget.store),
    ];
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        children: [
          for (final page in pages) _KeepAlivePage(child: page),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: dark ? kDarkSurface : Colors.white,
          border: Border(top: BorderSide(color: dark ? kLineDark : kLineLight)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Beranda',
                  active: _index == 0,
                  onTap: () => _go(0),
                ),
                _NavItem(
                  icon: Icons.auto_fix_high_outlined,
                  activeIcon: Icons.auto_fix_high,
                  label: 'Generator',
                  active: _index == 1,
                  highlight: true,
                  onTap: () => _go(1),
                ),
                _NavItem(
                  icon: Icons.history_outlined,
                  activeIcon: Icons.history,
                  label: 'Riwayat',
                  active: _index == 2,
                  onTap: () => _go(2),
                ),
                _NavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Akun',
                  active: _index == 3,
                  onTap: () => _go(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final bool highlight;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFB8A98F)
        : kMutedLight;
    final color = active ? kOrange : muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: active ? 1.08 : 1,
              duration: const Duration(milliseconds: 140),
              curve: kCurve,
              child: Icon(active ? activeIcon : icon, color: color, size: 24),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// BERANDA
// ============================================================================
class BerandaPage extends StatelessWidget {
  final AppStore store;
  final VoidCallback goGenerator;
  final VoidCallback goHarga;
  const BerandaPage({
    super.key,
    required this.store,
    required this.goGenerator,
    required this.goHarga,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final last3 = store.history.take(3).toList();
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                children: [
                  const HookWordmark(fontSize: 22),
                  const Spacer(),
                  _StatusChip(store: store, onTap: goHarga),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Kalimat pertama yang\nmenghentikan scroll.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(height: 1.25),
              ),
              const SizedBox(height: 16),
              _QuotaBar(store: store),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Buat Skrip Baru',
                icon: Icons.auto_fix_high,
                onPressed: goGenerator,
              ),
              if (store.onlineBlocked) ...[
                const SizedBox(height: 12),
                _InfoBanner(
                  color: kWarning,
                  text:
                      'Lisensimu perlu cek online sekali. Sambungkan internet lalu buka lagi aplikasi ini.',
                ),
              ],
              if (store.licError != null && store.licCode == null) ...[
                const SizedBox(height: 12),
                _InfoBanner(color: kDanger, text: store.licError!),
              ],
              const SizedBox(height: 24),
              const SectionLabel('Mulai cepat'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _QuickChip(
                    icon: Icons.replay,
                    label: '${store.lastNiche} · ${store.lastPlatform}',
                    onTap: goGenerator,
                  ),
                  _QuickChip(
                    icon: Icons.sell_outlined,
                    label: 'Lihat paket',
                    onTap: goHarga,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionLabel('Terakhir dibuat'),
              const SizedBox(height: 10),
              if (last3.isEmpty)
                FlatCard(
                  child: Column(
                    children: [
                      const HookWordmark(fontSize: 20),
                      const SizedBox(height: 12),
                      const Text(
                        'Belum ada skrip. Racik skrip pertamamu, kalimat pembukanya biar Hookify yang mikir.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: goGenerator,
                        child: const Text('Mulai meracik',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                color: kOrange)),
                      ),
                    ],
                  ),
                )
              else
                ...last3.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HistoryTile(store: store, item: item, compact: true),
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AppStore store;
  final VoidCallback onTap;
  const _StatusChip({required this.store, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final paid = store.isPaid;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: paid ? kSuccess.withOpacity(0.12) : kOrange.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: paid ? kSuccess : kOrange, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(paid ? Icons.verified : Icons.bolt,
                size: 14, color: paid ? kSuccess : kOrange),
            const SizedBox(width: 5),
            Text(
              paid ? store.tierName : 'Mode Trial · ${store.trialLeft} gratis',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: paid ? kSuccess : kOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuotaBar extends StatelessWidget {
  final AppStore store;
  const _QuotaBar({required this.store});

  @override
  Widget build(BuildContext context) {
    if (store.isPaid) {
      if (store.licTier == 'LIFE') {
        return const Row(
          children: [
            Icon(Icons.all_inclusive, size: 16, color: kSuccess),
            SizedBox(width: 6),
            Text('Tanpa batas, selamanya',
                style: TextStyle(fontWeight: FontWeight.w600, color: kSuccess)),
          ],
        );
      }
      final totalDays = store.licTier == 'YR' ? 365 : 30;
      final left = store.licExpiry!.difference(DateTime.now()).inDays;
      final frac = (left / totalDays).clamp(0.0, 1.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sisa masa aktif: $left hari',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: frac),
              duration: const Duration(milliseconds: 600),
              curve: kCurve,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: Theme.of(context).dividerColor,
                valueColor: const AlwaysStoppedAnimation<Color>(kOrange),
              ),
            ),
          ),
        ],
      );
    }
    final usedFrac = (store.trialUsed / kTrialLimit).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mode Trial: ${store.trialLeft} dari $kTrialLimit skrip gratis tersisa',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: usedFrac),
            duration: const Duration(milliseconds: 600),
            curve: kCurve,
            builder: (_, v, __) => LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: const AlwaysStoppedAnimation<Color>(kOrange),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final Color color;
  final String text;
  const _InfoBanner({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ActionChip(
      avatar: Icon(icon, size: 16, color: kOrange),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: dark ? kDarkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: dark ? kLineDark : kLineLight),
      ),
    );
  }
}

// ============================================================================
// GENERATOR
// ============================================================================
class GeneratorPage extends StatefulWidget {
  final AppStore store;
  const GeneratorPage({super.key, required this.store});

  @override
  State<GeneratorPage> createState() => _GeneratorPageState();
}

class _GeneratorPageState extends State<GeneratorPage> {
  final _prod = TextEditingController();
  final _pain = TextEditingController();
  final _offer = TextEditingController();
  final _persona = TextEditingController();
  final _customPrompt = TextEditingController();

  String _niche = 'Beauty & Skincare';
  String _platform = 'TikTok Video';
  String _duration = '30 Detik';
  String _tone = 'Soft-Selling Edukatif';
  String _creativity = 'Normal (Balanced)';
  bool _advancedOpen = false;
  bool _generating = false;
  String _stageText = '';
  String? _prodError;
  String? _painError;
  int _placeholderIdx = 0;
  Timer? _placeholderTimer;

  static const _platforms = ['TikTok Video', 'Instagram Reels', 'YouTube Shorts', 'Shopee Video'];
  static const _durations = ['20 Detik', '30 Detik', '60 Detik'];
  static const _toneLabels = {
    'Soft-Selling Edukatif': 'Santai',
    'Hard-Selling': 'Hard Selling',
    'Storytelling Emosional': 'Storytelling',
  };
  static const _creativityOptions = [
    'Normal (Balanced)',
    'High Conversion (Agresif)',
    'Storyteller (Emosional)',
  ];
  static const _painExamples = {
    'Beauty & Skincare': 'jerawat yang balik lagi',
    'Fashion & Outfit': 'baju kelihatan murah pas dipakai',
    'Kuliner & Snack': 'cemilan cepat bikin enek',
    'Gadget & Tech': 'baterai boros banget',
    'Edukasi & Bisnis': 'omzet stuck di situ-situ aja',
  };

  @override
  void initState() {
    super.initState();
    _niche = widget.store.lastNiche;
    _platform = widget.store.lastPlatform;
    _placeholderTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _placeholderIdx++);
    });
  }

  @override
  void dispose() {
    _placeholderTimer?.cancel();
    _prod.dispose();
    _pain.dispose();
    _offer.dispose();
    _persona.dispose();
    _customPrompt.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final store = widget.store;
    setState(() {
      _prodError = _prod.text.trim().isEmpty ? 'Nama produk belum diisi' : null;
      _painError = _pain.text.trim().isEmpty ? 'Masalah penonton belum diisi' : null;
    });
    if (_prodError != null || _painError != null) return;

    if (!store.isPaid && store.trialLeft <= 0) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => HargaPage(
          store: store,
          contextMessage:
              'Kamu sudah membuat $kTrialLimit skrip. Lanjutkan tanpa batas:',
        ),
      ));
      return;
    }
    if (store.isPaid && store.onlineBlocked) {
      showHookSnack(context, 'Lisensi perlu cek online sekali. Sambungkan internet dulu.');
      return;
    }
    if (store.licCode != null && !store.isPaid) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => HargaPage(store: store, contextMessage: 'Masa aktif paketmu sudah selesai. Perpanjang di sini:'),
      ));
      return;
    }

    HapticFeedback.lightImpact();
    final stages = ['Memilih hook…', 'Meracik agitasi…', 'Menyusun CTA…', 'Menulis caption…'];
    setState(() {
      _generating = true;
      _stageText = stages[0];
    });
    for (var i = 1; i < stages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _stageText = stages[i]);
    }

    final premium = store.isPremium;
    final data = HookDatabase.generateScriptData(
      niche: _niche,
      prodName: _prod.text.trim(),
      painPoint: _pain.text.trim(),
      offer: _offer.text.trim(),
      tone: _tone,
      isYearlyOrLifetime: premium,
      targetPlatform: _platform,
      customBrandPersona: premium ? _persona.text.trim() : '',
      aiCreativityLevel: premium ? _creativity : 'Normal (Balanced)',
    );
    final item = ScriptItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      ts: DateTime.now(),
      niche: _niche,
      platform: _platform,
      duration: _duration,
      tone: _tone,
      prod: _prod.text.trim(),
      pain: _pain.text.trim(),
      offer: _offer.text.trim(),
      premium: premium,
      persona: premium ? _persona.text.trim() : '',
      creativity: premium ? _creativity : 'Normal (Balanced)',
      customPrompt: premium ? _customPrompt.text.trim() : '',
      data: data,
      body: '',
    );
    item.recompose();

    if (!store.isPaid) await store.consumeTrial();
    await store.setLastUsed(_niche, _platform);
    await store.addHistory(item);

    if (!mounted) return;
    setState(() => _generating = false);
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultPage(store: store, item: item),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final niches = HookDatabase.allNiches.keys.toList();
    final painHint = _painExamples[_niche] ?? 'masalah yang dihadapi penontonmu';
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return SafeArea(
          child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                children: [
                  Text('Generator', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  const Text('Isi produkmu, Hookify racik kalimat pertamanya.'),
                  const SizedBox(height: 20),
                  const SectionLabel('Produk'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _prod,
                    decoration: InputDecoration(
                      labelText: 'Nama produk',
                      hintText: 'cth. Serum Brightening X',
                      errorText: _prodError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pain,
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Masalah penonton (pain point)',
                      hintText: 'cth. $painHint',
                      errorText: _painError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _offer,
                    decoration: InputDecoration(
                      labelText: 'Penawaran (opsional)',
                      hintText: 'cth. Diskon 50% + Gratis Ongkir',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('Niche'),
                  const SizedBox(height: 10),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 46,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: niches.length,
                    itemBuilder: (_, i) {
                      final n = niches[i];
                      final selected = n == _niche;
                      return _SelectChip(
                        label: n,
                        selected: selected,
                        onTap: () => setState(() => _niche = n),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('Platform'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _platforms
                        .map((p) => _SelectChip(
                              label: p.replaceAll(' Video', ''),
                              selected: p == _platform,
                              onTap: () => setState(() => _platform = p),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('Durasi'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: _durations
                        .map((d) => _SelectChip(
                              label: d,
                              selected: d == _duration,
                              onTap: () => setState(() => _duration = d),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel('Tone'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _toneLabels.entries
                        .map((e) => _SelectChip(
                              label: e.value,
                              selected: e.key == _tone,
                              onTap: () => setState(() => _tone = e.key),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 22),
                  InkWell(
                    onTap: () => setState(() => _advancedOpen = !_advancedOpen),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          const SectionLabel('Pengaturan lanjutan'),
                          const SizedBox(width: 6),
                          if (!store.isPremium)
                            const Icon(Icons.lock, size: 14, color: kOrange),
                          const Spacer(),
                          AnimatedRotation(
                            turns: _advancedOpen ? 0.5 : 0,
                            duration: const Duration(milliseconds: 220),
                            curve: kCurve,
                            child: const Icon(Icons.expand_more, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: store.isPremium
                          ? Column(
                              children: [
                                TextField(
                                  controller: _persona,
                                  decoration: InputDecoration(
                                    labelText: 'Persona brand (opsional)',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _creativity,
                                  decoration: InputDecoration(
                                    labelText: 'Level kreativitas',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                  items: _creativityOptions
                                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _creativity = v ?? _creativity),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _customPrompt,
                                  maxLines: 2,
                                  decoration: InputDecoration(
                                    labelText: 'Instruksi khusus (opsional)',
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            )
                          : const _InfoBanner(
                              color: kOrange,
                              text:
                                  'Persona brand, level kreativitas, dan instruksi khusus terbuka di paket Pro Tahunan dan Agency Lifetime.',
                            ),
                    ),
                    crossFadeState:
                        _advancedOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 220),
                    sizeCurve: kCurve,
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PrimaryButton(
                      label: _generating ? 'Meracik…' : 'Racik Skrip',
                      icon: Icons.auto_fix_high,
                      onPressed: _generating ? null : _generate,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      store.isPaid
                          ? 'Paket ${store.tierName} aktif'
                          : 'Gratis selama masa trial · tersisa ${store.trialLeft}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (_generating)
                Positioned.fill(
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.92),
                    child: Center(
                      child: FlatCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HookWordmark(fontSize: 18),
                            const SizedBox(height: 14),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: Text(_stageText,
                                  key: ValueKey(_stageText),
                                  style: const TextStyle(
                                      fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 6),
                            const Text('Skripmu sedang disusun per bagian.'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: kCurve,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? kOrange.withOpacity(0.14)
              : (dark ? kDarkSurface : Colors.white),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? kOrange : (dark ? kLineDark : kLineLight),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? kOrange : null,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// RACIK ULANG PER BAGIAN (mengikuti distribusi pool generator asli)
// ============================================================================
String rerollSection(ScriptItem item, String section) {
  final rnd = Random();
  String pick(List<String> pool) => pool[rnd.nextInt(pool.length)];
  String raw;
  switch (section) {
    case 'hook1':
      if (item.premium) {
        raw = item.platform == 'Shopee Video'
            ? pick(HookDatabase.shopeeOptimizedHooks)
            : pick(HookDatabase.geminiMasterHooks);
      } else {
        raw = pick(HookDatabase.allNiches[item.niche] ??
            HookDatabase.allNiches['Beauty & Skincare']!);
      }
      if (item.creativity.contains('High')) {
        raw = '🔥 [HIGH CONVERSION MODE] $raw';
      }
      if (item.persona.isNotEmpty && item.premium) {
        raw = '[${item.persona}] $raw';
      }
      break;
    case 'hook2':
      raw = item.premium
          ? pick(HookDatabase.geminiMasterHooks)
          : pick(HookDatabase.patternInterrupt);
      break;
    case 'hook3':
      raw = pick(HookDatabase.urgencyHooks);
      break;
    case 'agitation':
      raw = pick(HookDatabase.agitations);
      break;
    case 'cta':
      raw = pick(HookDatabase.ctaPool);
      break;
    case 'caption':
      raw = pick(HookDatabase.captionPool[item.niche] ??
          HookDatabase.captionPool['Beauty & Skincare']!);
      final tag = item.prod.isEmpty
          ? 'ProdukIni'
          : item.prod.replaceAll(RegExp(r'\s+'), '');
      return HookDatabase._cleanText(raw, item.prod, item.pain, item.offer)
          .replaceAll('#{prodName}', '#$tag');
    default:
      raw = '';
  }
  return HookDatabase._cleanText(raw, item.prod, item.pain, item.offer);
}

// ============================================================================
// HASIL SKRIP
// ============================================================================
class ResultPage extends StatefulWidget {
  final AppStore store;
  final ScriptItem item;
  const ResultPage({super.key, required this.store, required this.item});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  Future<void> _reroll(String section) async {
    HapticFeedback.selectionClick();
    setState(() {
      widget.item.data[section] = rerollSection(widget.item, section);
      widget.item.recompose();
    });
    await widget.store.updateHistoryItem(widget.item);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hasil Skrip'),
        actions: [
          IconButton(
            icon: Icon(
              item.fav ? Icons.star : Icons.star_border,
              color: item.fav ? kOrange2 : null,
            ),
            onPressed: () async {
              setState(() => item.fav = !item.fav);
              await widget.store.updateHistoryItem(item);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: kSuccess, size: 16),
              const SizedBox(width: 6),
              Text('Tersimpan di Riwayat · ${item.niche} · ${item.platform}',
                  style: const TextStyle(fontSize: 12.5)),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            label: 'HOOK',
            hero: true,
            text: item.data['hook1'] ?? '',
            onCopy: () => copyWithFeedback(context, item.data['hook1'] ?? '', 'Hook'),
            onShuffle: () => _reroll('hook1'),
          ),
          _SectionCard(
            label: 'Hook alternatif 1',
            text: item.data['hook2'] ?? '',
            onCopy: () => copyWithFeedback(context, item.data['hook2'] ?? '', 'Hook alternatif'),
            onShuffle: () => _reroll('hook2'),
          ),
          _SectionCard(
            label: 'Hook alternatif 2',
            text: item.data['hook3'] ?? '',
            onCopy: () => copyWithFeedback(context, item.data['hook3'] ?? '', 'Hook alternatif'),
            onShuffle: () => _reroll('hook3'),
          ),
          _SectionCard(
            label: 'Agitasi',
            text: item.data['agitation'] ?? '',
            onCopy: () => copyWithFeedback(context, item.data['agitation'] ?? '', 'Agitasi'),
            onShuffle: () => _reroll('agitation'),
          ),
          _SectionCard(
            label: 'CTA',
            text: item.data['cta'] ?? '',
            onCopy: () => copyWithFeedback(context, item.data['cta'] ?? '', 'CTA'),
            onShuffle: () => _reroll('cta'),
          ),
          _SectionCard(
            label: 'Caption & hashtag',
            text: item.data['caption'] ?? '',
            onCopy: () => copyWithFeedback(context, item.data['caption'] ?? '', 'Caption'),
            onShuffle: () => _reroll('caption'),
          ),
          const SizedBox(height: 8),
          const SectionLabel('Skrip lengkap (dengan timing)'),
          const SizedBox(height: 10),
          FlatCard(
            child: SelectableText(
              item.body.trim(),
              style: const TextStyle(fontFamily: 'Inter', fontSize: 14, height: 1.55),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                label: 'Salin Semua',
                icon: Icons.copy_all,
                onPressed: () => copyWithFeedback(context, item.fullText, 'Seluruh skrip'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.description_outlined, size: 17),
                      label: const Text('.txt'),
                      onPressed: () => shareScriptFile(context, item, 'txt'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.article_outlined, size: 17),
                      label: const Text('Word'),
                      onPressed: () => shareScriptFile(context, item, 'docx'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share_outlined, size: 17),
                      label: const Text('Bagikan'),
                      onPressed: () async {
                        await Share.share(
                          item.fullText,
                          subject: 'Skrip Hookify: ${item.prod}',
                        );
                      },
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

class _SectionCard extends StatelessWidget {
  final String label;
  final String text;
  final bool hero;
  final VoidCallback onCopy;
  final VoidCallback onShuffle;
  const _SectionCard({
    required this.label,
    required this.text,
    required this.onCopy,
    required this.onShuffle,
    this.hero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FlatCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.3,
                    color: hero ? kOrange : null,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.shuffle, size: 18),
                  tooltip: 'Ganti bagian ini',
                  onPressed: onShuffle,
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.content_copy, size: 18),
                  tooltip: 'Salin',
                  onPressed: onCopy,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            SelectableText(
              text,
              style: hero
                  ? const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      height: 1.35,
                    )
                  : const TextStyle(fontFamily: 'Inter', fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// RIWAYAT
// ============================================================================
class _HistoryTile extends StatelessWidget {
  final AppStore store;
  final ScriptItem item;
  final bool compact;
  const _HistoryTile({required this.store, required this.item, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return FlatCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ResultPage(store: store, item: item),
        ));
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.prod,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    if (item.fav)
                      const Icon(Icons.star, size: 15, color: kOrange2),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.niche} · ${item.platform} · ${item.duration} · ${relativeTime(item.ts)}',
                  style: const TextStyle(fontSize: 11.5),
                ),
                const SizedBox(height: 5),
                Text(
                  item.data['hook1'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.content_copy, size: 18),
            tooltip: 'Salin skrip',
            onPressed: () => copyWithFeedback(context, item.fullText, 'Skrip'),
          ),
        ],
      ),
    );
  }
}

class RiwayatPage extends StatefulWidget {
  final AppStore store;
  const RiwayatPage({super.key, required this.store});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  String _query = '';
  String _platformFilter = 'Semua';
  bool _favOnly = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final all = widget.store.history;
        final filtered = all.where((item) {
          if (_favOnly && !item.fav) return false;
          if (_platformFilter != 'Semua' && item.platform != _platformFilter) return false;
          if (_query.isNotEmpty) {
            final q = _query.toLowerCase();
            final hay = '${item.prod} ${item.niche} ${item.data['hook1']}'.toLowerCase();
            if (!hay.contains(q)) return false;
          }
          return true;
        }).toList();
        return SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Riwayat', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setState(() => _query = v),
                      decoration: InputDecoration(
                        hintText: 'Cari produk, niche, atau hook…',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...['Semua', 'TikTok Video', 'Instagram Reels', 'YouTube Shorts', 'Shopee Video']
                              .map((p) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: _SelectChip(
                                      label: p.replaceAll(' Video', ''),
                                      selected: p == _platformFilter,
                                      onTap: () => setState(() => _platformFilter = p),
                                    ),
                                  )),
                          _SelectChip(
                            label: 'Favorit',
                            selected: _favOnly,
                            onTap: () => setState(() => _favOnly = !_favOnly),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: all.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Belum ada riwayat. Skrip yang kamu racik akan tersimpan di sini dan tidak hilang walau aplikasi ditutup.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'Tidak ada hasil untuk pencarian ini. Coba kata kunci atau saringan lain.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final item = filtered[i];
                              final realIndex = all.indexOf(item);
                              return Dismissible(
                                key: ValueKey(item.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 18),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: kDanger,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: const Icon(Icons.delete, color: Colors.white),
                                ),
                                onDismissed: (_) async {
                                  await widget.store.removeHistory(item);
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).clearSnackBars();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Skrip dihapus'),
                                      duration: const Duration(seconds: 4),
                                      action: SnackBarAction(
                                        label: 'Urungkan',
                                        textColor: kOrange2,
                                        onPressed: () =>
                                            widget.store.restoreHistory(item, realIndex),
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _HistoryTile(store: widget.store, item: item),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// HARGA & AKTIVASI
// ============================================================================
class HargaPage extends StatefulWidget {
  final AppStore store;
  final String? contextMessage;
  const HargaPage({super.key, required this.store, this.contextMessage});

  @override
  State<HargaPage> createState() => _HargaPageState();
}

class _HargaPageState extends State<HargaPage>
    with SingleTickerProviderStateMixin {
  final _code = TextEditingController();
  bool _activating = false;
  String? _error;
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _code.dispose();
    _shake.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (_code.text.trim().isEmpty) {
      setState(() => _error = 'Kolom kode masih kosong.');
      _shake.forward(from: 0);
      return;
    }
    setState(() {
      _activating = true;
      _error = null;
    });
    final err = await widget.store.activate(_code.text);
    if (!mounted) return;
    setState(() => _activating = false);
    if (err == null) {
      HapticFeedback.lightImpact();
      showHookSnack(context, 'Paket ${widget.store.tierName} aktif. Selamat meracik!',
          icon: Icons.check_circle);
      Navigator.of(context).pop();
    } else {
      setState(() => _error = err);
      _shake.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    return Scaffold(
      appBar: AppBar(title: const Text('Harga & Aktivasi')),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (widget.contextMessage != null) ...[
                Text(widget.contextMessage!,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w500)),
                const SizedBox(height: 14),
              ],
              _PackageCard(
                store: store,
                tier: 'MON',
                name: 'Starter',
                price: 'Rp29 rb',
                period: '/bulan',
                features: const [
                  'Generate tanpa batas selama aktif',
                  'Semua 15 niche terbuka',
                  'Riwayat tersimpan 50 skrip',
                  'Ekspor berkas .txt dan Word',
                ],
                onChoose: () => openWhatsAppCheckout(
                    'Starter (Bulanan)', 'Rp29.000', shortDevice(store.deviceId)),
              ),
              _PackageCard(
                store: store,
                tier: 'YR',
                name: 'Pro Tahunan',
                price: 'Rp99 rb',
                period: '/tahun',
                popular: true,
                features: const [
                  'Semua fitur Starter',
                  'Pool hook premium (Master & Shopee)',
                  'Persona brand + level kreativitas',
                  'Instruksi khusus per skrip',
                ],
                onChoose: () => openWhatsAppCheckout(
                    'Pro Tahunan', 'Rp99.000', shortDevice(store.deviceId)),
              ),
              _PackageCard(
                store: store,
                tier: 'LIFE',
                name: 'Agency Lifetime',
                price: 'Rp199 rb',
                period: 'sekali bayar',
                badge: 'Selamanya',
                features: const [
                  'Semua fitur Pro Tahunan',
                  'Sekali bayar, aktif selamanya',
                  'Paling pas untuk jualan jasa konten',
                ],
                onChoose: () => openWhatsAppCheckout(
                    'Agency Lifetime', 'Rp199.000', shortDevice(store.deviceId)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Cara pesan: ketuk paketnya, WhatsApp terbuka dengan pesan otomatis berisi paket dan kode perangkatmu. Kirim, bayar, lalu kamu menerima kode aktivasi.',
                style: TextStyle(fontSize: 12.5),
              ),
              const SizedBox(height: 24),
              const SectionLabel('Sudah punya kode?'),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _shake,
                builder: (context, child) {
                  final dx = sin(_shake.value * pi * 4) * 8 * (1 - _shake.value);
                  return Transform.translate(offset: Offset(dx, 0), child: child);
                },
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'HOOK-XXXX-XXXX-XXXX',
                    errorText: _error,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.key_outlined, size: 20),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: _activating ? 'Memeriksa…' : 'Aktifkan',
                icon: Icons.lock_open,
                onPressed: _activating ? null : _activate,
              ),
              const SizedBox(height: 24),
              const SectionLabel('Contoh hasil asli'),
              const SizedBox(height: 10),
              _ExampleScriptCard(),
              const SizedBox(height: 16),
              const Text(
                'Satu kode aktif di satu HP. Pindah HP? Chat admin lewat WhatsApp dengan kode perangkat lama dan barumu, lisensimu dipindahkan manual.',
                style: TextStyle(fontSize: 12.5),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final AppStore store;
  final String tier;
  final String name;
  final String price;
  final String period;
  final List<String> features;
  final bool popular;
  final String? badge;
  final VoidCallback onChoose;
  const _PackageCard({
    required this.store,
    required this.tier,
    required this.name,
    required this.price,
    required this.period,
    required this.features,
    required this.onChoose,
    this.popular = false,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final active = store.isPaid && store.licTier == tier;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: dark ? kDarkSurface : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: active
                ? kSuccess
                : popular
                    ? kOrange
                    : (dark ? kLineDark : kLineLight),
            width: active || popular ? 1.6 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(name,
                    style: const TextStyle(
                        fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16)),
                const Spacer(),
                if (active)
                  _MiniBadge(text: 'Aktif', color: kSuccess)
                else if (popular)
                  _MiniBadge(text: 'Paling Laris', color: kOrange)
                else if (badge != null)
                  _MiniBadge(text: badge!, color: kOrange2),
              ],
            ),
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                children: [
                  TextSpan(
                    text: price,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  TextSpan(text: ' $period', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 16, color: kSuccess),
                      const SizedBox(width: 7),
                      Expanded(child: Text(f, style: const TextStyle(fontSize: 13.5))),
                    ],
                  ),
                )),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: active
                  ? OutlinedButton(
                      onPressed: null,
                      child: const Text('Paketmu saat ini'),
                    )
                  : PrimaryButton(
                      label: 'Pilih Paket Ini',
                      onPressed: onChoose,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  final Color color;
  const _MiniBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ExampleScriptCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = HookDatabase.generateScriptData(
      niche: 'Beauty & Skincare',
      prodName: 'Serum Brightening',
      painPoint: 'jerawat yang balik lagi',
      offer: 'Diskon 50%',
      tone: 'Soft-Selling Edukatif',
      isYearlyOrLifetime: false,
      targetPlatform: 'TikTok Video',
      customBrandPersona: '',
      aiCreativityLevel: 'Normal (Balanced)',
    );
    return FlatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Hook'),
          const SizedBox(height: 6),
          Text('"${data['hook1']}"',
              style: const TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 15.5)),
          const SizedBox(height: 10),
          const SectionLabel('Agitasi'),
          const SizedBox(height: 6),
          Text('"${data['agitation']}"'),
          const SizedBox(height: 10),
          const SectionLabel('Caption'),
          const SizedBox(height: 6),
          Text('"${data['caption']}"'),
        ],
      ),
    );
  }
}

// ============================================================================
// AKUN
// ============================================================================
class AkunPage extends StatelessWidget {
  final AppStore store;
  const AkunPage({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HookWordmark(fontSize: 20),
                      Text(
                        store.isPaid ? 'Paket ${store.tierName}' : 'Mode Trial',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SectionLabel('Status paket'),
              const SizedBox(height: 10),
              FlatCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuotaBar(store: store),
                    if (store.isPaid && store.licExpiry != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        store.licTier == 'LIFE'
                            ? 'Aktif selamanya'
                            : 'Berlaku sampai ${store.licExpiry!.day}/${store.licExpiry!.month}/${store.licExpiry!.year}',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ],
                    if (store.onlineBlocked) ...[
                      const SizedBox(height: 10),
                      const _InfoBanner(
                        color: kWarning,
                        text: 'Perlu cek online sekali. Sambungkan internet lalu ketuk Cek Ulang.',
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.refresh, size: 17),
                            label: const Text('Cek Ulang'),
                            onPressed: () async {
                              await store.refreshLicense();
                              if (context.mounted) {
                                showHookSnack(context, 'Status lisensi diperbarui',
                                    icon: Icons.check_circle);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.sell_outlined, size: 17),
                            label: const Text('Harga'),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => HargaPage(store: store),
                              ));
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionLabel('Kode perangkat'),
              const SizedBox(height: 10),
              FlatCard(
                child: Row(
                  children: [
                    const Icon(Icons.phone_android_outlined, size: 20, color: kOrange),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shortDevice(store.deviceId),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, letterSpacing: 1)),
                          if (store.deviceLabel.isNotEmpty)
                            Text(store.deviceLabel, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_copy, size: 19),
                      onPressed: () =>
                          copyWithFeedback(context, store.deviceId, 'Kode perangkat'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionLabel('Tampilan'),
              const SizedBox(height: 10),
              Row(
                children: [
                  _SelectChip(
                    label: 'Ikut Sistem',
                    selected: store.themeMode == ThemeMode.system,
                    onTap: () => store.setThemeMode(ThemeMode.system),
                  ),
                  const SizedBox(width: 8),
                  _SelectChip(
                    label: 'Terang',
                    selected: store.themeMode == ThemeMode.light,
                    onTap: () => store.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _SelectChip(
                    label: 'Gelap',
                    selected: store.themeMode == ThemeMode.dark,
                    onTap: () => store.setThemeMode(ThemeMode.dark),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SectionLabel('Bantuan'),
              const SizedBox(height: 10),
              FlatCard(
                onTap: () async {
                  final msg = Uri.encodeComponent(
                      'Halo Admin Hookify, saya butuh bantuan. Kode perangkat saya: ${shortDevice(store.deviceId)}');
                  final url = Uri.parse('https://wa.me/$kOwnerWhatsApp?text=$msg');
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                },
                child: const Row(
                  children: [
                    Icon(Icons.chat_outlined, size: 20, color: kOrange),
                    SizedBox(width: 10),
                    Expanded(child: Text('Chat admin lewat WhatsApp')),
                    Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text('Hookify versi 3.0.0',
                    style: TextStyle(fontSize: 12, color: kMutedLight)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
// AKAR APLIKASI
// ============================================================================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HookifyApp());
}

class HookifyApp extends StatefulWidget {
  const HookifyApp({super.key});

  @override
  State<HookifyApp> createState() => _HookifyAppState();
}

class _HookifyAppState extends State<HookifyApp> {
  final AppStore _store = AppStore();

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Hookify',
          theme: buildHookifyTheme(Brightness.light),
          darkTheme: buildHookifyTheme(Brightness.dark),
          themeMode: _store.themeMode,
          home: SplashGate(store: _store),
        );
      },
    );
  }
}
