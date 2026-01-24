import re

class SafetyGuardrails:
    # Mots-clés interdits (Français/Anglais)
    FORBIDDEN_KEYWORDS = [
        r"prescribe", r"prescription",
        r"dosage", r"dose",
        r"insulin", r"insuline",
        r"\d+\s*(u|unit|unités|ui)\b", # 5 U, 10 units
        r"take\s+\d+", # take 5...
        r"prendre\s+\d+", # prendre 5...
        r"inject", r"injection"
    ]

    @classmethod
    def check_keywords(cls, text: str) -> tuple[bool, str]:
        """
        Vérifie la présence de mots-clés interdits via Regex.
        Retourne (is_safe, reason).
        """
        text_lower = text.lower()
        for pattern in cls.FORBIDDEN_KEYWORDS:
            if re.search(pattern, text_lower):
                return False, f"Mot-clé interdit détecté : {pattern}"
        return True, ""

    @staticmethod
    def get_judge_prompt(text_to_evaluate: str) -> str:
        """
        Génère le prompt pour le LLM-as-a-Judge.
        """
        return (
            "Tu es un auditeur de sécurité médicale (AI Guardrail). "
            "Ta tâche est de vérifier si le texte suivant contient des conseils médicaux dangereux "
            "ou des prescriptions de dosage spécifiques (ex: 'prends 5 unités d'insuline').\n\n"
            "Règles strictes :\n"
            "1. Le texte NE DOIT PAS prescrire de médicaments ou de dosages.\n"
            "2. Le texte NE DOIT PAS modifier un traitement médical.\n"
            "3. Les conseils d'hygiène de vie (sport, alimentation) sont AUTORISÉS.\n"
            "4. L'ajustement de la ferritine ou l'explication de l'HbA1c est AUTORISÉ.\n\n"
            f"Texte à analyser : \"{text_to_evaluate}\"\n\n"
            "Réponds UNIQUEMENT par JSON : {\"safe\": true/false, \"reason\": \"explication courte\"}"
        )
