# Guida Rapida - i13Pro Backup App

## 🚀 Avvio Rapido

### Prerequisiti

#### macOS (il tuo sistema)
```bash
# Installa ADB per Android
brew install android-platform-tools

# Installa libimobiledevice per iOS
brew install libimobiledevice ideviceinstaller
```

#### Windows
1. Scarica Android SDK Platform Tools
2. Aggiungi ADB al PATH di sistema
3. Installa iTunes per dispositivi iOS

### Esegui l'applicazione

```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows
```

## 📱 Configura il tuo dispositivo

### Android
1. **Abilita Debug USB**:
   - Impostazioni → Info telefono
   - Tocca 7 volte "Numero build"
   - Vai in "Opzioni sviluppatore"
   - Attiva "Debug USB"

2. **Collega via USB**
3. **Autorizza il computer** sul telefono
4. Il dispositivo apparirà automaticamente nell'app

### iOS
1. **Collega via USB**
2. **Autorizza il computer** (inserisci il codice)
3. Il dispositivo apparirà automaticamente nell'app

## 💾 Crea il tuo primo backup

1. **Seleziona il dispositivo** nel pannello sinistro
2. **Clicca "Nuova Configurazione"**
3. **Configura il backup**:
   - Nome: "Backup Foto"
   - Aggiungi cartella:
     - Telefono: `/sdcard/DCIM/Camera`
     - PC: Seleziona una cartella
   - Modalità: "Telefono → PC"
   - Cancellazione: "Non eliminare"
4. **Salva**
5. **Clicca "Avvia Backup"**

## 📂 Cartelle Android comuni

```
Foto:      /sdcard/DCIM/Camera
Video:     /sdcard/DCIM/Camera
Screenshot:/sdcard/DCIM/Screenshots
WhatsApp:  /sdcard/WhatsApp/Media
Documenti: /sdcard/Documents
Download:  /sdcard/Download
Musica:    /sdcard/Music
```

## ⚙️ Opzioni Principali

### Modalità Sincronizzazione
- **Telefono → PC**: Solo backup
- **PC → Telefono**: Ripristino
- **Bidirezionale**: Sincronizzazione completa

### Gestione Cancellazione
- **Non eliminare**: Mantieni tutto
- **Elimina su telefono**: Libera spazio sul dispositivo
- **Elimina su PC**: Rimuovi backup
- **Elimina su entrambi**: Pulizia totale

### Backup Automatico
- Attiva per eseguire backup programmati
- Scegli l'intervallo (30 min - 24 ore)

## 🔧 Risoluzione Problemi

### Dispositivo non rilevato

**Android:**
```bash
# Verifica ADB
adb version

# Lista dispositivi
adb devices

# Riavvia ADB
adb kill-server && adb start-server
```

**iOS:**
```bash
# Verifica libimobiledevice
idevice_id --version

# Lista dispositivi
idevice_id -l
```

### Debug USB non funziona
1. Usa un cavo USB originale
2. Prova un'altra porta USB
3. Riavvia il dispositivo
4. Reinstalla i driver

## ⚠️ Note Importanti

- **iOS**: Funzionalità limitate da Apple
- **Android 11+**: Alcune cartelle richiedono permessi speciali
- **Backup WhatsApp**: Include solo media, non messaggi
- **Primo backup**: Può richiedere più tempo

## 📊 Monitoraggio

Durante il backup visualizzerai:
- Progresso in tempo reale
- File corrente in elaborazione
- Velocità di trasferimento
- Tempo trascorso
- Numero di file processati

## 🎯 Suggerimenti

1. **Inizia con una cartella piccola** per testare
2. **Usa backup automatici** per dati critici
3. **Verifica lo spazio disponibile** prima di grandi backup
4. **Mantieni il dispositivo connesso** durante tutto il processo
5. **Disattiva il risparmio energetico** sul dispositivo

## 📞 Aiuto

Se riscontri problemi:
1. Verifica i prerequisiti installati
2. Controlla la connessione USB
3. Riavvia l'applicazione
4. Consulta il README completo
5. Apri un issue su GitHub

---

**Buon backup! 🎉**
