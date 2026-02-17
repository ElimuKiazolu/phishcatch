import re

def analyze_text(content: str):
    score = 0
    indicators = []

    urgency_keywords = ["urgent", "act now", "limited time", "immediately"]
    reward_keywords = ["you won", "congratulations", "free money", "claim now"]
    financial_keywords = ["bank", "credit card", "payment", "crypto", "loan"]
    impersonation_keywords = ["hr department", "placement cell", "official notice"]

    suspicious_domains = ["bit.ly", "tinyurl", "goo.gl", "t.co"]

    content_lower = content.lower()

    # Urgency Detection
    for word in urgency_keywords:
        if word in content_lower:
            score += 15
            indicators.append(f"Urgency phrase detected: '{word}'")

    # Reward Detection
    for word in reward_keywords:
        if word in content_lower:
            score += 20
            indicators.append(f"Reward bait detected: '{word}'")

    # Financial Detection
    for word in financial_keywords:
        if word in content_lower:
            score += 10
            indicators.append(f"Financial keyword detected: '{word}'")

    # Impersonation Detection
    for word in impersonation_keywords:
        if word in content_lower:
            score += 15
            indicators.append(f"Impersonation indicator detected: '{word}'")

    # URL Detection
    urls = re.findall(r'(https?://\S+)', content)
    for url in urls:
        for domain in suspicious_domains:
            if domain in url:
                score += 20
                indicators.append(f"Suspicious shortened URL detected: '{url}'")

    # Excessive Capital Letters
    if content.isupper():
        score += 10
        indicators.append("Message contains excessive capital letters")

    # Risk Level Determination
    if score < 30:
        level = "Low"
    elif score < 60:
        level = "Medium"
    else:
        level = "High"

    advice = "Avoid clicking unknown links and verify directly from official sources."

    return {
        "risk_score": min(score, 100),
        "risk_level": level,
        "indicators": indicators,
        "advice": advice
    }
