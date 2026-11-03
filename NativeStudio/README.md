# Studio — app nativa SwiftUI

Apri `Package.swift` in Xcode e premi Run per eseguire la versione macOS. Il progetto usa SwiftUI e SwiftData ed è dichiarato per macOS 27 e iOS 27.

La versione corrente include:

- materie, obiettivi, esami, CFU e voti;
- medie aritmetica e ponderata;
- sessioni di studio e streak calcolate dai giorni consecutivi;
- dashboard, suggerimento automatico e temi Chiaro, Scuro e Liquid Glass;
- salvataggio locale persistente con SwiftData.

## Sincronizzazione tra Mac e iPhone

Per attivare la sincronizzazione reale serve creare un target app in Xcode con lo stesso bundle identifier per macOS e iOS, poi abilitare **iCloud > CloudKit** nelle Signing & Capabilities. A quel punto la configurazione SwiftData può essere collegata al container CloudKit dell'app. Questa fase richiede l'account Apple Developer del proprietario dell'app, quindi non viene configurata automaticamente nel sorgente.
