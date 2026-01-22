# i13Pro Backup App

Un'applicazione desktop completa per il backup automatico di dispositivi mobili (Android e iOS) su Windows e macOS.

## Caratteristiche Principali

### 🔌 Connessione Automatica
- Rilevamento automatico di dispositivi Android e iOS
- Polling continuo per rilevare nuove connessioni
- Supporto per più dispositivi simultanei

### 📁 Gestione Backup
- Selezione flessibile delle cartelle da backuppare
- Configurazioni multiple per dispositivo
- Esclusione di file e cartelle specifiche
- Filtri per estensioni file

### 🔄 Modalità di Sincronizzazione
1. **Telefono → PC**: Copia solo dal telefono al PC
2. **PC → Telefono**: Copia solo dal PC al telefono
3. **Bidirezionale**: Sincronizzazione in entrambe le direzioni

### 🗑️ Gestione Cancellazione
- **Non eliminare**: Mantieni file su entrambi i dispositivi
- **Elimina su telefono**: Libera spazio sul dispositivo dopo il backup
- **Elimina su PC**: Rimuovi file dal PC
- **Elimina su entrambi**: Pulizia completa

### ⏰ Backup Automatico
- Schedulazione automatica dei backup
- Intervalli configurabili (da 30 minuti a 1 giorno)
- Monitoraggio in tempo reale del progresso

## Requisiti di Sistema

### Windows
- Windows 10 o superiore
- **ADB (Android Debug Bridge)** per dispositivi Android
  - Installare Android SDK Platform Tools
  - Aggiungere ADB al PATH di sistema
- **iTunes** o **libimobiledevice** per dispositivi iOS

### macOS
- macOS 10.14 o superiore
- **ADB** per dispositivi Android:
  ```bash
  brew install android-platform-tools
  ```
- **libimobiledevice** per dispositivi iOS:
  ```bash
  brew install libimobiledevice
  brew install ideviceinstaller
  ```

## Installazione

### 1. Vai nella directory del progetto
```bash
cd i13pro_backup_app
```

### 2. Installa le dipendenze
```bash
flutter pub get
```

### 3. Genera i file JSON serialization
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Esegui l'applicazione

**Su Windows:**
```bash
flutter run -d windows
```

**Su macOS:**
```bash
flutter run -d macos
```

## Configurazione Dispositivi

### Android
1. Abilita **Debug USB** sul dispositivo:
   - Vai in Impostazioni → Informazioni sul telefono
   - Tocca 7 volte su "Numero build"
   - Torna indietro e vai in Opzioni sviluppatore
   - Abilita "Debug USB"

2. Collega il dispositivo via USB
3. Autorizza il computer sul dispositivo quando richiesto
4. Il dispositivo apparirà automaticamente nell'app

### iOS
1. Collega il dispositivo via USB
2. Autorizza il computer quando richiesto
3. Inserisci il codice del dispositivo se necessario
4. Il dispositivo apparirà automaticamente nell'app

**Nota**: Per iOS, alcune funzionalità potrebbero essere limitate a causa delle restrizioni di Apple.

## Utilizzo

### 1. Connetti un Dispositivo
- Collega il dispositivo via USB
- Il dispositivo apparirà nel pannello sinistro
- Clicca sul dispositivo per selezionarlo

### 2. Crea una Configurazione di Backup
- Clicca su "Nuova Configurazione"
- Inserisci un nome descrittivo
- Aggiungi le cartelle da backuppare:
  - Specifica il percorso sul telefono (es: `/sdcard/DCIM/Camera`)
  - Seleziona la cartella di destinazione sul PC
- Scegli la modalità di sincronizzazione
- Configura le opzioni di cancellazione
- Abilita il backup automatico se desiderato
- Salva la configurazione

### 3. Avvia un Backup
- Seleziona il dispositivo
- Clicca su "Avvia Backup" nella configurazione desiderata
- Monitora il progresso nella finestra di dialogo
- Attendi il completamento

## Percorsi Comuni Android

### Foto e Video
```
/sdcard/DCIM/Camera
/sdcard/DCIM/Screenshots
/sdcard/Pictures
```

### Documenti
```
/sdcard/Documents
/sdcard/Download
```

### WhatsApp
```
/sdcard/WhatsApp/Media/WhatsApp Images
/sdcard/WhatsApp/Media/WhatsApp Video
/sdcard/WhatsApp/Databases
```

### Musica
```
/sdcard/Music
```

## Architettura dell'App

```
lib/
├── models/              # Modelli di dati
│   ├── device.dart      # Definizione dispositivo mobile
│   ├── backup_config.dart # Configurazione backup
│   └── sync_progress.dart # Stato sincronizzazione
├── services/            # Servizi di business logic
│   ├── android_device_service.dart
│   ├── ios_device_service.dart
│   ├── device_manager.dart
│   ├── backup_service.dart
│   └── config_storage.dart
├── providers/           # State management
│   └── app_state.dart
├── screens/            # Schermate principali
│   ├── home_screen.dart
│   └── backup_config_screen.dart
└── widgets/            # Widget riutilizzabili
    ├── device_card.dart
    ├── backup_config_list.dart
    └── backup_progress_dialog.dart
```

## Risoluzione Problemi

### Dispositivo Android non rilevato
1. Verifica che ADB sia installato: `adb version`
2. Controlla che il dispositivo sia autorizzato: `adb devices`
3. Riavvia il server ADB: `adb kill-server && adb start-server`
4. Verifica che il Debug USB sia abilitato

### Dispositivo iOS non rilevato
1. Verifica che libimobiledevice sia installato: `idevice_id --version`
2. Controlla che il dispositivo sia autorizzato
3. Prova a ricollegare il dispositivo
4. Assicurati che iTunes o Finder riconosca il dispositivo

### Errori di sincronizzazione
1. Verifica i permessi di scrittura sul PC
2. Controlla che il percorso sul telefono sia corretto
3. Assicurati che ci sia spazio sufficiente su entrambi i dispositivi
4. Consulta i log per errori specifici

## Limitazioni Note

### iOS
- **Scrittura limitata**: iOS non permette scrittura diretta sul filesystem per motivi di sicurezza
- **Backup completo**: Si consiglia di usare il backup completo del dispositivo
- **Cartelle accessibili**: Solo alcune cartelle sono accessibili senza jailbreak

### Android
- **Permessi di root**: Alcune cartelle richiedono permessi root
- **Android 11+**: Limitazioni aggiuntive sullo storage condiviso

## Sviluppi Futuri

- [ ] Backup incrementale (solo file modificati)
- [ ] Compressione automatica dei backup
- [ ] Crittografia dei backup
- [ ] Sincronizzazione cloud (Google Drive, Dropbox)
- [ ] Notifiche push per backup completati
- [ ] Dashboard con statistiche dettagliate
- [ ] Supporto per backup wireless (WiFi)
- [ ] Ripristino selettivo dei file

## Licenza

Questo progetto è distribuito sotto licenza MIT.

---

**Nota**: Questa applicazione richiede che i dispositivi siano collegati fisicamente via USB. Assicurati di avere i driver appropriati installati per il tuo sistema operativo.


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
