from dataclasses import dataclass
import os


@dataclass(frozen=True)
class Settings:
    database_url: str = os.getenv("DATABASE_URL", "sqlite+pysqlite:///:memory:")
    jwt_sub_claim: str = os.getenv("JWT_SUB_CLAIM", "sub")


def get_settings() -> Settings:
    return Settings()
