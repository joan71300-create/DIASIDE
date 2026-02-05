import sys
import os
from sqlalchemy import func

# Add project root to path
sys.path.append(os.getcwd())

from app.models.database import SessionLocal
from app.models import models

def audit_hba1c():
    db = SessionLocal()
    
    # 1. Nombre total de mesures
    count = db.query(models.GlucoseEntry).count()
    if count == 0:
        print("❌ Aucune donnée en base.")
        return

    # 2. Moyenne Glycémique (mg/dL)
    avg_glucose = db.query(func.avg(models.GlucoseEntry.value)).scalar()
    avg_glucose = float(avg_glucose)
    
    # 3. Calcul HbA1c (ADAG Formula)
    # eA1c = (Avg + 46.7) / 28.7
    my_calc = (avg_glucose + 46.7) / 28.7
    
    # 4. Calcul Inverse pour trouver la moyenne correspondant à 6.9%
    # 6.9 = (Avg + 46.7) / 28.7  =>  Avg = (6.9 * 28.7) - 46.7
    target_avg_for_69 = (6.9 * 28.7) - 46.7

    print(f"Audit des Donnees Medtrum importees :")
    print(f"- Nombre de points : {count}")
    print(f"- Moyenne DIASIDE : {avg_glucose:.2f} mg/dL")
    print(f"- HbA1c Estimee DIASIDE : {my_calc:.2f} %")
    print(f"------------------------------------------------")
    print(f"Comparaison EasyView (6.9%) :")
    print(f"- Pour avoir 6.9%, la moyenne devrait etre de : {target_avg_for_69:.2f} mg/dL")
    print(f"- Ecart de moyenne : {avg_glucose - target_avg_for_69:.2f} mg/dL")

if __name__ == "__main__":
    audit_hba1c()
