# pos_tarayici_app

# POS Fiş Tarayıcı

POS Fiş Tarayıcı, fiş görsellerini yapay görme tabanlı bir model ile analiz ederek fiş üzerindeki bilgileri otomatik olarak çıkaran web tabanlı bir uygulamadır.

## Proje Hakkında

Uygulama, kullanıcı tarafından yüklenen fiş görselini yapay zeka modeli ile analiz eder ve aşağıdaki bilgileri otomatik olarak belirler:

* Mağaza / firma adı
* Tarih
* KDV oranı
* KDV hariç tutar
* KDV tutarı
* KDV dahil toplam tutar
* Fişteki ürün sayısına dayalı kısa özet

KDV oranı fiş üzerinde açıkça bulunmuyorsa, KDV dahil ve KDV hariç tutarlar üzerinden hesaplanabilir. Eksik tutarlar da mevcut bilgiler ve KDV oranı kullanılarak matematiksel olarak hesaplanmaktadır.

## Temel Özellikler

* Fiş görseli yükleme
* Yapay zeka ile fiş analizi
* Otomatik KDV oranı ve tutar hesaplama
* Kaydetmeden önce fiş bilgilerini kontrol etme
* Kaydedilmeden önce fiş bilgilerini düzenleme
* Kaydedilmiş fişleri düzenleme
* Fiş silme işlemi için onay sistemi
* Tüm kayıtları temizleme
* Kayıtlı fişlerin toplam tutarlarını görüntüleme
* KDV hariç, KDV ve KDV dahil toplamları ayrı görüntüleme
* Fiş kayıtlarını CSV formatında dışa aktarma
* Web üzerinden kullanılabilme
* Mobil cihazlarda ana ekrana eklenerek uygulama benzeri kullanılabilme

## Kullanılan Teknolojiler

* **Flutter Web** – Kullanıcı arayüzü ve web uygulaması
* **Dart** – Uygulama geliştirme
* **OpenRouter API** – Yapay zeka modeline erişim
* **Google Gemini** – Fiş görsellerinin analiz edilmesi
* **Cloudflare Worker** – API erişiminin güvenli şekilde yönlendirilmesi
* **Firebase Hosting** – Web uygulamasının yayınlanması
* **Shared Preferences** – Tarayıcı tarafında kayıtların saklanması
* **Git / GitHub** – Kaynak kodu ve sürüm kontrolü

## Yapay Zeka Süreci

Fiş görseli uygulamaya yüklendiğinde görüntü, yapay zeka modeline gönderilir. Modelden yalnızca belirlenen fiş bilgilerini içeren yapılandırılmış JSON formatında çıktı alınır.

Model tarafından okunabilen bilgiler doğrultusunda:

1. Mağaza ve tarih bilgileri çıkarılır.
2. KDV oranı belirlenir.
3. KDV dahil ve KDV hariç tutarlar belirlenir.
4. Eksik tutarlar matematiksel formüller kullanılarak hesaplanır.
5. KDV tutarı, KDV dahil toplam ile KDV hariç toplam arasındaki farktan hesaplanır.
6. Elde edilen bilgiler kullanıcıya kaydetmeden önce gösterilir.

Okunamayan bilgilerin tahmin edilmemesi için modelden bilinmeyen alanlarda varsayım yapmaması istenir.

## KDV Hesaplama

Uygulamada eksik KDV bilgilerinin tamamlanması için aşağıdaki hesaplamalar kullanılmaktadır:

**KDV Oranı:**

`((KDV Dahil - KDV Hariç) / KDV Hariç) × 100`

**KDV Hariç Tutar:**

`KDV Dahil / (1 + KDV Oranı / 100)`

**KDV Dahil Tutar:**

`KDV Hariç × (1 + KDV Oranı / 100)`

**KDV Tutarı:**

`KDV Dahil - KDV Hariç`

## API Güvenliği

OpenRouter API anahtarı doğrudan Flutter uygulamasında tutulmamaktadır.

İstek akışı:

**Flutter Web → Cloudflare Worker → OpenRouter API → Yapay Zeka Modeli**

Bu yapı sayesinde API anahtarının istemci tarafındaki uygulama kodunda açık şekilde bulunması engellenmiştir.

## Yayın

Uygulama Firebase Hosting üzerinden yayınlanmaktadır.

**Canlı Uygulama:**
https://pos-tarayici.web.app

## Kaynak Kod

Projenin kaynak koduna GitHub repository üzerinden ulaşılabilir.

**GitHub:**
https://github.com/Nisanurkonar/pos-tarayici-app

## Projenin Amacı

Bu proje ile görüntü tabanlı yapay zeka kullanılarak gerçek hayattaki fiş bilgilerinin otomatik olarak dijital verilere dönüştürülmesi, kullanıcı tarafından kontrol edilmesi ve yapılandırılmış şekilde saklanması amaçlanmıştır.


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
