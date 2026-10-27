"""Health scoring. Heuristic, inspired by Nutri-Score; NOT medical advice.
Values are per 100g. Tune weights with your food-technology partner."""
from typing import List, Dict, Tuple

# E-number -> (name, risk 0 low..3 high, note)
ADDITIVES: Dict[str, Tuple[str, int, str]] = {
    "en:e211": ("Sodium benzoate", 2, "Preservative; may form benzene with vitamin C"),
    "en:e202": ("Potassium sorbate", 1, "Common preservative, generally low risk"),
    "en:e200": ("Sorbic acid", 1, "Common preservative"),
    "en:e210": ("Benzoic acid", 2, "Preservative; sensitivity in some people"),
    "en:e220": ("Sulphur dioxide", 2, "Sulphite; may trigger asthma"),
    "en:e250": ("Sodium nitrite", 3, "Cured-meat preservative; linked to health concerns"),
    "en:e249": ("Potassium nitrite", 3, "Cured-meat preservative"),
    "en:e320": ("BHA", 3, "Antioxidant preservative; possible endocrine concerns"),
    "en:e321": ("BHT", 2, "Antioxidant preservative"),
    "en:e330": ("Citric acid", 0, "Natural acidulant"),
    "en:e300": ("Ascorbic acid", 0, "Vitamin C"),
    "en:e621": ("MSG", 1, "Flavour enhancer"),
    "en:e951": ("Aspartame", 2, "Artificial sweetener"),
    "en:e950": ("Acesulfame K", 2, "Artificial sweetener"),
    "en:e102": ("Tartrazine", 2, "Synthetic colour; hyperactivity link in children"),
    "en:e129": ("Allura red", 2, "Synthetic colour"),
    "en:e171": ("Titanium dioxide", 3, "Colourant; banned in EU foods"),
}

HIGH_GI_WORDS = ["glucose syrup", "high fructose", "dextrose", "maltodextrin", "invert sugar", "corn syrup"]


def _n(nutr: dict, key: str) -> float:
    try:
        return float(nutr.get(key) or 0)
    except (TypeError, ValueError):
        return 0.0


def preservatives_from_tags(tags: List[str]) -> List[dict]:
    out = []
    for t in tags or []:
        t = t.lower()
        if t in ADDITIVES:
            name, risk, note = ADDITIVES[t]
            out.append({"code": t.replace("en:", "").upper(), "name": name, "risk": risk, "note": note})
        else:
            out.append({"code": t.replace("en:", "").upper(), "name": t.replace("en:", "").upper(), "risk": 1, "note": "Additive"})
    return sorted(out, key=lambda x: -x["risk"])


def overall_score(nutr: dict, additives: List[dict], nova: int | None) -> Tuple[float, Dict[str, float]]:
    energy = _n(nutr, "energy-kcal_100g")
    sugar = _n(nutr, "sugars_100g")
    sat = _n(nutr, "saturated-fat_100g")
    salt = _n(nutr, "salt_100g")
    fiber = _n(nutr, "fiber_100g")
    protein = _n(nutr, "proteins_100g")

    # Negative points (0-10 scale each, like Nutri-Score)
    neg_energy = min(energy / 80, 10)
    neg_sugar = min(sugar / 4.5, 10)
    neg_sat = min(sat / 1, 10)
    neg_salt = min(salt / 0.225, 10)
    # Positive points
    pos_fiber = min(fiber / 0.9, 5)
    pos_protein = min(protein / 1.6, 5)

    raw = 100 - (neg_energy + neg_sugar + neg_sat + neg_salt) * 2.0 + (pos_fiber + pos_protein) * 1.5
    add_pen = sum({0: 0, 1: 2, 2: 5, 3: 9}[a["risk"]] for a in additives)
    nova_pen = {1: 0, 2: 3, 3: 8, 4: 15}.get(nova or 0, 5)
    score = max(0.0, min(100.0, raw - add_pen - nova_pen))
    breakdown = {
        "energy_kcal": energy, "sugar_g": sugar, "saturated_fat_g": sat, "salt_g": salt,
        "fiber_g": fiber, "protein_g": protein, "additive_penalty": add_pen, "processing_penalty": nova_pen,
    }
    return round(score, 1), breakdown


def diabetic_score(nutr: dict, ingredients_text: str, base: float) -> float:
    sugar = _n(nutr, "sugars_100g")
    carbs = _n(nutr, "carbohydrates_100g")
    fiber = _n(nutr, "fiber_100g")
    net_carbs = max(carbs - fiber, 0)
    s = base - min(sugar * 2.2, 40) - min(net_carbs * 0.35, 25) + min(fiber * 2, 10)
    low = (ingredients_text or "").lower()
    if any(w in low for w in HIGH_GI_WORDS):
        s -= 12
    return round(max(0.0, min(100.0, s)), 1)


def grade(score: float) -> str:
    if score >= 80: return "A"
    if score >= 65: return "B"
    if score >= 50: return "C"
    if score >= 35: return "D"
    return "E"


def flags_for(nutr: dict, additives: List[dict], nova: int | None) -> List[str]:
    f = []
    if _n(nutr, "sugars_100g") > 15: f.append("High sugar")
    if _n(nutr, "salt_100g") > 1.5: f.append("High salt")
    if _n(nutr, "saturated-fat_100g") > 5: f.append("High saturated fat")
    if nova == 4: f.append("Ultra-processed")
    if any(a["risk"] >= 3 for a in additives): f.append("Contains high-risk additive")
    if _n(nutr, "fiber_100g") >= 6: f.append("High fibre")
    if _n(nutr, "proteins_100g") >= 10: f.append("Good protein")
    return f


def summary_text(score: float, g: str, flags: List[str]) -> str:
    base = {"A": "Excellent choice.", "B": "Good choice.", "C": "Okay in moderation.",
            "D": "Not great; limit intake.", "E": "Best avoided."}[g]
    return base + (" " + ", ".join(flags[:2]) + "." if flags else "")
