import json
import statistics

def analyze_json_file(filename):
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            content = json.load(f)
            
        data = content.get("data", [])
        print(f"Analyse de {len(data)} points...")
        
        values = []
        for point in data:
            # Filtre sur le status (Index 5)
            # Hypothèse: 0.0 = Valid, autre = Calibration/Erreur
            status = float(point[5])
            if status != 0.0:
                continue

            val = float(point[3]) # Index 3
            values.append(val)
            
        if not values:
            print("Aucune valeur trouvée.")
            return

        min_val = min(values)
        max_val = max(values)
        avg_val = statistics.mean(values)
        
        print(f"--- Statistiques Brutes (Source JSON) ---")
        print(f"Min: {min_val}")
        print(f"Max: {max_val}")
        print(f"Moyenne: {avg_val:.2f}")
        
        # Test Hypothèses
        if avg_val < 20:
            print("=> HYPOTHÈSE: Les données sont en mmol/L.")
            print(f"   Moyenne convertie (x18.0182) : {avg_val * 18.0182:.2f} mg/dL")
        else:
            print("=> HYPOTHÈSE: Les données sont déjà en mg/dL.")

    except Exception as e:
        print(f"Erreur: {e}")

if __name__ == "__main__":
    analyze_json_file("medtrum_data_2026-02-04.json")
