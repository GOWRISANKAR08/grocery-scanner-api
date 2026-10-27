"""Open Food Facts client (free product database)."""
import json
import httpx
from sqlalchemy.orm import Session
from . import config, models

FIELDS = ("code,product_name,brands,image_front_url,categories_tags,ingredients_text,"
          "nutriments,nova_group,additives_tags")


def _to_model(p: dict) -> models.Product:
    cats = p.get("categories_tags") or []
    return models.Product(
        barcode=p.get("code"),
        name=p.get("product_name") or "Unknown product",
        brand=(p.get("brands") or "").split(",")[0],
        image_url=p.get("image_front_url"),
        category=cats[-1] if cats else None,
        ingredients_text=p.get("ingredients_text") or "",
        nutriments_json=json.dumps(p.get("nutriments") or {}),
        nova_group=p.get("nova_group"),
        additives_json=json.dumps(p.get("additives_tags") or []),
    )


async def get_product(db: Session, barcode: str) -> models.Product | None:
    cached = db.get(models.Product, barcode)
    if cached:
        return cached
    async with httpx.AsyncClient(timeout=15) as c:
        r = await c.get(f"{config.OFF_BASE}/api/v2/product/{barcode}.json", params={"fields": FIELDS})
    if r.status_code != 200:
        return None
    data = r.json()
    if data.get("status") != 1:
        return None
    prod = _to_model(data["product"])
    db.merge(prod)
    db.commit()
    return prod


async def search_category(category_tag: str, limit: int = 20) -> list[dict]:
    params = {"categories_tags_en": category_tag.replace("en:", ""), "fields": FIELDS,
              "page_size": limit, "sort_by": "unique_scans_n"}
    async with httpx.AsyncClient(timeout=15) as c:
        r = await c.get(f"{config.OFF_BASE}/api/v2/search", params=params)
    if r.status_code != 200:
        return []
    return r.json().get("products", [])
