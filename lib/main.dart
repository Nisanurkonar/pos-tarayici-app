import 'dart:convert';
import 'dart:typed_data';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String apiKey = '';
const String modelName = 'google/gemini-2.5-flash-lite';

void main() {
  runApp(const PosTarayiciApp());
}

// =====================================================
// ANA UYGULAMA
// =====================================================

class PosTarayiciApp extends StatelessWidget {
  const PosTarayiciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POS Fiş Tarayıcı',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        useMaterial3: true,
      ),
      home: const FisTarayiciEkrani(),
    );
  }
}

// =====================================================
// FİŞ MODELİ
// =====================================================

class FisModel {
  final String magaza;
  final String tarih;
  final double kdvOrani;
  final double kdvsizTutar;
  final double kdvTutari;
  final double kdvliTutar;
  final String ozet;

  FisModel({
    required this.magaza,
    required this.tarih,
    required this.kdvOrani,
    required this.kdvsizTutar,
    required this.kdvTutari,
    required this.kdvliTutar,
    required this.ozet,
  });

  Map<String, dynamic> toJson() {
    return {
      'magaza': magaza,
      'tarih': tarih,
      'kdvOrani': kdvOrani,
      'kdvsizTutar': kdvsizTutar,
      'kdvTutari': kdvTutari,
      'kdvliTutar': kdvliTutar,
      'ozet': ozet,
    };
  }

  factory FisModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return FisModel(
      magaza:
          json['magaza']?.toString() ??
              'Bilinmiyor',
      tarih:
          json['tarih']?.toString() ??
              'Bilinmiyor',
      kdvOrani:
          (json['kdvOrani'] as num?)
                  ?.toDouble() ??
              0.0,
      kdvsizTutar:
          (json['kdvsizTutar'] as num?)
                  ?.toDouble() ??
              0.0,
      kdvTutari:
          (json['kdvTutari'] as num?)
                  ?.toDouble() ??
              0.0,
      kdvliTutar:
          (json['kdvliTutar'] as num?)
                  ?.toDouble() ??
              0.0,
      ozet:
          json['ozet']?.toString() ??
              '',
    );
  }

  FisModel copyWith({
    String? magaza,
    String? tarih,
    double? kdvOrani,
    double? kdvsizTutar,
    double? kdvTutari,
    double? kdvliTutar,
    String? ozet,
  }) {
    return FisModel(
      magaza:
          magaza ?? this.magaza,
      tarih:
          tarih ?? this.tarih,
      kdvOrani:
          kdvOrani ?? this.kdvOrani,
      kdvsizTutar:
          kdvsizTutar ??
              this.kdvsizTutar,
      kdvTutari:
          kdvTutari ??
              this.kdvTutari,
      kdvliTutar:
          kdvliTutar ??
              this.kdvliTutar,
      ozet:
          ozet ?? this.ozet,
    );
  }
}

// =====================================================
// FİŞ TARAYICI EKRANI
// =====================================================

class FisTarayiciEkrani
    extends StatefulWidget {
  const FisTarayiciEkrani({
    super.key,
  });

  @override
  State<FisTarayiciEkrani>
      createState() =>
          _FisTarayiciEkraniState();
}

class _FisTarayiciEkraniState
    extends State<FisTarayiciEkrani> {
  Uint8List? _secilenResimBytes;

  final ImagePicker _picker =
      ImagePicker();

  bool _yukleniyor = false;

  final List<FisModel>
      _tarananFisler = [];

  // Analiz edilmiş fakat henüz kaydedilmemiş fiş
  FisModel? _bekleyenFis;

  // Yeni taranan fiş düzenleme modu
  bool _bekleyenFisDuzenleniyor =
      false;

  // Kaydedilmiş fiş düzenleme modu
  int? _duzenlenenKayitIndex;

  // Yeni fiş düzenleme alanları
  final TextEditingController
      _bekleyenMagazaController =
      TextEditingController();

  final TextEditingController
      _bekleyenTarihController =
      TextEditingController();

  final TextEditingController
      _bekleyenKdvOraniController =
      TextEditingController();

  final TextEditingController
      _bekleyenKdvsizController =
      TextEditingController();

  final TextEditingController
      _bekleyenKdvliController =
      TextEditingController();

  final TextEditingController
      _bekleyenOzetController =
      TextEditingController();

  // Kaydedilmiş fiş düzenleme alanları
  final TextEditingController
      _kayitliMagazaController =
      TextEditingController();

  final TextEditingController
      _kayitliTarihController =
      TextEditingController();

  final TextEditingController
      _kayitliKdvOraniController =
      TextEditingController();

  final TextEditingController
      _kayitliKdvsizController =
      TextEditingController();

  final TextEditingController
      _kayitliKdvliController =
      TextEditingController();

  final TextEditingController
      _kayitliOzetController =
      TextEditingController();

  static const String
      _kayitAnahtari =
      'kayitli_fisler';

  @override
  void initState() {
    super.initState();
    _kayitliFisleriYukle();
  }

  @override
  void dispose() {
    _bekleyenMagazaController.dispose();
    _bekleyenTarihController.dispose();
    _bekleyenKdvOraniController.dispose();
    _bekleyenKdvsizController.dispose();
    _bekleyenKdvliController.dispose();
    _bekleyenOzetController.dispose();

    _kayitliMagazaController.dispose();
    _kayitliTarihController.dispose();
    _kayitliKdvOraniController.dispose();
    _kayitliKdvsizController.dispose();
    _kayitliKdvliController.dispose();
    _kayitliOzetController.dispose();

    super.dispose();
  }

  // =====================================================
  // KAYITLI FİŞLERİ YÜKLE
  // =====================================================

  Future<void> _kayitliFisleriYukle() async {
    try {
      final prefs =
          await SharedPreferences
              .getInstance();

      final kayitlar =
          prefs.getStringList(
                _kayitAnahtari,
              ) ??
              [];

      final fisler =
          <FisModel>[];

      for (final kayit
          in kayitlar) {
        try {
          final map =
              jsonDecode(kayit);

          if (map
              is Map<String, dynamic>) {
            fisler.add(
              FisModel.fromJson(map),
            );
          }
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        _tarananFisler
          ..clear()
          ..addAll(fisler);
      });
    } catch (e) {
      debugPrint(
        'Fiş kayıtları yüklenemedi: $e',
      );
    }
  }

  // =====================================================
  // KALICI KAYDET
  // =====================================================

  Future<void>
      _fisleriKaliciKaydet() async {
    try {
      final prefs =
          await SharedPreferences
              .getInstance();

      final kayitlar =
          _tarananFisler
              .map(
                (fis) => jsonEncode(
                  fis.toJson(),
                ),
              )
              .toList();

      await prefs.setStringList(
        _kayitAnahtari,
        kayitlar,
      );
    } catch (e) {
      debugPrint(
        'Fişler kaydedilemedi: $e',
      );
    }
  }

  // =====================================================
  // SAYI PARSE
  // =====================================================

  double _parseSayi(
    String value,
  ) {
    var temiz =
        value
            .replaceAll('₺', '')
            .replaceAll('TL', '')
            .replaceAll('tl', '')
            .replaceAll('%', '')
            .trim();

    if (temiz.contains(',') &&
        temiz.contains('.')) {
      temiz = temiz
          .replaceAll('.', '')
          .replaceAll(',', '.');
    } else {
      temiz =
          temiz.replaceAll(',', '.');
    }

    return double.tryParse(
          temiz,
        ) ??
        0.0;
  }

  // =====================================================
  // KDV ORANI HESAPLA
  // =====================================================

  double _kdvOraniHesapla(
    double kdvli,
    double kdvsiz,
  ) {
    if (kdvli <= 0 ||
        kdvsiz <= 0) {
      return 0.0;
    }

    return ((kdvli - kdvsiz) /
            kdvsiz) *
        100;
  }

  // =====================================================
  // KDV'SİZ HESAPLA
  // =====================================================

  double _kdvsizTutarHesapla(
    double kdvli,
    double oran,
  ) {
    if (kdvli <= 0 ||
        oran < 0) {
      return 0.0;
    }

    return kdvli /
        (1 + oran / 100);
  }

  // =====================================================
  // KDV'Lİ HESAPLA
  // =====================================================

  double _kdvliTutarHesapla(
    double kdvsiz,
    double oran,
  ) {
    if (kdvsiz <= 0 ||
        oran < 0) {
      return 0.0;
    }

    return kdvsiz *
        (1 + oran / 100);
  }

  // =====================================================
  // KDV TUTARI
  // =====================================================

  double _kdvTutariHesapla(
    double kdvli,
    double kdvsiz,
  ) {
    if (kdvli <= 0 ||
        kdvsiz <= 0) {
      return 0.0;
    }

    final sonuc =
        kdvli - kdvsiz;

    return sonuc < 0
        ? 0.0
        : sonuc;
  }

  // =====================================================
  // PARA
  // =====================================================

  String _para(double tutar) {
    return '${tutar.toStringAsFixed(2)} ₺';
  }

  // =====================================================
  // MIME TYPE
  // =====================================================

  String _getMimeType(
    Uint8List bytes,
  ) {
    if (bytes.length >= 2 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8) {
      return 'image/jpeg';
    }

    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }

    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'image/webp';
    }

    return 'image/jpeg';
  }

  // =====================================================
  // RESİM SEÇ
  // =====================================================

  Future<void> _resimSec(
    ImageSource source,
  ) async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        return;
      }

      final bytes =
          await pickedFile.readAsBytes();

      setState(() {
        _secilenResimBytes = bytes;
        _bekleyenFis = null;
        _bekleyenFisDuzenleniyor =
            false;
      });
    } catch (e) {
      _hataDiyalogGoster(
        'Resim Seçim Hatası',
        e.toString(),
      );
    }
  }

  // =====================================================
  // FİŞ ANALİZİ
  // =====================================================

  Future<void> _fisAnalizEt() async {
    if (_secilenResimBytes ==
        null) {
      _hataDiyalogGoster(
        'Resim Yok',
        'Lütfen önce bir fiş resmi seçin.',
      );
      return;
    }

    final cleanApiKey =
        apiKey.trim();

    if (cleanApiKey.isEmpty ||
        cleanApiKey ==
            'BURAYA_OPENROUTER_API_KEYINIZI_YAZIN') {
      _hataDiyalogGoster(
        'API Key Eksik',
        'Lütfen OpenRouter API keyinizi kodun başındaki alana yazın.',
      );
      return;
    }

    setState(() {
      _yukleniyor = true;
      _bekleyenFis = null;
      _bekleyenFisDuzenleniyor =
          false;
    });

    try {
      final base64Image =
          base64Encode(
        _secilenResimBytes!,
      );

      final detectedMime =
          _getMimeType(
        _secilenResimBytes!,
      );

      final url = Uri.parse(
        'https://openrouter.ai/api/v1/chat/completions',
      );

      const promptText = '''
Bu bir alışveriş/POS fişidir.

Fişteki bilgileri dikkatlice oku.

SADECE geçerli JSON döndür.
Başka hiçbir açıklama yazma.
Markdown kullanma.
```json kullanma.

JSON formatı:

{
  "magaza": "Mağaza veya firma adı",
  "tarih": "DD.MM.YYYY",
  "kdvOrani": 20.0,
  "kdvliTutar": 0.00,
  "kdvsizTutar": 0.00,
  "kdvTutari": 0.00,
  "ozet": "X kalem ürün"
}

KURALLAR:

1. magaza:
Fişte yazan mağaza veya firma adını yaz.

2. tarih:
Fişteki işlem tarihini DD.MM.YYYY formatında yaz.

3. kdvOrani:
Fişte açıkça belirtilen KDV oranını bul.

Örneğin:
%20 → 20.0
%10 → 10.0
%1 → 1.0

KDV oranı açıkça yazmıyorsa ama KDV dahil ve KDV hariç toplam
bulunabiliyorsa şu formülle hesapla:

kdvOrani = ((kdvliTutar - kdvsizTutar) / kdvsizTutar) * 100

KDV oranını tahmin etme.
Hesaplayamıyorsan 0.0 yaz.

4. kdvliTutar:
Fişte müşterinin ödediği GENEL TOPLAM tutarı bul.

Fişte açıkça bulunmuyorsa:
KDV hariç toplam ve KDV oranı bulunabiliyorsa hesapla:

kdvliTutar = kdvsizTutar * (1 + kdvOrani / 100)

Sadece sayı kullan.
₺ veya TL yazma.

5. kdvsizTutar:
Fişte açıkça KDV hariç toplam varsa onu kullan.

Fişte açıkça bulunmuyorsa:
KDV dahil toplam ve KDV oranı bulunabiliyorsa hesapla:

kdvsizTutar = kdvliTutar / (1 + kdvOrani / 100)

6. kdvTutari:
KDV dahil toplam ile KDV hariç toplam arasındaki farkı yaz.

Formül:

kdvTutari = kdvliTutar - kdvsizTutar

7. ozet:
Fişteki ürün/kalem sayısını kısa şekilde belirt.

Örneğin:
"5 kalem ürün"

8. Bilgi okunamıyorsa tahmin etme.

Mümkünse fişteki ürün satırları, ara toplam,
genel toplam, KDV tutarı ve diğer sayısal
bilgiler arasındaki matematiksel ilişkiyi
kullanarak eksik değerleri hesapla.

9. Toplam tutar hesaplanamıyorsa:
0.00

10. Tarih okunamıyorsa:
"Bilinmiyor"

11. Mağaza adı okunamıyorsa:
"Bilinmiyor"

12. Sayısal alanlarda virgül yerine nokta kullan.
Örneğin:
245,90 → 245.90
''';

      final requestBody =
          jsonEncode({
        'model': modelName,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': promptText,
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url':
                      'data:$detectedMime;base64,$base64Image',
                },
              },
            ],
          },
        ],
        'max_tokens': 500,
        'reasoning': {
          'max_tokens': 0,
        },
        'temperature': 0.1,
        'response_format': {
          'type': 'json_object',
        },
      });

      final response =
          await http.post(
        url,
        headers: {
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer $cleanApiKey',
          'HTTP-Referer':
              'http://localhost',
          'X-Title':
              'POS Fis Tarayici',
        },
        body: requestBody,
      );

      if (response.statusCode !=
          200) {
        throw Exception(
          'API Hatası: ${response.statusCode}\n${response.body}',
        );
      }

      final data =
          jsonDecode(response.body);

      final choices =
          data['choices'];

      if (choices == null ||
          choices.isEmpty) {
        throw Exception(
          'API boş cevap döndürdü.',
        );
      }

      String rawText =
          choices[0]['message']
                      ['content']
                  ?.toString() ??
              '';

      rawText =
          rawText.trim();

      if (rawText.startsWith(
        '```json',
      )) {
        rawText =
            rawText.substring(7);
      } else if (rawText.startsWith(
        '```',
      )) {
        rawText =
            rawText.substring(3);
      }

      if (rawText.endsWith(
        '```',
      )) {
        rawText =
            rawText.substring(
          0,
          rawText.length - 3,
        );
      }

      rawText =
          rawText.trim();

      final parsedMap =
          jsonDecode(rawText);

      final String magaza =
          parsedMap['magaza']
                  ?.toString() ??
              'Bilinmiyor';

      final String tarih =
          parsedMap['tarih']
                  ?.toString() ??
              'Bilinmiyor';

      final String ozet =
          parsedMap['ozet']
                  ?.toString() ??
              '';

      double kdvOrani =
          _parseSayi(
        parsedMap['kdvOrani']
                ?.toString() ??
            '0',
      );

      double kdvliTutar =
          _parseSayi(
        parsedMap['kdvliTutar']
                ?.toString() ??
            '0',
      );

      double kdvsizTutar =
          _parseSayi(
        parsedMap['kdvsizTutar']
                ?.toString() ??
            '0',
      );

      if (kdvOrani <= 0 &&
          kdvliTutar > 0 &&
          kdvsizTutar > 0) {
        kdvOrani =
            _kdvOraniHesapla(
          kdvliTutar,
          kdvsizTutar,
        );
      }

      if (kdvsizTutar <= 0 &&
          kdvliTutar > 0 &&
          kdvOrani > 0) {
        kdvsizTutar =
            _kdvsizTutarHesapla(
          kdvliTutar,
          kdvOrani,
        );
      }

      if (kdvliTutar <= 0 &&
          kdvsizTutar > 0 &&
          kdvOrani > 0) {
        kdvliTutar =
            _kdvliTutarHesapla(
          kdvsizTutar,
          kdvOrani,
        );
      }

      final kdvTutari =
          _kdvTutariHesapla(
        kdvliTutar,
        kdvsizTutar,
      );

      final yeniFis =
          FisModel(
        magaza: magaza,
        tarih: tarih,
        kdvOrani: kdvOrani,
        kdvsizTutar:
            kdvsizTutar,
        kdvTutari:
            kdvTutari,
        kdvliTutar:
            kdvliTutar,
        ozet: ozet,
      );

      if (!mounted) return;

      setState(() {
        _bekleyenFis =
            yeniFis;

        _bekleyenFisDuzenleniyor =
            false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Fiş analiz edildi. Kaydetmeden önce bilgileri kontrol edebilirsiniz.',
          ),
        ),
      );
    } catch (e) {
      _hataDiyalogGoster(
        'Analiz Hatası',
        e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _yukleniyor = false;
        });
      }
    }
  }

  // =====================================================
  // YENİ FİŞ DÜZENLEME ALANLARINI DOLDUR
  // =====================================================

  void _bekleyenFisiDuzenlemeyeAc() {
    if (_bekleyenFis == null) {
      return;
    }

    final fis =
        _bekleyenFis!;

    _bekleyenMagazaController
        .text = fis.magaza;

    _bekleyenTarihController
        .text = fis.tarih;

    _bekleyenKdvOraniController
        .text =
        fis.kdvOrani.toString();

    _bekleyenKdvsizController
        .text =
        fis.kdvsizTutar
            .toStringAsFixed(2);

    _bekleyenKdvliController
        .text =
        fis.kdvliTutar
            .toStringAsFixed(2);

    _bekleyenOzetController
        .text = fis.ozet;

    setState(() {
      _bekleyenFisDuzenleniyor =
          true;
    });
  }

  // =====================================================
  // YENİ FİŞ DÜZENLEMEYİ İPTAL
  // =====================================================

  void _bekleyenDuzenlemeyiIptalEt() {
    setState(() {
      _bekleyenFisDuzenleniyor =
          false;
    });
  }

  // =====================================================
  // YENİ FİŞ DEĞİŞİKLİKLERİNİ UYGULA
  // =====================================================

  void _bekleyenFisDegisiklikleriniUygula() {
    if (_bekleyenFis == null) {
      return;
    }

    double kdvOrani =
        _parseSayi(
      _bekleyenKdvOraniController
          .text,
    );

    double kdvsizTutar =
        _parseSayi(
      _bekleyenKdvsizController
          .text,
    );

    double kdvliTutar =
        _parseSayi(
      _bekleyenKdvliController
          .text,
    );

    // Eksik tutarı hesapla
    if (kdvliTutar <= 0 &&
        kdvsizTutar > 0 &&
        kdvOrani > 0) {
      kdvliTutar =
          _kdvliTutarHesapla(
        kdvsizTutar,
        kdvOrani,
      );
    }

    if (kdvsizTutar <= 0 &&
        kdvliTutar > 0 &&
        kdvOrani > 0) {
      kdvsizTutar =
          _kdvsizTutarHesapla(
        kdvliTutar,
        kdvOrani,
      );
    }

    // Oran eksikse iki tutardan hesapla
    if (kdvOrani <= 0 &&
        kdvliTutar > 0 &&
        kdvsizTutar > 0) {
      kdvOrani =
          _kdvOraniHesapla(
        kdvliTutar,
        kdvsizTutar,
      );
    }

    final kdvTutari =
        _kdvTutariHesapla(
      kdvliTutar,
      kdvsizTutar,
    );

    setState(() {
      _bekleyenFis =
          _bekleyenFis!.copyWith(
        magaza:
            _bekleyenMagazaController
                    .text
                    .trim()
                    .isEmpty
                ? 'Bilinmiyor'
                : _bekleyenMagazaController
                    .text
                    .trim(),
        tarih:
            _bekleyenTarihController
                    .text
                    .trim()
                    .isEmpty
                ? 'Bilinmiyor'
                : _bekleyenTarihController
                    .text
                    .trim(),
        kdvOrani:
            kdvOrani,
        kdvsizTutar:
            kdvsizTutar,
        kdvTutari:
            kdvTutari,
        kdvliTutar:
            kdvliTutar,
        ozet:
            _bekleyenOzetController
                .text
                .trim(),
      );

      _bekleyenFisDuzenleniyor =
          false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Değişiklikler uygulandı. Fiş henüz kaydedilmedi.',
        ),
      ),
    );
  }

  // =====================================================
  // BEKLEYEN FİŞİ KAYDET
  // =====================================================

  Future<void>
      _bekleyenFisiKaydet() async {
    if (_bekleyenFis == null) {
      return;
    }

    final fis =
        _bekleyenFis!;

    setState(() {
      _tarananFisler.insert(
        0,
        fis,
      );

      _bekleyenFis = null;

      _bekleyenFisDuzenleniyor =
          false;
    });

    await _fisleriKaliciKaydet();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Fiş başarıyla kaydedildi.',
        ),
      ),
    );
  }

  // =====================================================
  // KAYITLI FİŞİ DÜZENLEMEYE AÇ
  // =====================================================

  void _kayitliFisiDuzenlemeyeAc(
    int index,
  ) {
    if (index < 0 ||
        index >= _tarananFisler.length) {
      return;
    }

    final fis =
        _tarananFisler[index];

    _kayitliMagazaController
        .text = fis.magaza;

    _kayitliTarihController
        .text = fis.tarih;

    _kayitliKdvOraniController
        .text =
        fis.kdvOrani.toString();

    _kayitliKdvsizController
        .text =
        fis.kdvsizTutar
            .toStringAsFixed(2);

    _kayitliKdvliController
        .text =
        fis.kdvliTutar
            .toStringAsFixed(2);

    _kayitliOzetController
        .text = fis.ozet;

    setState(() {
      _duzenlenenKayitIndex =
          index;
    });
  }

  // =====================================================
  // KAYITLI FİŞ DÜZENLEMEYİ İPTAL
  // =====================================================

  void _kayitliDuzenlemeyiIptalEt() {
    setState(() {
      _duzenlenenKayitIndex =
          null;
    });
  }

  // =====================================================
  // KAYITLI FİŞ DEĞİŞİKLİKLERİNİ KAYDET
  // =====================================================

  Future<void>
      _kayitliFisDegisiklikleriniKaydet() async {
    final index =
        _duzenlenenKayitIndex;

    if (index == null ||
        index < 0 ||
        index >= _tarananFisler.length) {
      return;
    }

    double kdvOrani =
        _parseSayi(
      _kayitliKdvOraniController
          .text,
    );

    double kdvsizTutar =
        _parseSayi(
      _kayitliKdvsizController
          .text,
    );

    double kdvliTutar =
        _parseSayi(
      _kayitliKdvliController
          .text,
    );

    if (kdvliTutar <= 0 &&
        kdvsizTutar > 0 &&
        kdvOrani > 0) {
      kdvliTutar =
          _kdvliTutarHesapla(
        kdvsizTutar,
        kdvOrani,
      );
    }

    if (kdvsizTutar <= 0 &&
        kdvliTutar > 0 &&
        kdvOrani > 0) {
      kdvsizTutar =
          _kdvsizTutarHesapla(
        kdvliTutar,
        kdvOrani,
      );
    }

    if (kdvOrani <= 0 &&
        kdvliTutar > 0 &&
        kdvsizTutar > 0) {
      kdvOrani =
          _kdvOraniHesapla(
        kdvliTutar,
        kdvsizTutar,
      );
    }

    final kdvTutari =
        _kdvTutariHesapla(
      kdvliTutar,
      kdvsizTutar,
    );

    final guncelFis =
        _tarananFisler[index]
            .copyWith(
      magaza:
          _kayitliMagazaController
                  .text
                  .trim()
                  .isEmpty
              ? 'Bilinmiyor'
              : _kayitliMagazaController
                  .text
                  .trim(),
      tarih:
          _kayitliTarihController
                  .text
                  .trim()
                  .isEmpty
              ? 'Bilinmiyor'
              : _kayitliTarihController
                  .text
                  .trim(),
      kdvOrani:
          kdvOrani,
      kdvsizTutar:
          kdvsizTutar,
      kdvTutari:
          kdvTutari,
      kdvliTutar:
          kdvliTutar,
      ozet:
          _kayitliOzetController
              .text
              .trim(),
    );

    setState(() {
      _tarananFisler[index] =
          guncelFis;

      _duzenlenenKayitIndex =
          null;
    });

    await _fisleriKaliciKaydet();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Fiş bilgileri güncellendi.',
        ),
      ),
    );
  }

  // =====================================================
  // TEK FİŞ SİL
  // =====================================================

  Future<void> _fisSil(
    int index,
  ) async {
    if (index < 0 ||
        index >= _tarananFisler.length) {
      return;
    }

    final fis =
        _tarananFisler[index];

    final bool? onay =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Fişi Sil',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: Text(
            '${fis.magaza} fişini silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text(
                'Vazgeç',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              style:
                  FilledButton
                      .styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Sil',
              ),
            ),
          ],
        );
      },
    );

    if (onay != true) {
      return;
    }

    setState(() {
      _tarananFisler
          .removeAt(index);
    });

    await _fisleriKaliciKaydet();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Fiş başarıyla silindi.',
        ),
      ),
    );
  }

  // =====================================================
  // TÜM FİŞLERİ SİL
  // =====================================================

  Future<void>
      _fisleriTemizle() async {
    if (_tarananFisler
        .isEmpty) {
      return;
    }

    final bool? onay =
        await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Tüm Fişleri Sil',
            style: TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content: Text(
            'Kayıtlı olan ${_tarananFisler.length} adet fişin tamamını silmek istediğinize emin misiniz?\n\nBu işlem geri alınamaz.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text(
                'Vazgeç',
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              style:
                  FilledButton
                      .styleFrom(
                backgroundColor:
                    Colors.red,
                foregroundColor:
                    Colors.white,
              ),
              child:
                  const Text(
                'Tümünü Sil',
              ),
            ),
          ],
        );
      },
    );

    if (onay != true) {
      return;
    }

    setState(() {
      _tarananFisler.clear();
      _bekleyenFis = null;
      _secilenResimBytes = null;
      _bekleyenFisDuzenleniyor =
          false;
    });

    await _fisleriKaliciKaydet();

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Tüm fişler başarıyla silindi.',
        ),
      ),
    );
  }

  // =====================================================
  // CSV HÜCRESİ
  // =====================================================

  String _csvHucre(
    String value,
  ) {
    return '"${value.replaceAll('"', '""')}"';
  }

  // =====================================================
  // CSV OLUŞTUR
  // =====================================================

  String _tarananFislerCsvOlustur() {
    final satirlar =
        <String>[
      'Mağaza,Tarih,KDV Oranı,KDV\'siz Tutar,KDV Tutarı,KDV\'li Toplam,Özet',
    ];

    for (final fis
        in _tarananFisler) {
      satirlar.add(
        [
          _csvHucre(fis.magaza),
          _csvHucre(fis.tarih),
          _csvHucre(
            '%${fis.kdvOrani.toStringAsFixed(0)}',
          ),
          _csvHucre(
            fis.kdvsizTutar
                .toStringAsFixed(2),
          ),
          _csvHucre(
            fis.kdvTutari
                .toStringAsFixed(2),
          ),
          _csvHucre(
            fis.kdvliTutar
                .toStringAsFixed(2),
          ),
          _csvHucre(fis.ozet),
        ].join(','),
      );
    }

    return '\uFEFF${satirlar.join('\r\n')}';
  }

  // =====================================================
  // CSV İNDİR
  // =====================================================

  void _tarananFislerDosyasiniIndir() {
    if (_tarananFisler
        .isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Henüz kaydedilmiş fiş bulunmuyor.',
          ),
        ),
      );
      return;
    }

    final csv =
        _tarananFislerCsvOlustur();

    final blob = web.Blob(
      <JSAny>[
        csv.toJS,
      ].toJS,
      web.BlobPropertyBag(
        type:
            'text/csv;charset=utf-8',
      ),
    );

    final url =
        web.URL.createObjectURL(
      blob,
    );

    final anchor =
        web.HTMLAnchorElement()
          ..href = url
          ..download =
              'Taranan_Fisler.csv'
          ..style.display =
              'none';

    web.document.body
        ?.append(anchor);

    anchor.click();
    anchor.remove();

    web.URL.revokeObjectURL(
      url,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      const SnackBar(
        content: Text(
          'Taranan_Fisler.csv dosyası indirildi.',
        ),
      ),
    );
  }

  // =====================================================
  // KÜMÜLATİF TOPLAMLAR
  // =====================================================

  double get _kumulatifKdvsizToplam {
    return _tarananFisler.fold(
      0.0,
      (toplam, fis) =>
          toplam +
          fis.kdvsizTutar,
    );
  }

  double get _kumulatifKdvToplam {
    return _tarananFisler.fold(
      0.0,
      (toplam, fis) =>
          toplam +
          fis.kdvTutari,
    );
  }

  double get _kumulatifKdvliToplam {
    return _tarananFisler.fold(
      0.0,
      (toplam, fis) =>
          toplam +
          fis.kdvliTutar,
    );
  }

  // =====================================================
  // HATA DİYALOĞU
  // =====================================================

  void _hataDiyalogGoster(
    String baslik,
    String mesaj,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            baslik,
            style:
                const TextStyle(
              color: Colors.red,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
          content:
              SingleChildScrollView(
            child:
                SelectableText(mesaj),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child:
                  const Text(
                'Tamam',
              ),
            ),
          ],
        );
      },
    );
  }

  // =====================================================
  // BEKLEYEN FİŞ GÖRÜNÜMÜ
  // =====================================================

  Widget _bekleyenFisWidget() {
    if (_bekleyenFis == null) {
      return const SizedBox.shrink();
    }

    if (_bekleyenFisDuzenleniyor) {
      return _bekleyenFisDuzenlemeWidget();
    }

    final fis =
        _bekleyenFis!;

    return Card(
      color: Colors.amber.shade50,
      elevation: 3,
      child: Padding(
        padding:
            const EdgeInsets.all(
          14,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons
                      .pending_actions,
                  color:
                      Colors.orange,
                ),
                const SizedBox(
                  width: 8,
                ),
                const Expanded(
                  child: Text(
                    'Kontrol Edilecek Fiş',
                    style:
                        TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Colors.orange,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors
                        .orange
                        .shade100,
                    borderRadius:
                        BorderRadius
                            .circular(
                      8,
                    ),
                  ),
                  child:
                      const Text(
                    'Henüz kaydedilmedi',
                    style:
                        TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight
                              .bold,
                      color:
                          Colors.orange,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 12,
            ),

            const Divider(),

            const SizedBox(
              height: 6,
            ),

            _bilgiSatiri(
              'Mağaza / Firma',
              fis.magaza,
            ),

            const SizedBox(
              height: 8,
            ),

            _bilgiSatiri(
              'Tarih',
              fis.tarih,
            ),

            const SizedBox(
              height: 8,
            ),

            _bilgiSatiri(
              'KDV Oranı',
              '%${fis.kdvOrani.toStringAsFixed(0)}',
            ),

            const SizedBox(
              height: 8,
            ),

            _bilgiSatiri(
              "KDV'siz Tutar",
              _para(
                fis.kdvsizTutar,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            _bilgiSatiri(
              'KDV Tutarı',
              _para(
                fis.kdvTutari,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            _bilgiSatiri(
              "KDV'li Tutar",
              _para(
                fis.kdvliTutar,
              ),
            ),

            if (fis.ozet.isNotEmpty) ...[
              const SizedBox(
                height: 8,
              ),
              _bilgiSatiri(
                'Özet',
                fis.ozet,
              ),
            ],

            const SizedBox(
              height: 14,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton
                          .icon(
                    onPressed:
                        _bekleyenFisiDuzenlemeyeAc,
                    icon:
                        const Icon(
                      Icons.edit,
                    ),
                    label:
                        const Text(
                      'Düzenle',
                    ),
                    style:
                        OutlinedButton
                            .styleFrom(
                      foregroundColor:
                          Colors
                              .teal,
                    ),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                Expanded(
                  child:
                      FilledButton
                          .icon(
                    onPressed:
                        _bekleyenFisiKaydet,
                    icon:
                        const Icon(
                      Icons.save,
                    ),
                    label:
                        const Text(
                      'Kaydet',
                    ),
                    style:
                        FilledButton
                            .styleFrom(
                      backgroundColor:
                          Colors
                              .teal,
                      foregroundColor:
                          Colors
                              .white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 8,
            ),

            SizedBox(
              width:
                  double.infinity,
              child:
                  TextButton.icon(
                onPressed: () {
                  setState(() {
                    _bekleyenFis =
                        null;
                    _bekleyenFisDuzenleniyor =
                        false;
                  });
                },
                icon:
                    const Icon(
                  Icons.close,
                ),
                label:
                    const Text(
                  'Kaydetmeden Vazgeç',
                ),
                style:
                    TextButton
                        .styleFrom(
                  foregroundColor:
                      Colors
                          .redAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // BEKLEYEN FİŞ DÜZENLEME EKRANI
  // =====================================================

  Widget _bekleyenFisDuzenlemeWidget() {
    return Card(
      elevation: 4,
      color: Colors.teal.shade50,
      child: Padding(
        padding:
            const EdgeInsets.all(
          14,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.edit,
                  color:
                      Colors.teal,
                ),
                const SizedBox(
                  width: 8,
                ),
                const Expanded(
                  child: Text(
                    'Fiş Bilgilerini Düzenle',
                    style:
                        TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Colors.teal,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            _duzenlemeAlani(
              'Mağaza / Firma',
              _bekleyenMagazaController,
              Icons.store,
            ),

            const SizedBox(
              height: 10,
            ),

            _duzenlemeAlani(
              'Tarih',
              _bekleyenTarihController,
              Icons.calendar_today,
            ),

            const SizedBox(
              height: 10,
            ),

            _duzenlemeAlani(
              'KDV Oranı (%)',
              _bekleyenKdvOraniController,
              Icons.percent,
              sayisal: true,
            ),

            const SizedBox(
              height: 10,
            ),

            _duzenlemeAlani(
              "KDV'siz Tutar",
              _bekleyenKdvsizController,
              Icons.receipt_long,
              sayisal: true,
            ),

            const SizedBox(
              height: 10,
            ),

            _duzenlemeAlani(
              "KDV'li Tutar",
              _bekleyenKdvliController,
              Icons.payments,
              sayisal: true,
            ),

            const SizedBox(
              height: 10,
            ),

            _duzenlemeAlani(
              'Özet',
              _bekleyenOzetController,
              Icons.notes,
              maxLines: 2,
            ),

            const SizedBox(
              height: 14,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton(
                    onPressed:
                        _bekleyenDuzenlemeyiIptalEt,
                    child:
                        const Text(
                      'İptal',
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child:
                      FilledButton
                          .icon(
                    onPressed:
                        _bekleyenFisDegisiklikleriniUygula,
                    icon:
                        const Icon(
                      Icons.check,
                    ),
                    label:
                        const Text(
                      'Değişiklikleri Uygula',
                    ),
                    style:
                        FilledButton
                            .styleFrom(
                      backgroundColor:
                          Colors
                              .teal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // KAYITLI FİŞ DÜZENLEME EKRANI
  // =====================================================

  Widget _kayitliFisDuzenlemeWidget(
    int index,
  ) {
    return Card(
      elevation: 4,
      color: Colors.blueGrey
          .shade50,
      child: Padding(
        padding:
            const EdgeInsets.all(
          14,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment
                  .start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.edit,
                  color:
                      Colors.blueGrey,
                ),
                const SizedBox(
                  width: 8,
                ),
                const Expanded(
                  child: Text(
                    'Kayıtlı Fişi Düzenle',
                    style:
                        TextStyle(
                      fontSize: 18,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Colors
                              .blueGrey,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(
              height: 14,
            ),

            _duzenlemeAlani(
              'Mağaza / Firma',
              _kayitliMagazaController,
              Icons.store,
            ),

            const SizedBox(
              height: 10,
            ),

            _duzenlemeAlani(
              'Tarih',
              _kayitliTarihController,
              Icons.calendar_today,
            ),

            const SizedBox(
              height: 10,
            ),

            _duzenlemeAlani(
              'KDV Oranı (%)',
              _kayitliKdvOraniController,
              Icons.percent,
              sayisal: true,
            ),

            const SizedBox(
              height: 10,
            ),

            _duzenlemeAlani(
              "KDV'siz Tutar",
              _kayitliKdvsizController,
              Icons.receipt_long,
              sayisal: true,
            ),

            const SizedBox(
              height: 10,
            ),

            _duzenlemeAlani(
              "KDV'li Tutar",
              _kayitliKdvliController,
              Icons.payments,
              sayisal: true,
            ),

            const SizedBox(
              height: 10,
            ),

            _duzenlemeAlani(
              'Özet',
              _kayitliOzetController,
              Icons.notes,
              maxLines: 2,
            ),

            const SizedBox(
              height: 14,
            ),

            Row(
              children: [
                Expanded(
                  child:
                      OutlinedButton(
                    onPressed:
                        _kayitliDuzenlemeyiIptalEt,
                    child:
                        const Text(
                      'İptal',
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child:
                      FilledButton
                          .icon(
                    onPressed:
                        _kayitliFisDegisiklikleriniKaydet,
                    icon:
                        const Icon(
                      Icons.save,
                    ),
                    label:
                        const Text(
                      'Değişiklikleri Kaydet',
                    ),
                    style:
                        FilledButton
                            .styleFrom(
                      backgroundColor:
                          Colors
                              .teal,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // DÜZENLEME ALANI
  // =====================================================

  Widget _duzenlemeAlani(
    String label,
    TextEditingController
        controller,
    IconData icon, {
    bool sayisal = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: sayisal
          ? const TextInputType
              .numberWithOptions(
              decimal: true,
            )
          : TextInputType.text,
      decoration:
          InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon),
        border:
            const OutlineInputBorder(),
      ),
    );
  }

  // =====================================================
  // BİLGİ SATIRI
  // =====================================================

  Widget _bilgiSatiri(
    String baslik,
    String deger,
  ) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment
              .spaceBetween,
      children: [
        Text(
          baslik,
          style:
              const TextStyle(
            color: Colors.grey,
          ),
        ),
        Flexible(
          child: Text(
            deger,
            textAlign:
                TextAlign.right,
            style:
                const TextStyle(
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'POS Fiş Tarayıcı',
        ),
        backgroundColor:
            Colors.teal,
        foregroundColor:
            Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip:
                'Taranan Fişler Dosyasını İndir',
            onPressed:
                _tarananFislerDosyasiniIndir,
            icon:
                const Icon(
              Icons.file_download,
            ),
          ),
          if (_tarananFisler
              .isNotEmpty)
            IconButton(
              tooltip:
                  'Fişleri Temizle',
              onPressed:
                  _fisleriTemizle,
              icon:
                  const Icon(
                Icons.delete_sweep,
              ),
            ),
        ],
      ),

      body: Column(
        children: [
          // =================================================
          // TOPLAM BİLGİSİ
          // =================================================

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets
                    .all(16),
            color:
                Colors.teal.shade50,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        const Text(
                          'KÜMÜLATİF TOPLAM',
                          style:
                              TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight
                                    .bold,
                            color:
                                Colors
                                    .teal,
                          ),
                        ),
                        Text(
                          '${_tarananFisler.length} Adet Fiş',
                          style:
                              TextStyle(
                            fontSize: 12,
                            color: Colors
                                .grey
                                .shade700,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _para(
                        _kumulatifKdvliToplam,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight
                                .bold,
                        color:
                            Colors.teal,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 10,
                ),

                const Divider(),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    const Text(
                      "KDV'siz Toplam",
                    ),
                    Text(
                      _para(
                        _kumulatifKdvsizToplam,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 6,
                ),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    const Text(
                      'KDV Toplamı',
                    ),
                    Text(
                      _para(
                        _kumulatifKdvToplam,
                      ),
                      style:
                          const TextStyle(
                        color:
                            Colors.orange,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 6,
                ),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,
                  children: [
                    const Text(
                      "KDV'li Toplam",
                    ),
                    Text(
                      _para(
                        _kumulatifKdvliToplam,
                      ),
                      style:
                          const TextStyle(
                        color:
                            Colors.teal,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // =================================================
          // ANA ALAN
          // =================================================

          Expanded(
            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets
                      .all(16),
              child: Column(
                children: [
                  // RESİM
                  SizedBox(
                    height: 200,
                    width:
                        double.infinity,
                    child:
                        Container(
                      decoration:
                          BoxDecoration(
                        color: Colors
                            .grey
                            .shade200,
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                        border:
                            Border.all(
                          color: Colors
                              .grey
                              .shade400,
                        ),
                      ),
                      child:
                          _yukleniyor
                              ? const Center(
                                  child:
                                      Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(
                                        height:
                                            12,
                                      ),
                                      Text(
                                        'Fiş analiz ediliyor...',
                                      ),
                                    ],
                                  ),
                                )
                              : _secilenResimBytes !=
                                      null
                                  ? ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(
                                        12,
                                      ),
                                      child:
                                          Image.memory(
                                        _secilenResimBytes!,
                                        fit: BoxFit
                                            .contain,
                                      ),
                                    )
                                  : const Center(
                                      child:
                                          Text(
                                        'Bilgisayardan fiş görseli seçin',
                                      ),
                                    ),
                    ),
                  ),

                  const SizedBox(
                    height: 12,
                  ),

                  // BUTONLAR
                  Row(
                    children: [
                      Expanded(
                        child:
                            ElevatedButton
                                .icon(
                          onPressed:
                              _yukleniyor
                                  ? null
                                  : () =>
                                      _resimSec(
                                        ImageSource
                                            .gallery,
                                      ),
                          icon:
                              const Icon(
                            Icons
                                .file_upload,
                          ),
                          label:
                              const Text(
                            'Fiş Seç',
                          ),
                        ),
                      ),

                      const SizedBox(
                        width: 10,
                      ),

                      Expanded(
                        child:
                            ElevatedButton
                                .icon(
                          onPressed:
                              (_secilenResimBytes ==
                                          null ||
                                      _yukleniyor)
                                  ? null
                                  : _fisAnalizEt,
                          icon:
                              const Icon(
                            Icons
                                .auto_awesome,
                          ),
                          label:
                              const Text(
                            'FİŞİ ANALİZ ET',
                          ),
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                Colors
                                    .teal,
                            foregroundColor:
                                Colors
                                    .white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // BEKLEYEN FİŞ
                  if (_bekleyenFis !=
                      null)
                    _bekleyenFisWidget(),

                  // =================================================
                  // KAYITLI FİŞLER
                  // =================================================

                  const SizedBox(
                    height: 16,
                  ),

                  Align(
                    alignment:
                        Alignment
                            .centerLeft,
                    child:
                        Text(
                      'TARANAN FİŞLER',
                      style:
                          TextStyle(
                        fontSize: 17,
                        fontWeight:
                            FontWeight
                                .bold,
                        color: Colors
                            .teal
                            .shade800,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  if (_tarananFisler
                      .isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets
                              .all(
                        30,
                      ),
                      child:
                          Text(
                        'Henüz kaydedilmiş fiş yok.',
                        style:
                            TextStyle(
                          color:
                              Colors.grey,
                        ),
                      ),
                    ),

                  ...List.generate(
                    _tarananFisler
                        .length,
                    (index) {
                      final fis =
                          _tarananFisler[
                              index];

                      // Kayıt düzenleniyorsa
                      if (_duzenlenenKayitIndex ==
                          index) {
                        return Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            bottom:
                                12,
                          ),
                          child:
                              _kayitliFisDuzenlemeWidget(
                            index,
                          ),
                        );
                      }

                      return Card(
                        child:
                            Padding(
                          padding:
                              const EdgeInsets
                                  .all(
                            10,
                          ),
                          child:
                              Column(
                            children: [
                              ListTile(
                                contentPadding:
                                    EdgeInsets.zero,
                                leading:
                                    const CircleAvatar(
                                  backgroundColor:
                                      Colors
                                          .teal,
                                  child:
                                      Icon(
                                    Icons
                                        .receipt,
                                    color:
                                        Colors.white,
                                  ),
                                ),
                                title:
                                    Text(
                                  fis.magaza,
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                                subtitle:
                                    Text(
                                  '${fis.tarih} • ${fis.ozet}',
                                ),
                                trailing:
                                    Text(
                                  _para(
                                    fis.kdvliTutar,
                                  ),
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                    color:
                                        Colors.teal,
                                  ),
                                ),
                              ),

                              const Divider(),

                              _bilgiSatiri(
                                'KDV Oranı',
                                '%${fis.kdvOrani.toStringAsFixed(0)}',
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              _bilgiSatiri(
                                "KDV'siz Tutar",
                                _para(
                                  fis.kdvsizTutar,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              _bilgiSatiri(
                                'KDV Tutarı',
                                _para(
                                  fis.kdvTutari,
                                ),
                              ),

                              const SizedBox(
                                height: 6,
                              ),

                              _bilgiSatiri(
                                "KDV'li Tutar",
                                _para(
                                  fis.kdvliTutar,
                                ),
                              ),

                              const SizedBox(
                                height: 14,
                              ),

                              Row(
                                children: [
                                  Expanded(
                                    child:
                                        OutlinedButton
                                            .icon(
                                      onPressed:
                                          () {
                                        _kayitliFisiDuzenlemeyeAc(
                                          index,
                                        );
                                      },
                                      icon:
                                          const Icon(
                                        Icons
                                            .edit,
                                      ),
                                      label:
                                          const Text(
                                        'Düzenle',
                                      ),
                                      style:
                                          OutlinedButton
                                              .styleFrom(
                                        foregroundColor:
                                            Colors.teal,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    width:
                                        10,
                                  ),

                                  Expanded(
                                    child:
                                        OutlinedButton
                                            .icon(
                                      onPressed:
                                          () {
                                        _fisSil(
                                          index,
                                        );
                                      },
                                      icon:
                                          const Icon(
                                        Icons
                                            .delete_outline,
                                      ),
                                      label:
                                          const Text(
                                        'Sil',
                                      ),
                                      style:
                                          OutlinedButton
                                              .styleFrom(
                                        foregroundColor:
                                            Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}