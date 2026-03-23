from dataclasses import dataclass


@dataclass(frozen=True)
class WorkerSettings:
    database_url: str = "sqlite+pysqlite:///:memory:"
