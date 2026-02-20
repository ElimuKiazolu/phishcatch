import re

SUSPICIOUS_KEYWORDS = [
    "login", "verify", "secure", "update",
    "support", "account", "bank", "paypal"
]

BRAND_PATTERNS = [
    "google", "facebook", "paypal", "amazon"
]

def analyze_url(content: str):
    url = content.lower()
    score = 0
    indicators = []

    # 1️⃣ Suspicious keywords
    for word in SUSPICIOUS_KEYWORDS:
        if word in url:
            score += 2
            indicators.append(f"Contains suspicious keyword: {word}")

    # 2️⃣ Brand impersonation
    for brand in BRAND_PATTERNS:
        if brand in url:
            # If brand + hyphen = suspicious
            if "-" in url:
                score += 3
                indicators.append(f"Possible brand impersonation: {brand}")

    # 3️⃣ Numbers replacing letters (simple detection)
    if re.search(r"[0-9]", url):
        score += 1
        indicators.append("Contains numeric characters")

    # Risk levels
    if score >= 5:
        level = "High"
    elif score >= 3:
        level = "Medium"
    else:
        level = "Low"

    return {
        "risk_score": score,
        "risk_level": level,
        "indicators": indicators,
        "advice": "Avoid clicking unknown links and verify directly from official sources."
}