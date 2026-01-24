"""
Stability Engine - Miedema HbA1c Adjustment Logic

This module implements the Miedema kinetic model for HbA1c adjustment based on glucose levels and questionnaire data.
"""

from app.models.schemas import LabData, LifestyleProfile

def adjust_hba1c(lab: LabData, lifestyle: LifestyleProfile) -> dict:
    """
    Ticket B05: Adjustment of HbA1c based on physiological factors (Miedema simplified rules).
    
    Rules:
    - Ferritin < 30 ng/mL -> Positive bias (Measured HbA1c is artificially high) -> Correction: subtract
    - Athlete or Blood Event -> Negative bias (Measured HbA1c is artificially low) -> Correction: add
    
    Formula:
    hba1c_adjusted = hba1c_measured + correction_factor
    """
    correction_factor = 0.0
    summary_parts = []
    
    # Rule 1: Ferritin < 30 -> Positive bias (measured > actual)
    # We need to lower the value to get the true HbA1c.
    if lab.ferritin is not None and lab.ferritin < 30:
        # Bias estimated at +0.5% (common for iron deficiency anemia)
        # So we apply a negative correction.
        correction_factor -= 0.5
        summary_parts.append("Ferritine basse (<30) -> HbA1c mesurée surestimée (-0.5%).")
        
    # Rule 2: Athlete OR Blood Event -> Negative bias (measured < actual)
    # We need to raise the value.
    if lifestyle.is_athlete or lab.blood_event:
        # Bias estimated at -0.5% (due to increased RBC turnover)
        # So we apply a positive correction.
        correction_factor += 0.5
        reason = "Athlète" if lifestyle.is_athlete else "Perte de sang récente"
        if lifestyle.is_athlete and lab.blood_event:
            reason = "Athlète & Perte de sang"
        summary_parts.append(f"{reason} -> HbA1c mesurée sous-estimée (+0.5%).")
    
    # Calculate adjusted HbA1c
    hba1c_adjusted = lab.hba1c + correction_factor
    
    # Analysis Summary
    if not summary_parts:
        analysis_summary = "Aucun facteur d'interférence détecté. HbA1c fiable."
    else:
        analysis_summary = " ".join(summary_parts)
        
    return {
        "hba1c_adjusted": round(hba1c_adjusted, 2),
        "correction_factor": round(correction_factor, 2),
        "analysis_summary": analysis_summary
    }

def estimate_hba1c_from_glucose(avg_glucose: float) -> float:
    """
    Estimate HbA1c from Average Glucose using Miedema formula.
    HbA1c = (AvgGlucose + 46.7) / 28.7
    """
    return (avg_glucose + 46.7) / 28.7

def analyze_stability(lab: LabData, lifestyle: LifestyleProfile, rolling_avg_90d: float) -> dict:
    """
    Complete Stability Analysis (Ticket T-M001 + B05).
    Combines:
    1. Lab HbA1c Adjustment (Bias correction).
    2. Estimated HbA1c from CGM data (Miedema).
    3. Gap analysis.
    """
    # 1. Adjust Lab HbA1c (Bias)
    lab_analysis = adjust_hba1c(lab, lifestyle)
    hba1c_lab_adjusted = lab_analysis["hba1c_adjusted"]
    
    # 2. Estimate from Glucose (CGM)
    hba1c_estimated = estimate_hba1c_from_glucose(rolling_avg_90d)
    
    # 3. Gap Analysis
    gap = hba1c_lab_adjusted - hba1c_estimated
    gap_analysis = ""
    
    if abs(gap) < 0.5:
        gap_analysis = "Cohérence excellente entre CGM et Labo."
    elif gap > 0.5:
        gap_analysis = f"HbA1c Labo plus élevée que prévu (+{gap:.2f}%). Glycation rapide possible ou pics post-prandiaux manqués."
    else:
        gap_analysis = f"HbA1c Labo plus basse que prévu ({gap:.2f}%). Glycation lente ou hypoglycémies fréquentes."

    return {
        **lab_analysis,
        "hba1c_estimated_from_cgm": round(hba1c_estimated, 2),
        "gap": round(gap, 2),
        "gap_analysis": gap_analysis,
        "rolling_avg_90d": round(rolling_avg_90d, 1)
    }
