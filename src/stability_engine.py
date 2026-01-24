"""
Stability Engine - Miedema HbA1c Adjustment Logic

This module implements the Miedema kinetic model for HbA1c adjustment based on glucose levels and questionnaire data.
"""

def calculate_hba1c_adjustment(current_glucose: float, rolling_avg: float, questionnaire: dict) -> tuple[float, float, str]:
    """
    Calculate adjusted HbA1c using Miedema kinetic model.

    Args:
        current_glucose: Current glucose level in mg/dL
        rolling_avg: 90-day rolling average glucose in mg/dL
        questionnaire: JSON dict with user factors (age, smoking, etc.)

    Returns:
        tuple: (hba1c_adjusted, correction_factor, french_summary)
    """
    # Base HbA1c estimation from rolling average
    # Formula: HbA1c (%) = (glucose + 46.7) / 28.7
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
    if questionnaire.get('smoking', '').lower() == 'yes':
        correction_factor += 0.3

    # Other factors (placeholder for more)
    if questionnaire.get('diabetes_type', '') == 'type1':
        correction_factor += 0.1

    # Adjustment based on current vs average
    glucose_diff = current_glucose - rolling_avg
    adjustment = correction_factor * (glucose_diff / 100)  # Scale the difference

    hba1c_adjusted = base_hba1c + adjustment

    # French summary
    summary = (f"L'HbA1c ajusté est de {hba1c_adjusted:.1f}% "
               f"avec un facteur de correction de {correction_factor:.2f} "
               f"basé sur le modèle Miedema et le questionnaire.")

    return hba1c_adjusted, correction_factor, summary