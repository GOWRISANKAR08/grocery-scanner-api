import datetime as dt
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey, Text
from sqlalchemy.orm import relationship
from .database import Base


class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True)
    name = Column(String(100), nullable=False)
    email = Column(String(150), unique=True, index=True, nullable=False)
    password_hash = Column(String(200), nullable=False)
    is_diabetic = Column(Boolean, default=False)
    plan = Column(String(20), default="free")  # free | premium
    plan_expires_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=dt.datetime.utcnow)
    scans = relationship("Scan", back_populates="user")


class Product(Base):
    __tablename__ = "products"
    barcode = Column(String(32), primary_key=True)
    name = Column(String(200))
    brand = Column(String(150))
    image_url = Column(String(300))
    category = Column(String(100))
    ingredients_text = Column(Text)
    nutriments_json = Column(Text)  # raw per-100g nutrients as JSON
    nova_group = Column(Integer, nullable=True)
    additives_json = Column(Text)   # JSON list of additive tags


class Scan(Base):
    __tablename__ = "scans"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    barcode = Column(String(32), index=True)
    product_name = Column(String(200))
    score = Column(Float)
    diabetic_score = Column(Float)
    scanned_at = Column(DateTime, default=dt.datetime.utcnow)
    user = relationship("User", back_populates="scans")


class Payment(Base):
    __tablename__ = "payments"
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    gateway_order_id = Column(String(100), index=True)
    gateway_payment_id = Column(String(100), nullable=True)
    amount = Column(Integer)  # in paise/cents
    status = Column(String(20), default="created")  # created | paid | failed
    created_at = Column(DateTime, default=dt.datetime.utcnow)
