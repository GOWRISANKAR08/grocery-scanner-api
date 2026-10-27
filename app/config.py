import os

SECRET_KEY = os.getenv("SECRET_KEY", "change-me-in-production")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60 * 24 * 30
PREMIUM_PRICE_PAISE = int(os.getenv("PREMIUM_PRICE_PAISE", "9900"))  # Rs 99
PREMIUM_DAYS = 30
GATEWAY_KEY_ID = os.getenv("GATEWAY_KEY_ID", "rzp_test_xxx")
GATEWAY_KEY_SECRET = os.getenv("GATEWAY_KEY_SECRET", "secret")
OFF_BASE = "https://world.openfoodfacts.org"
