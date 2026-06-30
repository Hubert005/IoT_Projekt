// ============================================================
//  Projektbeschreibung – Internet of Things
//  "Gehirnzellen Massaker" · IoT-Cocktailautomat
// ============================================================

#let title = "Gehirnzellen Massaker"
#let subtitle = "Vernetzter Cocktail-Automat mit ESP32, Arduino Nano und KI"

#set document(title: title + " – IoT Projektbeschreibung")

// --- Farben: eine einzige, zurückhaltende Akzentfarbe ---
#let accent = rgb("#1f3a5f")
#let gray = rgb("#555f6b")
#let rule = rgb("#c8ccd2")

// --- Seite mit laufender Kopf-/Fußzeile ---
#set page(
  paper: "a4",
  margin: (x: 2.6cm, top: 3cm, bottom: 2.6cm),
  header: context {
    if counter(page).get().first() > 0 {
      set text(size: 8.5pt, fill: gray)
      grid(columns: (1fr, auto),
        emph(title),
        smallcaps("IoT · Projektbeschreibung"),
      )
      v(-0.6em)
      line(length: 100%, stroke: 0.5pt + rule)
    }
  },
  footer: context {
    set text(size: 9pt, fill: gray)
    line(length: 100%, stroke: 0.5pt + rule)
    v(-0.3em)
    grid(columns: (1fr, auto),
      [FH Oberösterreich],
      counter(page).display("1"),
    )
  },
)

// --- Typografie: Serifen-Fließtext, Sans-Überschriften ---
#set text(font: "Libertinus Serif", size: 11pt, lang: "de", hyphenate: true)
#set par(justify: true, leading: 0.72em, first-line-indent: 0pt, spacing: 1.0em)

#show raw: set text(font: "DejaVu Sans Mono", size: 9pt)
#let code(body) = raw(body)

// --- Überschriften ---
#set heading(numbering: "1.1")
#show heading: set text(font: "Helvetica Neue")
#show heading.where(level: 1): it => [
  #v(1.1em)
  #block(below: 0.7em)[
    #text(fill: accent, weight: "bold", size: 15pt)[
      #counter(heading).display() #h(0.5em) #it.body
    ]
    #v(0.25em)
    #line(length: 100%, stroke: 0.8pt + accent)
  ]
]
#show heading.where(level: 2): it => [
  #v(0.5em)
  #text(fill: accent, weight: "bold", size: 12pt)[
    #counter(heading).display() #h(0.4em) #it.body
  ]
  #v(0.15em)
]
#show heading.where(level: 3): it => [
  #v(0.3em)
  #text(fill: black, weight: "bold", size: 10.5pt, font: "Helvetica Neue")[#it.body]
  #v(0.1em)
]

#set figure(supplement: [Abb.])
#show figure.caption: set text(size: 9.5pt, fill: gray)

// Tabellen einheitlich
#set table(stroke: 0.5pt + rule, inset: 7pt)
#show table.cell.where(y: 0): set text(weight: "bold")

// dezente Hinweisbox (eine Farbe, schlicht)
#let note(body) = block(
  fill: accent.lighten(94%),
  inset: (x: 11pt, y: 9pt),
  radius: 2pt,
  width: 100%,
  stroke: (left: 2.5pt + accent),
  text(size: 10pt)[#body],
)

// ============================================================
//  TITELSEITE
// ============================================================
#page(header: none, footer: none, margin: (x: 2.8cm, top: 4cm, bottom: 3cm))[
  #set par(justify: false)
  #align(center)[
    #text(size: 10pt, fill: gray, weight: "bold")[
      #smallcaps("Internet of Things · Projektbeschreibung")
    ]
    #v(0.4cm)
    #line(length: 40%, stroke: 0.8pt + accent)
    #v(1.6cm)

    #text(size: 30pt, weight: "bold", fill: accent, font: "Helvetica Neue")[#title]
    #v(0.5cm)
    #text(size: 13pt, fill: gray)[#subtitle]
    #v(2cm)

    #block(width: 82%)[
      #set text(size: 11pt)
      Ein vernetzter Getränkeautomat, bei dem zwei Spieler an Hardware-Tasten in
      Schere-Stein-Papier gegeneinander antreten. Der Verlierer bekommt einen per
      KI generierten Cocktail, frisch gemixt und ausgegeben. Das Dokument
      beschreibt Idee, Hardware, Schaltung, Software und die Kommunikation des
      Systems.
    ]
  ]

  #v(1fr)
  #line(length: 100%, stroke: 0.5pt + rule)
  #v(0.5cm)
  #grid(
    columns: (auto, 1fr),
    row-gutter: 8pt,
    column-gutter: 14pt,
    text(fill: gray)[Lehrveranstaltung], text(weight: "bold")[Internet of Things],
    text(fill: gray)[Hochschule], text(weight: "bold")[FH Oberösterreich],
    text(fill: gray)[Verfasser:innen], text(weight: "bold")[Sams Felix, Kekic Haris, Huber Elias, Grafeneder Daniels],
    text(fill: gray)[Semester / Jahr], text(weight: "bold")[6 / 2026],
  )
]

// ============================================================
//  INHALTSVERZEICHNIS
// ============================================================
#page(header: none)[
  #show outline.entry.where(level: 1): it => {
    v(0.6em, weak: true)
    strong(it)
  }
  #outline(title: [Inhaltsverzeichnis], indent: auto, depth: 2)
]

#counter(page).update(1)

// ============================================================
//  1 · PROJEKTIDEE
// ============================================================
= Projektidee, Motivation und Einsatzgebiete

== Die Idee

Unser Projekt ist ein Partyspiel in Form eines Getränkeautomaten. Zwei Personen
spielen an der Maschine eine Runde Schere-Stein-Papier, nicht am Handy, sondern
an echten, 3D-gedruckten Tasten an den seitlichen Bedienpanels. Wer das Duell verliert, muss trinken. Das Besondere ist, dass nicht der
Spieler entscheidet, _was_ getrunken wird, sondern eine KI. Aus den tatsächlich
angeschlossenen Zutaten und einem Foto des Verlierers generiert sie einen
individuellen Cocktail, der anschließend von vier Pumpen frisch gemixt und
ausgegeben wird.

Drei Bausteine greifen ineinander, und genau dieses Zusammenspiel ist der Kern
eines IoT-Systems.

- *Physisches Spiel.* An zwei Panels mit je drei Tasten (Schere, Stein, Papier)
  spielen zwei Personen gegeneinander. Die Auswertung übernimmt der ESP32.
- *Begleit-App.* Die Flutter-App führt durch das Spiel, zeigt den Punktestand
  live und verwaltet die Pumpen-Belegung.
- *KI und Ausschank.* Aus den Zutaten und dem Spielerfoto mixt eine KI den
  Drink. Der Arduino Nano steuert die Pumpen und gibt ihn aus.

== Motivation

Wir wollten bewusst kein reines „Sensor-liest-Wert-und-schickt-ihn-in-die-Cloud“-Projekt
bauen, sondern etwas, das die einzelnen IoT-Bausteine organisch zu einem
Erlebnis verbindet. Ein Spiel hat einen klaren Ablauf (Start, Runden,
Auswertung, Aktion), und dieser Ablauf zieht sich als roter Faden durch alle
Komponenten. Die Tasten dienen als Eingabe, zwei Mikrocontroller übernehmen die
Verarbeitung, eine drahtlose Verbindung führt zum Smartphone, ein aus der Cloud
geladenes KI-Modell läuft direkt auf dem Handy und Aktoren wie Pumpen und Buzzer
sorgen für die Ausgabe. So ist
jede geforderte Anforderung nicht nur „angehängt“, sondern hat eine echte
Funktion im Gesamtsystem.

== Einsatzgebiete

Der naheliegendste Einsatz ist die Unterhaltung auf Partys und Events, ein
Eyecatcher, der Gäste zusammenbringt. Darüber hinaus ist das System ein gutes
Beispiel für einen vernetzten Self-Service-Automaten. Die gleiche Architektur
(App steuert Gerät, Gerät führt zeitkritische Aktion aus, Cloud liefert die
„Intelligenz“) findet sich auch in modernen Kaffeevollautomaten, in der
Gastronomie-Automatisierung oder bei individualisierten Getränke-Stationen
wieder.

#pagebreak()

// ============================================================
//  2 · ARCHITEKTUR
// ============================================================
= Systemarchitektur

Das System gliedert sich in drei Schichten und zwei Übertragungsstrecken. Die
App spricht drahtlos über Bluetooth Low Energy (BLE) mit dem ESP32, der ESP32
steuert über eine serielle Leitung (UART) den Arduino Nano.

#table(
  columns: (1fr, 1fr, 1fr),
  align: left + top,
  table.header([Flutter-App (Smartphone)], [ESP32], [Arduino Nano]),
  [Spielführung und UI, Punktestand live, On-Device-KI, Foto-Aufnahme.],
  [Auswertung der Taster, Spiellogik (Best of Three), BLE-Server, Relay zum Nano.],
  [Ansteuerung der vier Pumpen, Mix-Sequenz, Quittung über den Buzzer.],
)

Diese Aufgabentrennung hat zwei Gründe. Erstens bringt der ESP32 Funk und genug
Rechenleistung für die Spiellogik mit, während der Nano die zeitkritische
Pumpensteuerung übernimmt. Zweitens läuft die Spiellogik lokal auf dem ESP32 und
die KI lokal auf dem Smartphone (Edge). Das Netz wird nur einmalig gebraucht, um
das KI-Modell aus der Cloud zu laden. Das Ergebnis ist geringe Latenz im Spiel
und ein robustes Verhalten auch bei wackeligem Netz.

// ============================================================
//  3 · KOMPONENTEN
// ============================================================
= Beschreibung der verwendeten Komponenten <komponenten>

== Übersicht (Stückliste)

Die folgende Stückliste entspricht dem Fritzing-Schaltplan aus @schaltplan.

#table(
  columns: (auto, auto, 1fr),
  align: (center + horizon, left + horizon, left + top),
  table.header([Anz.], [Bauteil], [Funktion]),
  [1], [ESP32], [Hauptcontroller, stellt den BLE-Server bereit, liest die Taster und fährt die Spiellogik],
  [1], [Arduino Nano], [Pumpen-Treiber, empfängt den Mix-Befehl und dosiert],
  [4], [DC-Pumpe (Motor)], [Fördern je eine Zutat in den Becher (kursfremde Komponente)],
  [4], [MOSFET], [Leistungsschalter für die Pumpenmotoren],
  [4], [Diode], [Freilaufdiode gegen Induktionsspannung der Motoren],
  [8], [Taster (Pushbutton)], [Spieleingabe, 2× je 3 (Schere/Stein/Papier) und Bedientasten],
  [1], [Piezo-Buzzer], [Akustische Rückmeldung „Drink fertig“],
  [2], [Widerstand], [Gate-Vorwiderstand / Pull-down der MOSFETs],
  [1], [Power-Plug], [Separate Stromversorgung der Pumpen],
)

#pagebreak()

== Die kursfremde Komponente (DC-Pumpen mit MOSFET-Treiber)

Als Komponente außerhalb des Kurs-Bundles haben wir vier kleine DC-Pumpen
(Membran- bzw. Schlauchpumpen, 3 bis 5 V) gewählt. Wir beschreiben sie hier
ausführlicher, damit sie auch andere nachbauen können.

*Funktionsprinzip.* Jede Pumpe enthält einen kleinen Gleichstrommotor, der eine
Membran bzw. einen Schlauch-Rotor antreibt und so Flüssigkeit fördert. Solange
Spannung anliegt, läuft die Pumpe mit nahezu konstanter Förderrate. Je länger
sie läuft, desto mehr Milliliter werden ausgegeben. Genau das nutzen wir zur
Dosierung.

*Warum ein Treiber nötig ist.* Die Pumpen ziehen mehr Strom, als ein
Mikrocontroller-Pin liefern darf. Jede Pumpe hängt deshalb an einem
N-Kanal-MOSFET, der als elektronischer Schalter arbeitet. Der Nano legt den
Gate-Pin auf HIGH, der MOSFET schaltet durch, die Pumpe läuft. Parallel zu jedem
Motor sitzt eine Schottky-Diode (1N5819) als Freilaufdiode. Sie fängt die
Spannungsspitze ab, die beim Abschalten eines Motors entsteht, und schützt so
die Elektronik.

*Anschluss und Ansteuerung.* Die Pumpen laufen über eine eigene 5-V-Quelle
(Power-Plug), damit die Mikrocontroller stabil bleiben. Angesteuert wird jede
Pumpe über #code("digitalWrite(pin, HIGH/LOW)"), die Laufzeit in Millisekunden
bestimmt die Menge.

#table(
  columns: (auto, 1fr, auto, 1fr),
  align: left + horizon,
  table.header([Typ], [DC-Membran-/Schlauchpumpe], [Treiber], [MOSFET]),
  [Spannung], [3 bis 5 V], [Schutz], [Diode],
  [Versorgung], [eigene 5-V-Quelle], [Dosierung], [über Laufzeit (ms)],
)

== Weitere Aktoren und Eingabe-Elemente

Der Piezo-Buzzer gibt am Ende des Mixens zwei kurze Töne als Bestätigung aus.
Pro Spieler gibt es ein 3D-gedrucktes Panel mit drei Tastern für Schere, Stein
und Papier. Zusätzlich sind am vorderen Bedienpanel Taster für _Next_ (Pumpe
durchschalten), _Clean_ (Pumpen spülen) und _Random_ (Zufallsdrink) vorgesehen.
Alle Taster sind als #code("INPUT_PULLUP") verschaltet (gedrückt = LOW) und
werden in Software entprellt.

#figure(
  image("IOT/pump.jpg", width: 30%),
  caption: [Steckbrett-Aufbau in Fritzing mit ESP32 und Arduino Nano, vier
  Pumpen mit MOSFET-Treiber und Freilaufdioden, Buzzer und Taster.],
)

#pagebreak()

// ============================================================
//  4 · SCHALTPLAN
// ============================================================
= Schaltplan <schaltplan>

Der Schaltplan wurde mit Fritzing erstellt. @fig-steck zeigt den gesamten Aufbau
auf dem Steckbrett mit allen Bauteilen und Verbindungen.

#figure(
  image("schaltplan/sketch_Steckplatine.png", width: 88%),
  caption: [Steckbrett-Aufbau in Fritzing mit ESP32 und Arduino Nano, vier
  Pumpen mit MOSFET-Treiber und Freilaufdioden, Buzzer und Taster.],
) <fig-steck>

Im Zentrum der Schaltung stehen die beiden Mikrocontroller. Der ESP32 liest die
Taster der beiden Spiel-Panels ein und kommuniziert per BLE mit dem Smartphone.
Über zwei Leitungen (UART) ist er mit dem Arduino Nano verbunden und teilt diesem
mit, was zu mixen ist. Damit beide Boards sich richtig verstehen, sind ihre
Sende- und Empfangsleitungen über Kreuz verbunden, der Sendeausgang des einen
geht also jeweils auf den Empfangseingang des anderen.

Die eigentliche Leistung steckt im Pumpenteil. Jede der vier Pumpen wird von
einem N-Kanal-MOSFET geschaltet, der über einen Gate-Vorwiderstand am
entsprechenden Pin des Nano hängt. Der MOSFET arbeitet als schneller Schalter
zwischen der Pumpe und Masse. Parallel zu jeder Pumpe liegt eine Schottky-Diode
in Sperrrichtung. Schaltet der MOSFET ab, will die Induktivität des Motors den
Strom weitertreiben und erzeugt eine Spannungsspitze. Die Diode leitet diesen
Strom im Kreis und schützt so MOSFET und Mikrocontroller vor Beschädigung.

Wichtig ist außerdem die Stromversorgung. Die Pumpen ziehen vergleichsweise viel
Strom und werden deshalb aus einer eigenen 5-V-Quelle (Power-Plug) gespeist, die
von der Versorgung der Mikrocontroller getrennt ist. Beide Kreise teilen sich
aber eine gemeinsame Masse, damit die Steuersignale ein gemeinsames Bezugspotential
haben. Diese Trennung verhindert, dass die Anlaufströme der Motoren die
Mikrocontroller stören oder zurücksetzen. Der Buzzer hängt direkt an einem
weiteren Ausgangspin des Nano und gibt am Ende des Mixens das akustische Signal.

#pagebreak()

// ============================================================
//  5 · REALER AUFBAU (HARDWARE-FOTOS)
// ============================================================
= Der reale Aufbau

Die Box ist aus OSB-Platten gebaut, die Bedien- und Spiel-Panels sind
3D-gedruckt. Die folgenden Fotos zeigen den fertigen Prototyp. Im Inneren sitzen
oben die vier Pumpen, von denen je ein Schlauch nach unten zum gemeinsamen
Ausguss führt. Vorne gibt es ein Bedienpanel mit drei Tastern (Next, Clean,
Random), an den beiden Seiten je ein ausklappbares Spiel-Panel mit den Tasten
für Rock, Paper und Scissors.

#figure(
  grid(columns: (1fr, 1fr), gutter: 10pt, row-gutter: 12pt,
    image("IOT/hw_innen.png", width: 90%),
    image("IOT/hw_front.png", width: 90%),
    image("IOT/hw_panel1.jpg", width: 100%),
    image("IOT/hw_panel2.jpg", width: 100%),
  ),
  caption: [Oben links das Innenleben mit den vier Pumpen und der
  Schlauchführung zum Ausguss, oben rechts die Front mit dem Bedienpanel und dem
  Ausguss darunter. Unten die beiden 3D-gedruckten Spiel-Panels mit den Tastern
  für Rock, Paper und Scissors.],
)

// ============================================================
//  6 · ABLAUF IN DER APP
// ============================================================
= Bedienung und Ablauf in der App

Von der Zutaten-Eingabe bis zum fertigen Drink führt die App durch sechs
Schritte. Die Schritte 1 und 2 finden vorab in der App statt, hier wird die Box
befüllt und die KI erzeugt die Rezepte. Die Schritte 3 bis 6 laufen dann am
Gerät und in der App zusammen, vom Verbinden über das Duell bis zum fertigen
Drink.

Auf den folgenden Seiten ist der Ablauf paarweise dargestellt. Jede der drei
Doppelseiten behandelt zwei zusammengehörige Schritte und zeigt darunter die
beiden passenden App-Screenshots nebeneinander, links der jeweils erste, rechts
der zweite Bildschirm. So lässt sich der beschriebene Ablauf direkt mit der
Oberfläche der App vergleichen.

#pagebreak()

== Zutaten eintragen und KI-Rezepte (Schritt 1 und 2)

Zuerst trägt man pro Pumpe ein, welches Getränk gerade angeschlossen ist (zum
Beispiel Rum, Orangensaft, Wodka, Ananassaft). Dieser Schritt ist wichtig, weil
die Maschine nur dann sinnvolle Drinks mixen kann, wenn sie weiß, was real in den
Flaschen steckt. Aus diesen vier Zutaten generiert die KI anschließend mögliche
Cocktails, jeweils mit Name, den Mengen in Milliliter, einer kurzen Beschreibung
und einem Serviervorschlag. Gemixt wird dabei immer nur, was auch wirklich
angeschlossen ist, die KI bleibt also im Rahmen des Möglichen und schlägt keine
Zutaten vor, die gar nicht vorhanden sind.

Der linke Screenshot zeigt die Eingabemaske für die vier Pumpen, der rechte die
Liste der daraus erzeugten Rezepte.

#figure(
  grid(columns: (1fr, 1fr), gutter: 12pt,
    image("IOT/pic_01.png", width: 100%),
    image("IOT/pic_02.png", width: 100%),
  ),
  caption: [Links die Eingabe der Pumpen-Belegung („What's in the box?“), rechts
  die daraus generierten KI-Rezepte mit ml-Mengen.],
)

#pagebreak()

== Start und Fotos (Schritt 3 und 4)

Sind die Rezepte vorbereitet, geht es an das eigentliche Spiel. Die App zeigt
oben den BLE-Status an, sodass man sofort sieht, ob die Verbindung zur Box steht.
Mit „Start Game“ sendet sie den Befehl #code("start"), den der ESP32 mit
#code("start_ok") quittiert. Damit ist das Spiel scharf geschaltet.

Anschließend nimmt jeder der beiden Spieler ein Foto von sich auf. Diese Fotos
sind die Grundlage für den personalisierten KI-Drink des Verlierers, denn die KI
liest später aus dem Bild eine Stimmung heraus und stimmt den Cocktail darauf ab.
Der linke Screenshot zeigt den Startbildschirm mit dem BLE-Status, der rechte die
Foto-Aufnahme für beide Spieler.

#figure(
  grid(columns: (1fr, 1fr), gutter: 12pt,
    image("IOT/pic_03.png", width: 100%),
    image("IOT/pic_04.png", width: 100%),
  ),
  caption: [Links der Startbildschirm mit BLE-Status, rechts die Foto-Aufnahme
  für beide Spieler.],
)

#pagebreak()

== Duell und KI-Drink (Schritt 5 und 6)

Nun folgt das Duell. Jeder Spieler drückt an seinem Panel Schere, Stein oder
Papier. Der ESP32 wertet die Runde aus und schickt das Ergebnis
(#code("runde_x_y_z")) an die App, die den Punktestand live anzeigt. Gespielt
wird nach dem Best-of-Three-Prinzip, gewonnen hat also, wer zuerst zwei Runden
für sich entscheidet.

Steht der Verlierer fest, kommt die KI ins Spiel. Aus dessen Foto und den
vorhandenen Zutaten generiert sie einen individuellen Cocktail mit Name,
Charakter-Tags und festen Mengen. Diese Mengen werden in Pump-Laufzeiten
umgerechnet und an die Box geschickt, die den Drink danach mixt und ausgibt. Der
linke Screenshot zeigt das Live-Ergebnis während des Mixens, der rechte den
fertig bestätigten Drink.

#figure(
  grid(columns: (1fr, 1fr), gutter: 12pt,
    image("IOT/pic_05.png", width: 100%),
    image("IOT/pic_06.png", width: 100%),
  ),
  caption: [Links das Live-Ergebnis während des Mixens, rechts der bestätigte
  Drink mit Name, Charakter-Tags und Mengen.],
)

// ============================================================
//  6 · SOFTWARE
// ============================================================
= Beschreibung der Software

Das System besteht aus drei unabhängigen Codebasen, die über klar definierte
Schnittstellen zusammenarbeiten. Das sind die ESP32-Firmware, die
Arduino-Nano-Firmware (beide PlatformIO/Arduino, C++) und die Flutter-App (Dart).
Jede Codebasis hat eine klar abgegrenzte Aufgabe und kennt von den anderen nur
die ausgetauschten Textbefehle, nicht deren Interna. Das hält die Teile
unabhängig, erlaubt getrenntes Testen und macht es einfach, einen Baustein zu
ändern, ohne die anderen anzufassen.

Die Aufgaben sind dabei nach der jeweiligen Stärke der Plattform verteilt. Das
Smartphone bringt Display, Kamera und Rechenleistung für die KI mit und
übernimmt deshalb die gesamte Benutzerführung. Der ESP32 ist das Bindeglied mit
Funk und genügend Logik für das Spiel. Der Arduino Nano kümmert sich nur um das
zeitkritische, präzise Schalten der Pumpen. Im Folgenden ist jede der drei
Codebasen kurz beschrieben.

== Programm

=== Der zentrale Knoten ESP32

Der ESP32 ist das Herzstück der Box und läuft in einer Endlosschleife, die
ständig auf Bluetooth-Nachrichten der App horcht und je nach Befehl reagiert. Er
übernimmt dabei vier Aufgaben.

- Taster einlesen mit einer einfachen Entprellung über
  #code("pressedStable()"), die nach erkanntem Druck 10 ms wartet und erneut
  prüft. So werden mechanische Prellschwingungen der Taster ausgefiltert und
  jeder Tastendruck nur einmal gewertet.
- Spiellogik (Best of Three). In einer Schleife sammelt er pro Runde die
  Eingaben beider Spieler und baut daraus die Nachricht #code("runde_x_y_z").
- BLE-Server. Er stellt den Nordic UART Service bereit, über den die App Befehle
  schickt und empfängt.
- UART-Relay. Den fertigen Mix-Befehl reicht er unverändert an den Nano weiter
  und wartet auf dessen Quittung, bevor er das Ergebnis an die App zurückmeldet.

=== Der Pumpen-Treiber Arduino Nano

Der Nano hört über eine #code("SoftwareSerial")-Verbindung (Pins 8/9, 9600 Baud)
auf den ESP32. Empfängt er einen #code("mix_a_b_c_d")-Befehl, zerlegt er ihn in
vier Laufzeiten (in Millisekunden) und schaltet die Pumpen nacheinander für die
jeweilige Dauer ein. Ist eine Nachricht fehlerhaft, antwortet er mit
#code("mix_err"), damit der ESP nicht in einen Timeout läuft. Nach erfolgreichem
Mix sendet er #code("mix_ok") und quittiert akustisch über den Buzzer. Bewusst
hält der Nano keine eigene Spiellogik vor, er ist reiner Befehlsempfänger und
führt nur aus, was er bekommt. Das macht sein Verhalten vorhersehbar und die
Fehlersuche einfach.

=== Die Flutter-App für Steuerung und Anzeige

Die App ist „feature-first“ aufgebaut (`home`, `game`, `recipes`). Die
BLE-Kommunikation kapselt ein zentraler #code("BleService") (Singleton). Darauf
setzen #code("BleBackendService") (Rundenergebnisse) und #code("BleMixerService")
(Mix-Befehl) auf. Die App übernimmt die Pumpen-Belegung, zeigt die KI-Rezepte
an, stellt die BLE-Verbindung her, nimmt die Fotos auf, stellt den Punktestand
live dar und löst am Ende den Drink-Befehl aus. Ein Test-Modus erlaubt die
Entwicklung ohne Hardware, indem eingehende BLE-Nachrichten simuliert werden.

#pagebreak()

== Kommunikation

Alle Knoten tauschen bewusst kurze Text-Kommandos aus. Das ist leicht zu
debuggen und macht das Protokoll unabhängig vom Transport (ob BLE oder UART).
Jeder Befehl wird mit einem #code("_ok") quittiert, ein bestätigtes Handshake.
@fig-seq zeigt den vollständigen Ablauf zwischen der App (Frontend), dem ESP32
und dem Nano.

#figure(
  image("IOT/sequence_diagram.png", width: 80%),
  caption: [Kommunikations-Sequenzdiagramm mit Handshake, Runden-Schleife und
  Mix-Relay zwischen App, ESP32 und Nano.],
) <fig-seq>

Das Diagramm liest sich von oben nach unten als zeitlicher Ablauf. Nach dem
Spielstart sendet die App #code("start"), der ESP32 bestätigt mit
#code("start_ok"). In der mittleren Schleife schickt der ESP32 pro Runde das
Ergebnis als #code("runde_x") und wartet auf die Quittung #code("runde_ok") der
App, erst dann beginnt die nächste Runde. Steht der Verlierer fest, läuft der
Drink-Befehl über den ESP32 zum Nano, der mixt und mit #code("mix_ok")
zurückmeldet. Danach kehrt das System in den Wartezustand zurück.

Die Gesten sind als Zahlen kodiert, wobei #code("0") für Stein, #code("1") für
Papier und #code("2") für Schere steht. Die vier Felder in #code("mix_a_b_c_d")
sind die Laufzeiten für Pumpe 0 bis 3.

#pagebreak()

== Externe Services und KI <services>

Die „Intelligenz“ des Automaten läuft bewusst on-device, also direkt auf dem
Smartphone. Für die Rezept-Generierung bindet die App über das Paket
#code("flutter_gemma") ein kleines Sprachmodell ein (Gemma 3 1B, 4-Bit). Dieses
Modell wird beim ersten Start über die WLAN-Verbindung des Smartphones aus einem
Cloud-Modell-Repository (Hugging Face) heruntergeladen und danach lokal
ausgeführt. Das ist die kabellose WiFi-Verbindung zur Cloud. Zur Laufzeit
braucht die Rezept-Erzeugung dann kein Netz mehr, was die Antworten schnell und
unabhängig von der Internetqualität macht.

Die KI wird an zwei Stellen genutzt und liefert beide Male strukturierte,
maschinenlesbare Rezepte (Mengen in ml) statt Fließtext, sodass sich die Antwort
direkt in Pump-Laufzeiten übersetzen lässt.

#table(
  columns: (1fr, 1fr),
  align: left + top,
  table.header([1 · Rezepte aus Zutaten (Gemma)], [2 · Personalisierter Drink (ML Kit)]),
  [Als Eingabe dienen die vier Pumpen-Getränke. Das Sprachmodell kombiniert sie
   zu sinnvollen Cocktails. Heraus kommen Name, ml-Mengen und ein Servier-Tipp.],
  [Aus dem Foto des Verlierers liest Google ML Kit (Gesichtserkennung und
   Bild-Labeling) den „Vibe / Look“. Daraus wählt die App einen passenden Drink
   mit Charakter-Tags.],
)

Beide KI-Bausteine, das Gemma-Sprachmodell und Google ML Kit, arbeiten nach dem
einmaligen Modell-Download komplett offline auf dem Gerät. Wichtig dabei ist,
dass nur gemixt wird, was wirklich angeschlossen ist. Die KI bleibt im Rahmen
der vorhandenen Zutaten. Findet die App das Modell nicht, fällt sie automatisch
auf einen einfachen, regelbasierten Generator zurück, sodass der Ablauf immer
funktioniert.

// ============================================================
//  7 · HERAUSFORDERUNGEN & FAZIT
// ============================================================
= Technische Herausforderungen

Beim Bauen sind wir auf einige Stolpersteine gestoßen, die für ein IoT-System
typisch sind.

#table(
  columns: (auto, 1fr),
  align: (left + top, left + top),
  table.header([Bereich], [Herausforderung]),
  [BLE-Verbindung],
  [Stabiles Pairing zwischen App und ESP32, sauberer Reconnect nach einem
   Abbruch und ein konsistentes Zustands-Handling, damit die App nach einem
   Neustart nicht hängen bleibt.],
  [ESP32 ↔ Arduino],
  [Zuverlässige serielle Kommunikation und Synchronisation zweier
   Mikrocontroller über ein klares Befehls-/Quittungs-Protokoll
   (#code("mix_ok") / #code("mix_err")).],
  [Pumpen-Dosierung],
  [Milliliter korrekt in Pump-Laufzeiten umrechnen, jede Pumpe einzeln
   kalibrieren und über die _Clean_-Funktion ein Vermischen der Getränke
   verhindern.],
  [KI-Integration],
  [Verlässlich strukturierte Antworten von der KI erzwingen und die Antwortzeit
   kurz halten, damit das Spielerlebnis flüssig bleibt.],
)

#pagebreak()

// ============================================================
//  8 · KOSTENAUFSTELLUNG
// ============================================================
= Kostenaufstellung

Die Hardware für den Automaten wurde im Team beschafft. Die folgende Aufstellung
listet die Materialkosten nach Besteller auf. Insgesamt belaufen sich die Kosten
auf *124,44 €*, was bei vier Personen rund *31,11 € pro Person* entspricht.

#let kostenblock(name, posten, gesamt) = block(breakable: false, width: 100%)[
  #text(weight: "bold", fill: accent, size: 10.5pt)[#name]
  #v(0.3em)
  #table(
    columns: (1fr, auto),
    inset: (x: 5pt, y: 4.5pt),
    align: (left + horizon, right + horizon),
    stroke: 0.5pt + rule,
    table.header([Posten], [Preis]),
    ..posten.map(((p, pr)) => (text(size: 9.5pt)[#p], text(size: 9.5pt)[#pr])).flatten(),
    table.cell(fill: accent.lighten(92%))[*Gesamt*],
    table.cell(fill: accent.lighten(92%), align: right)[*#gesamt*],
  )
]

#grid(
  columns: (1fr, 1fr, 1fr),
  column-gutter: 10pt,
  kostenblock("Elias", (
    ("TOF-Sensoren", "11,09 €"),
    ("FQP30N06L MOSFET", "14,77 €"),
    ("Tactile Push Button", "8,95 €"),
    ("Getränkepumpen", "42,18 €"),
    ("3D-Druck", "0,50 €"),
  ), "77,49 €"),
  kostenblock("Haris", (
    ("Klettverschluss", "14,95 €"),
    ("Div. Kleinteile", "10,00 €"),
  ), "24,95 €"),
  kostenblock("Felix", (
    ("Holz", "15,00 €"),
    ("Winkel", "5,00 €"),
    ("Div. Kleinteile", "2,00 €"),
  ), "22,00 €"),
)

#v(0.6em)

#note[
  *Gesamtkosten:* 77,49 € + 24,95 € + 22,00 € = *124,44 €* · bei 4 Personen
  ≈ *31,11 € pro Person.*
]

// ============================================================
//  9 · FAZIT
// ============================================================
= Fazit und Ausblick

Entstanden ist ein funktionierender, vernetzter Getränkeautomat, der
Hardware-Spiel, Mobile-App und On-Device-KI über ein schlankes IoT-Protokoll
(ESP32 und Arduino Nano) zu einem durchgängigen Erlebnis verbindet. Alle fünf
geforderten Anforderungen sind nicht bloß angehängt, sondern erfüllen im
Gesamtsystem eine echte Funktion.

Am lehrreichsten war das Lösen vieler kleiner, vorab kaum sichtbarer Probleme.
Die Kommunikation zwischen den Komponenten verlangte sauberes Handling von
Timeouts und Quittungen, die Dosierung eine einzelne Kalibrierung jeder Pumpe,
und die KI-Integration mehrere Anläufe, bis die Antworten verlässlich
strukturiert und schnell genug vorlagen. Dabei haben wir viel über das
Zusammenspiel von Hardware, Software und App in einem realen IoT-System gelernt,
das mehr ist als die Summe seiner einzeln getesteten Teile.

Für die Zukunft sind außerdem mehrere Erweiterungen denkbar.

- *Mehr Sensorik.* Füllstand-Sensoren an den Flaschen und eine Becher-Erkennung,
  die den Ausschank erst bei platziertem Becher freigibt.
- *Cloud und Statistik.* Spielhistorie, Bestenlisten und Fern-Monitoring der
  Maschine über ein Web-Dashboard.
- *Mehrspieler und Modi.* Turniere, mehr als zwei Spieler und alternative Spiele
  zur Drink-Entscheidung.
