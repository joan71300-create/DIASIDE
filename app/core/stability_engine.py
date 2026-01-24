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

def calculate_hba1c_adjustment(current_glucose: float, rolling_avg: float, questionnaire: dict = None) -> tuple[float, float, str]:
    """
    Calculate adjusted HbA1c using Miedema kinetic model.

    Args:
        current_glucose: Current glucose level in mg/dL
        rolling_avg: 90-day rolling average glucose in mg/dL
        questionnaire: JSON dict with user factors (age, smoking, etc.)

    Returns:
        tuple: (hba1c_adjusted, correction_factor, french_summary)
    """
    if questionnaire is None:
        questionnaire = {}
        
    # Base HbA1c estimation from rolling average
    # Formula: HbA1c (%) = (glucose + 46.7) / 28.7
    # Note: rolling_avg represents MBG (Mean Blood Glucose)
    base_hba1c = (rolling_avg + 46.7) / 28.7

    # Calculate correction factor based on questionnaire
    correction_factor = 0.0

    # Age adjustment
    age = questionnaire.get('age', 0)
    if age > 60:
        correction_factor += 0.2
    elif age < 30:
        correction_factor -= 0.1

    # Smoking adjustment
    if questionnaire.get('is_smoker', False) or questionnaire.get('smoking', '').lower() == 'yes':
        correction_factor += 0.3

    # Other factors (placeholder for more)
    if questionnaire.get('diabetes_type', '') == 'type1':
        correction_factor += 0.1

    # Adjustment based on current vs average
    glucose_diff = current_glucose - rolling_avg
    
    # Simple adjustment model combining factors
    hba1c_adjusted = base_hba1c + correction_factor

    # French summary
    summary = (f"HbA1c calculée via Miedema : {hba1c_adjusted:.1f}% "
               f"(MBG: {rolling_avg:.0f} mg/dL).")

    return hba1c_adjusted, correction_factor, summary
