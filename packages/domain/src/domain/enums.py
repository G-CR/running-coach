from enum import StrEnum


class SourceType(StrEnum):
    HEALTHKIT = "healthkit"


class AnalysisMode(StrEnum):
    STANDARD = "standard"
    DEGRADED = "degraded"
    CONSERVATIVE = "conservative"
    PROTECTIVE = "protective"


class AnalysisJobStatus(StrEnum):
    QUEUED = "queued"
    RUNNING = "running"
    SUCCEEDED = "succeeded"
    FAILED = "failed"
    PARTIAL = "partial"
    NEEDS_RETRY = "needs_retry"
