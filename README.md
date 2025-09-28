# Mobile AI Assistant

Aplikasi AI Assistant berbasis Flutter dengan fitur Speech-to-Text dan Text-to-Speech yang memungkinkan pengguna berinteraksi dengan AI menggunakan suara.

## 🚀 Fitur Utama

- **Speech-to-Text**: Menangkap suara pengguna dan mengubahnya menjadi teks
- **Text-to-Speech**: AI merespons dengan suara yang dapat disesuaikan
- **Pengaturan Suara**: Kustomisasi kecepatan, volume, dan nada suara
- **Chat Interface**: Antarmuka percakapan yang modern dan responsif
- **AI Avatar**: Avatar animasi yang memberikan feedback visual
- **Voice Button**: Tombol hold-to-talk yang dinamis
- **Error Handling**: Penanganan error yang baik dengan retry mechanism

## 📱 Screenshots

*Screenshots akan ditambahkan setelah testing*

## 🛠️ Teknologi yang Digunakan

- **Flutter**: Framework UI untuk mobile development
- **GetX**: State management dan dependency injection
- **Speech-to-Text**: Package untuk speech recognition
- **Flutter TTS**: Package untuk text-to-speech
- **Permission Handler**: Mengelola izin perangkat
- **Flutter Animate**: Animasi UI yang smooth

## 📋 Prasyarat

Sebelum memulai, pastikan Anda telah menginstall:

### 1. Flutter SDK

#### Windows:
1. Download Flutter SDK dari [flutter.dev](https://flutter.dev/docs/get-started/install/windows)
2. Extract ke folder `C:\flutter`
3. Tambahkan `C:\flutter\bin` ke PATH environment variable
4. Jalankan `flutter doctor` untuk memverifikasi instalasi

#### macOS:
1. Download Flutter SDK dari [flutter.dev](https://flutter.dev/docs/get-started/install/macos)
2. Extract ke folder `/Users/username/flutter`
3. Tambahkan ke PATH di `~/.zshrc` atau `~/.bash_profile`:
   ```bash
   export PATH="$PATH:/Users/username/flutter/bin"
   ```
4. Jalankan `flutter doctor` untuk memverifikasi instalasi

#### Linux:
1. Download Flutter SDK dari [flutter.dev](https://flutter.dev/docs/get-started/install/linux)
2. Extract ke folder `/home/username/flutter`
3. Tambahkan ke PATH di `~/.bashrc`:
   ```bash
   export PATH="$PATH:/home/username/flutter/bin"
   ```
4. Jalankan `flutter doctor` untuk memverifikasi instalasi

### 2. Visual Studio Code

1. Download VS Code dari [code.visualstudio.com](https://code.visualstudio.com/)
2. Install extension Flutter:
   - Buka VS Code
   - Tekan `Ctrl+Shift+X` (Windows/Linux) atau `Cmd+Shift+X` (macOS)
   - Cari "Flutter" dan install extension Flutter
   - Install juga extension "Dart" yang akan otomatis terinstall

### 3. Android Studio (untuk Android development)

1. Download Android Studio dari [developer.android.com](https://developer.android.com/studio)
2. Install Android SDK dan Android SDK Command-line Tools
3. Setup Android emulator atau sambungkan device fisik

### 4. Xcode (untuk iOS development - macOS only)

1. Install Xcode dari App Store
2. Install Xcode Command Line Tools:
   ```bash
   sudo xcode-select --install
   ```

## 🔧 Instalasi dan Setup

### 1. Clone Repository

```bash
git clone https://github.com/jogels/mobileAIAssistant.git
cd mobileAIAssistant
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Setup Android (untuk Android development)

1. Buka Android Studio
2. Setup Android SDK (API level 21 atau lebih tinggi)
3. Buat Android Virtual Device (AVD) atau sambungkan device fisik
4. Enable Developer Options dan USB Debugging di device

### 4. Setup iOS (untuk iOS development - macOS only)

1. Buka Xcode
2. Accept license agreement:
   ```bash
   sudo xcodebuild -license accept
   ```
3. Install iOS Simulator

## 🚀 Menjalankan Aplikasi

### 1. Verifikasi Setup

```bash
flutter doctor
```

Pastikan semua komponen menunjukkan status ✅ (hijau).

### 2. List Available Devices

```bash
flutter devices
```

### 3. Run Aplikasi

#### Debug Mode:
```bash
flutter run
```

#### Release Mode:
```bash
flutter run --release
```

#### Specific Device:
```bash
flutter run -d <device_id>
```

### 4. Build APK (Android)

```bash
flutter build apk --release
```

File APK akan tersedia di `build/app/outputs/flutter-apk/app-release.apk`

### 5. Build IPA (iOS - macOS only)

```bash
flutter build ios --release
```

## 📱 Cara Menggunakan Aplikasi

### 1. Pertama Kali Membuka
- Berikan izin mikrofon saat diminta
- Pastikan koneksi internet stabil

### 2. Menggunakan Voice Button
- Tekan dan tahan tombol mikrofon biru
- Berbicara dengan jelas
- Lepas tombol untuk mengirim pesan
- AI akan merespons dengan suara dan teks

### 3. Pengaturan Suara
- Tekan icon ⚙️ di AppBar
- Atur kecepatan bicara (10% - 100%)
- Atur volume (0% - 100%)
- Atur nada suara (0.5 - 2.0)
- Tekan "Test Suara" untuk mendengar hasilnya

### 4. Fitur Lainnya
- Tekan icon 🗑️ untuk menghapus percakapan
- Gunakan suggestion chips untuk memulai percakapan

## 🔧 Troubleshooting

### Speech Recognition Tidak Berfungsi
- Pastikan izin mikrofon telah diberikan
- Periksa koneksi internet
- Gunakan device fisik (bukan emulator)
- Berbicara dengan jelas dan dekat ke mikrofon

### Build Error
- Jalankan `flutter clean`
- Jalankan `flutter pub get`
- Periksa versi Flutter dengan `flutter --version`

### Permission Denied
- Pastikan semua izin telah diberikan di pengaturan perangkat
- Restart aplikasi setelah memberikan izin

## 📦 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.6
  speech_to_text: ^6.6.0
  flutter_tts: ^3.8.5
  permission_handler: ^11.4.0
  flutter_animate: ^4.5.0
```

## 🤝 Contributing

1. Fork repository ini
2. Buat feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit perubahan (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

## 📞 Contact

- **GitHub**: [@jogels](https://github.com/jogels)
- **Project Link**: [https://github.com/jogels/mobileAIAssistant](https://github.com/jogels/mobileAIAssistant)

## 🙏 Acknowledgments

- Flutter team untuk framework yang luar biasa
- GetX team untuk state management yang powerful
- Speech-to-Text dan Flutter TTS package developers
- Komunitas Flutter Indonesia

---

**Happy Coding! 🚀**