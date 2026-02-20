import re

SUSPICIOUS_KEYWORDS = [
    "login", "verify", "secure", "update",
    "support", "account", "bank", "paypal"
]

BRAND_PATTERNS = [
    "google", "facebook", "paypal", "amazon", "microsoft"
]

def simple_distance(a: str, b: str) -> int:
    # Basic character difference count (not full Levenshtein)
    return sum(1 for x, y in zip(a, b) if x != y) + abs(len(a) - len(b))

def analyze_text(content: str):
    url = content.lower()
    score = 0
    indicators = []

    # 1️⃣ Suspicious keywords
    for word in SUSPICIOUS_KEYWORDS:
        if word in url:
            score += 2
            indicators.append(f"Contains suspicious keyword: {word}")

    # 2️⃣ Brand impersonation (hyphen based)
    for brand in BRAND_PATTERNS:
        if brand in url and "-" in url:
            score += 3
            indicators.append(f"Possible brand impersonation: {brand}")

    # 3️⃣ Typosquatting detection
    domain_part = url.split(".")[0]

    for brand in BRAND_PATTERNS:
        if brand not in domain_part:
            distance = simple_distance(domain_part, brand)
            if distance <= 2:  # small typo
                score += 4
                indicators.append(f"Possible typosquatting of: {brand}")

    # 4️⃣ Numeric characters
    if re.search(r"[0-9]", url):
        score += 1
        indicators.append("Contains numeric characters")

    # Risk levels
    if score >= 6:
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