from dataclasses import dataclass, field
import os


@dataclass(frozen=True)
class Settings:
    database_url: str = field(default_factory=lambda: os.getenv("DATABASE_URL", "sqlite+pysqlite:///:memory:"))
    jwt_sub_claim: str = field(default_factory=lambda: os.getenv("JWT_SUB_CLAIM", "sub"))


def get_settings() -> Settings:
    return Settings()
