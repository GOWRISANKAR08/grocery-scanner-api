from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, EmailStr


class RegisterIn(BaseModel):
    name: str
    email: EmailStr
    password: str
    is_diabetic: bool = False


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"


class UserOut(BaseModel):
    id: int
    name: str
    email: EmailStr
    is_diabetic: bool
    plan: str
    plan_expires_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class ProfileUpdate(BaseModel):
    name: Optional[str] = None
    is_diabetic: Optional[bool] = None


class Alternative(BaseModel):
    barcode: str
    name: str
    brand: Optional[str] = None
    image_url: Optional[str] = None
    score: float


class ProductOut(BaseModel):
    barcode: str
    name: str
    brand: Optional[str] = None
    image_url: Optional[str] = None
    score: float                    # 0-100 overall
    grade: str                      # A-E
    diabetic_score: float           # 0-100
    diabetic_friendly: bool
    summary: str
    # premium-only fields below are None for free users
    locked: bool
    ingredients: Optional[List[str]] = None
    preservatives: Optional[List[dict]] = None
    nutrition_breakdown: Optional[dict] = None
    alternatives: Optional[List[Alternative]] = None
    flags: Optional[List[str]] = None


class ScanHistoryItem(BaseModel):
    id: int
    barcode: str
    product_name: str
    score: float
    diabetic_score: float
    scanned_at: datetime

    class Config:
        from_attributes = True


class TrendPoint(BaseModel):
    date: str
    avg_score: float
    scans: int


class OrderOut(BaseModel):
    order_id: str
    amount: int
    currency: str
    key_id: str
