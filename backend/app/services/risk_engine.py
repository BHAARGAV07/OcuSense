from typing import Dict, Any
from app.services.rule_engine import RuleEngine


class RiskEngine:
    @staticmethod
    def calculate_risk(combined_data: Dict[str, Any], observation_count: int = 10) -> Dict[str, Any]:
        """
        RESEARCH / LEGACY RULE-BASED ENGINE.

        Preserved for historical comparisons only. The primary
        /api/analysis/risk endpoint uses the ML prediction pipeline instead.

        Takes RuleEngine contributions and produces a final score (0-100),
        risk_level (low/moderate/high/very high), and contributing factors list.
        """
        rule_eval = RuleEngine.evaluate_rules(combined_data, observation_count=observation_count)
        raw_score = rule_eval["raw_score"]
        contributing_factors = rule_eval["contributing_factors"]

        # Normalize score between 0 and 100
        risk_score = min(100, max(0, raw_score))

        # Map to Risk Level
        if risk_score <= 25:
            risk_level = "low"
        elif risk_score <= 50:
            risk_level = "moderate"
        elif risk_score <= 75:
            risk_level = "high"
        else:
            risk_level = "very high"

        return {
            "risk_score": risk_score,
            "risk_level": risk_level,
            "contributing_factors": contributing_factors,
            "observation_count": observation_count,
            "insufficient_data": rule_eval["insufficient_data"]
        }
