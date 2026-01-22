# 📡 Proximity Backup Wireless - Guida Completa

## 🌟 Cos'è il Proximity Backup?

Il **Proximity Backup** è una funzionalità avanzata che permette al tuo telefono Android di effettuare **backup automatici** quando è **sulla stessa rete WiFi** del PC, **senza bisogno del cavo USB**!

### Come Funziona

1. **Setup Iniziale** (una tantum via USB)
2. **Rilevamento Automatico** (quando telefono e PC sono sulla stessa WiFi)
3. **Backup Automatico** (si avvia da solo in background)
4. **Cooldown** (evita backup troppo frequenti)

---

## 🚀 Setup Iniziale (5 minuti)

### Passo 1: Collega via USB (solo la prima volta)

1. Collega il telefono Android al Mac via USB
2. Autorizza il debug USB sul telefono
3. L'app rileverà il dispositivo

### Passo 2: Abilita la Connessione Wireless

1. Nella home, clicca l'**icona WiFi** (📶) sulla card del dispositivo
2. Si aprirà il dialog "Setup Connessione Wireless"
3. Assicurati che il telefono sia connesso al WiFi
4. Clicca "**Abilita Connessione Wireless**"
5. Aspetta qualche secondo...
6. ✅ L'app mostrerà l'**IP del telefono** (es: `192.168.1.45`)

### Passo 3: Scollega il Cavo!

Ora puoi **scollegare il cavo USB**! 🎉

Il telefono si connetterà automaticamente quando:
- È sulla stessa rete WiFi del Mac
- L'app è in esecuzione
- Il Proximity Backup è abilitato

---

## ⚙️ Attiva il Proximity Backup

### Nella Home Screen

1. In alto vedrai il pannello "**Backup Automatico Proximity**"
2. Attiva lo **switch** a destra
3. 📡 L'app inizierà a rilevare dispositivi sulla rete

### Configurazione Backup

Quando crei o modifichi una configurazione backup:
- ✅ Abilita "**Backup Automatico**"
- Scegli l'**intervallo** (es: Ogni ora, Ogni 6 ore)
- Salva la configurazione

**Importante**: Solo le configurazioni con "Backup Automatico" abilitato verranno eseguite dal Proximity Backup!

---

## 📊 Come Funziona il Rilevamento

### Scansione Automatica

Quando il Proximity Backup è attivo:

1. **Ogni 15 secondi** l'app scansiona la rete locale (192.168.x.x)
2. Cerca dispositivi con **ADB WiFi** abilitato (porta 5555)
3. Quando trova un dispositivo noto:
   - Verifica se ha configurazioni con backup automatico
   - Controlla il **cooldown** (per evitare backup troppo frequenti)
   - Se tutto OK → **Avvia il backup automatico**

### Pannello Status

Nel pannello "Proximity Backup" vedrai:
- ✅ **Stato**: Attivo/Disattivo
- 📱 **Dispositivi rilevati**: Numero e lista
- 🟢 **Indicatore verde**: Dispositivo online

---

## 🎯 Esempi d'Uso Pratici

### Caso 1: Backup Foto Automatico Serale

```
Setup:
1. Configura "Backup Foto" con:
   - Cartella: /sdcard/DCIM
   - Modalità: Telefono → PC
   - Elimina su telefono: ✅ (libera spazio)
   - Auto backup: Ogni giorno
   
2. Abilita proximity backup
3. Ogni sera, quando torni a casa:
   - Telefono si connette al WiFi
   - Proximity rileva il dispositivo
   - Backup si avvia automaticamente
   - Foto vengono copiate e cancellate dal telefono
```

### Caso 2: Sync Documenti Continuo

```
Setup:
1. Configura "Sync Documenti" con:
   - Cartella: /sdcard/Documents/Lavoro
   - Modalità: Bidirezionale
   - Elimina: Non eliminare
   - Auto backup: Ogni ora
   
2. Abilita proximity backup
3. Durante la giornata lavorativa:
   - Modifichi documenti sul telefono o PC
   - Ogni ora viene sincronizzato automaticamente
   - Sempre la versione più recente su entrambi
```

### Caso 3: Backup Completo Notturno

```
Setup:
1. Usa "Backup Completo"
2. Imposta auto backup: Ogni 12 ore
3. Modalità: Telefono → PC
4. Elimina: Non eliminare

Durante la notte:
- Telefono in carica sul comodino
- Connesso al WiFi
- Proximity lo rileva
- Backup completo automatico
```

---

## 🔧 Dettagli Tecnici

### Cooldown Period

**Default: 30 minuti**

Dopo ogni backup automatico, il sistema aspetta 30 minuti prima di permettere un altro backup per lo stesso dispositivo.

**Perché?** 
- Evita backup troppo frequenti
- Risparmia batteria
- Riduce uso rete

### Porta ADB WiFi

**Porta standard: 5555**

ADB over WiFi usa la porta TCP 5555. L'app:
- Scansiona la subnet locale (es: 192.168.1.1-254)
- Prova a connettersi sulla porta 5555
- Se trova un device ADB, lo identifica

### Requisiti di Rete

- **Stessa subnet**: Telefono e PC devono essere sulla stessa rete locale
- **Firewall**: macOS potrebbe chiedere di consentire connessioni in ingresso
- **Router**: Alcuni router aziendali bloccano comunicazioni client-to-client

---

## 🆘 Troubleshooting

### Il dispositivo non viene rilevato

**Soluzione 1: Verifica WiFi**
```bash
# Sul Mac, verifica il tuo IP
ifconfig | grep "inet "

# Dovresti vedere qualcosa come: 192.168.1.x
```

**Soluzione 2: Riconnetti ADB WiFi**
```bash
# Collega via USB e riabilita WiFi
adb devices
adb -s DEVICE_ID tcpip 5555

# Ottieni IP del telefono
adb shell ip addr show wlan0 | grep inet
```

**Soluzione 3: Connetti Manualmente**
```bash
# Se conosci l'IP del telefono
adb connect 192.168.1.45:5555
```

### Backup non si avvia automaticamente

**Controlla:**
1. ✅ Proximity Backup è **attivo** (switch verde)
2. ✅ Configurazione ha "**Auto backup**" abilitato
3. ✅ Dispositivo è **rilevato** (appare nella lista)
4. ⏱️ Non sei nel **cooldown** period (30 min dall'ultimo backup)

### Connessione WiFi si perde

**Possibili cause:**
- Telefono va in deep sleep → Disabilita risparmio batteria per ADB
- WiFi del telefono si disconnette → Mantieni WiFi sempre attivo
- Router riassegna IP → Usa IP statico per il telefono

---

## 🔒 Sicurezza

### ADB over WiFi è sicuro?

**Limitazioni di sicurezza:**
- ADB WiFi è **non criptato**
- Accessibile a chiunque sulla stessa rete
- Usa solo su **reti fidate** (casa, ufficio)

**Best practices:**
1. Usa solo su reti WiFi **private**
2. Disabilita ADB WiFi quando non serve
3. Non usare su WiFi pubblici
4. Considera VPN per reti aziendali

### Permessi Richiesti

- **Debug USB**: Necessario per setup iniziale
- **Accesso File**: Per leggere/scrivere file
- **Rete**: Per rilevamento e connessione wireless

---

## 💡 Tips Avanzati

### 1. Backup Condizionale

Crea multiple configurazioni con intervalli diversi:
- **Foto**: Ogni giorno (pesante)
- **Documenti**: Ogni ora (leggero)
- **WhatsApp**: Ogni 6 ore (medio)

### 2. Risparmio Batteria

Imposta backup automatici solo quando:
- Telefono è in carica (usa Tasker/MacroDroid)
- Batteria > 50%
- Nelle ore notturne

### 3. Notifiche

L'app stampa nel log:
```
📡 Dispositivo rilevato: Samsung Galaxy
🔄 Avvio backup automatico...
💾 Backup: Foto e Video
✅ Backup completato: Foto e Video
🎉 Backup automatico completato
```

Usa `flutter run` per vedere i log in tempo reale.

### 4. Multiple Reti

Se hai WiFi casa + ufficio:
- Setup wireless funziona su entrambe
- Il telefono si riconnetterà automaticamente
- Stesso IP o diverso, funziona comunque

---

## 📈 Prossime Funzionalità

- [ ] Notifiche push al completamento backup
- [ ] Statistiche proximity backup (frequenza, data/ora)
- [ ] Scheduler avanzato (solo notturno, solo weekend)
- [ ] Backup condizionale (batteria, WiFi specifico)
- [ ] Supporto iOS (limitato dalle restrizioni Apple)

---

## 🎉 Riepilogo

**Con il Proximity Backup:**
1. ✅ Setup wireless una volta via USB
2. ✅ Scollega il cavo per sempre
3. ✅ Backup automatici quando telefono e PC sono vicini
4. ✅ Zero intervento manuale
5. ✅ Tutto in background

**Non serve più:**
- ❌ Cercare il cavo USB
- ❌ Ricordarsi di fare backup
- ❌ Intervento manuale

**Tutto avviene automaticamente quando torni a casa/ufficio!** 🏡💼
