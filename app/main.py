import json
import uuid
import hmac
import hashlib
from datetime import datetime, timedelta
from collections import defaultdict
from fastapi import FastAPI, Depends, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session

from . import models, schemas, auth, config, scoring, off_client
from .database import Base, engine, get_db

Base.metadata.create_all(bind=engine)
app = FastAPI(title="Grocery Scanner API", version="1.0")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


@app.get("/")
def root():
    return {
        "status": "online",
        "message": "Grocery Scanner API is running!",
        "docs": "/docs",
        "health": "/health"
    }


# ---------- Auth ----------
@app.post("/auth/register", response_model=schemas.TokenOut)
def register(body: schemas.RegisterIn, db: Session = Depends(get_db)):
    if db.query(models.User).filter_by(email=body.email).first():
        raise HTTPException(400, "Email already registered")
    u = models.User(name=body.name, email=body.email,
                    password_hash=auth.hash_password(body.password), is_diabetic=body.is_diabetic)
    db.add(u); db.commit(); db.refresh(u)
    return {"access_token": auth.create_token(u.id)}


@app.post("/auth/login", response_model=schemas.TokenOut)
def login(body: schemas.LoginIn, db: Session = Depends(get_db)):
    u = db.query(models.User).filter_by(email=body.email).first()
    if not u or not auth.verify_password(body.password, u.password_hash):
        raise HTTPException(401, "Invalid credentials")
    return {"access_token": auth.create_token(u.id)}


@app.post("/auth/login-form", response_model=schemas.TokenOut, include_in_schema=False)
def login_form(form: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    u = db.query(models.User).filter_by(email=form.username).first()
    if not u or not auth.verify_password(form.password, u.password_hash):
        raise HTTPException(401, "Invalid credentials")
    return {"access_token": auth.create_token(u.id)}


@app.get("/me", response_model=schemas.UserOut)
def me(user: models.User = Depends(auth.current_user)):
    return user


@app.patch("/me", response_model=schemas.UserOut)
def update_me(body: schemas.ProfileUpdate, user: models.User = Depends(auth.current_user),
              db: Session = Depends(get_db)):
    if body.name is not None: user.name = body.name
    if body.is_diabetic is not None: user.is_diabetic = body.is_diabetic
    db.commit(); db.refresh(user)
    return user


# ---------- Products ----------
def _analyze(prod: models.Product, user: models.User):
    nutr = json.loads(prod.nutriments_json or "{}")
    additives = scoring.preservatives_from_tags(json.loads(prod.additives_json or "[]"))
    score, breakdown = scoring.overall_score(nutr, additives, prod.nova_group)
    d_score = scoring.diabetic_score(nutr, prod.ingredients_text, score)
    return nutr, additives, score, breakdown, d_score


@app.get("/products/{barcode}", response_model=schemas.ProductOut)
async def product(barcode: str, user: models.User = Depends(auth.current_user),
                  db: Session = Depends(get_db)):
    prod = await off_client.get_product(db, barcode)
    if not prod:
        raise HTTPException(404, "Product not found")
    nutr, additives, score, breakdown, d_score = _analyze(prod, user)
    g = scoring.grade(d_score if user.is_diabetic else score)
    flags = scoring.flags_for(nutr, additives, prod.nova_group)

    db.add(models.Scan(user_id=user.id, barcode=barcode, product_name=prod.name,
                       score=score, diabetic_score=d_score))
    db.commit()

    premium = auth.is_premium(user)
    out = dict(
        barcode=prod.barcode, name=prod.name, brand=prod.brand, image_url=prod.image_url,
        score=score, grade=g, diabetic_score=d_score, diabetic_friendly=d_score >= 60,
        summary=scoring.summary_text(score, g, flags), locked=not premium,
    )
    if premium:
        out["ingredients"] = [i.strip() for i in (prod.ingredients_text or "").split(",") if i.strip()]
        out["preservatives"] = additives
        out["nutrition_breakdown"] = breakdown
        out["flags"] = flags
        out["alternatives"] = await _alternatives(prod, user)
    return out


async def _alternatives(prod: models.Product, user: models.User, top: int = 5):
    if not prod.category:
        return []
    cands = await off_client.search_category(prod.category)
    ranked = []
    for p in cands:
        if not p.get("code") or p["code"] == prod.barcode or not p.get("product_name"):
            continue
        n = p.get("nutriments") or {}
        add = scoring.preservatives_from_tags(p.get("additives_tags") or [])
        s, _ = scoring.overall_score(n, add, p.get("nova_group"))
        if user.is_diabetic:
            s = scoring.diabetic_score(n, p.get("ingredients_text") or "", s)
        ranked.append(schemas.Alternative(barcode=p["code"], name=p["product_name"],
                                          brand=(p.get("brands") or "").split(",")[0],
                                          image_url=p.get("image_front_url"), score=s))
    ranked.sort(key=lambda a: -a.score)
    return ranked[:top]


# ---------- History & trends ----------
@app.get("/history", response_model=list[schemas.ScanHistoryItem])
def history(limit: int = 50, user: models.User = Depends(auth.current_user), db: Session = Depends(get_db)):
    q = db.query(models.Scan).filter_by(user_id=user.id).order_by(models.Scan.scanned_at.desc())
    return q.limit(limit).all()


@app.get("/trends", response_model=list[schemas.TrendPoint])
def trends(days: int = 30, user: models.User = Depends(auth.current_user), db: Session = Depends(get_db)):
    if not auth.is_premium(user):
        raise HTTPException(402, "Premium required for score trends")
    since = datetime.utcnow() - timedelta(days=days)
    rows = db.query(models.Scan).filter(models.Scan.user_id == user.id, models.Scan.scanned_at >= since).all()
    buckets = defaultdict(list)
    for r in rows:
        buckets[r.scanned_at.strftime("%Y-%m-%d")].append(r.diabetic_score if user.is_diabetic else r.score)
    return [{"date": d, "avg_score": round(sum(v) / len(v), 1), "scans": len(v)} for d, v in sorted(buckets.items())]


# ---------- Subscription / payments (Razorpay-style flow) ----------
@app.post("/subscription/order", response_model=schemas.OrderOut)
def create_order(user: models.User = Depends(auth.current_user), db: Session = Depends(get_db)):
    """TODO: replace the fake order id with a real gateway call, e.g.
    razorpay_client.order.create({'amount': amt, 'currency': 'INR'})"""
    order_id = "order_" + uuid.uuid4().hex[:14]
    db.add(models.Payment(user_id=user.id, gateway_order_id=order_id, amount=config.PREMIUM_PRICE_PAISE))
    db.commit()
    return {"order_id": order_id, "amount": config.PREMIUM_PRICE_PAISE, "currency": "INR",
            "key_id": config.GATEWAY_KEY_ID}


def _activate(user: models.User, db: Session):
    base = user.plan_expires_at if user.plan_expires_at and user.plan_expires_at > datetime.utcnow() else datetime.utcnow()
    user.plan = "premium"
    user.plan_expires_at = base + timedelta(days=config.PREMIUM_DAYS)
    db.commit()


@app.post("/subscription/verify", response_model=schemas.UserOut)
def verify(payload: dict, user: models.User = Depends(auth.current_user), db: Session = Depends(get_db)):
    """Client sends order_id, payment_id, signature. Signature = HMAC_SHA256(order_id|payment_id, secret)."""
    order_id, pay_id, sig = payload.get("order_id"), payload.get("payment_id"), payload.get("signature")
    pay = db.query(models.Payment).filter_by(gateway_order_id=order_id, user_id=user.id).first()
    if not pay:
        raise HTTPException(404, "Order not found")
    expected = hmac.new(config.GATEWAY_KEY_SECRET.encode(), f"{order_id}|{pay_id}".encode(), hashlib.sha256).hexdigest()
    if not hmac.compare_digest(expected, sig or ""):
        pay.status = "failed"; db.commit()
        raise HTTPException(400, "Invalid signature")
    pay.status, pay.gateway_payment_id = "paid", pay_id
    _activate(user, db)
    return user


@app.post("/subscription/dev-activate", response_model=schemas.UserOut)
def dev_activate(user: models.User = Depends(auth.current_user), db: Session = Depends(get_db)):
    """DEV ONLY: unlock premium without payment. Remove before production."""
    _activate(user, db)
    return user


@app.get("/health")
def health():
    return {"ok": True}
