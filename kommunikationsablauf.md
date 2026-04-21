
1. Spielstart über App
  - Erhebung von Spielernamen und Bildern
  - BLE -> "start"
  - BLE <- "start_ok"
2. ESP: 3 Runden:
  - Auswahl des Zuges von beiden Personen
  - erst dann: BLE -> "runde_x_y_z"

  | **x** | **y** | **z** |
  |---|---|---|
  | Runde | Auswahl Spieler 1 (0, 1, 2) | Auswahl Spieler 2 (0, 1, 2) |

  - BLE <- "runde_ok" 
  - nächste Runde
3. Auswertung des Spieles durch App, danach:
  - BLE -> "mix_a_b_c_d"
  
  | **a** | **b** | **c** | **d** |
  |---|---|---|---|
  | Menge Pumpe 0 | Menge Pumpe 1 | Mende Pumpe 2 | Menge Pumpe 3 |

  - Serial (nano) -> "mix_a_b_c_d"
  - wenn fertig: Serial <- "mix_ok"
  - BLE -> "mix_ok"
4. warten auf neuen Rundenstart
