from __future__ import annotations

from datetime import UTC, date, datetime
from uuid import UUID, uuid4

from sqlalchemy import JSON, Boolean, Date, DateTime, Float, ForeignKey, Integer, String, Text, UniqueConstraint, Uuid
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class TimestampMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        onupdate=lambda: datetime.now(UTC),
        nullable=False,
    )


class UserModel(TimestampMixin, Base):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    timezone: Mapped[str | None] = mapped_column(String(64))
    unit_preference: Mapped[str | None] = mapped_column(String(16))


class GoalProfileCurrentModel(TimestampMixin, Base):
    __tablename__ = "goal_profile_current"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), unique=True, nullable=False)
    primary_goal_type: Mapped[str] = mapped_column(String(64), nullable=False)
    secondary_goal_types: Mapped[list[str] | None] = mapped_column(JSON)
    target_time_sec: Mapped[int | None] = mapped_column(Integer)
    target_date: Mapped[date | None] = mapped_column(Date)
    weekly_run_days: Mapped[int | None] = mapped_column(Integer)


class GoalProfileHistoryModel(Base):
    __tablename__ = "goal_profile_history"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    primary_goal_type: Mapped[str] = mapped_column(String(64), nullable=False)
    secondary_goal_types: Mapped[list[str] | None] = mapped_column(JSON)
    target_time_sec: Mapped[int | None] = mapped_column(Integer)
    target_date: Mapped[date | None] = mapped_column(Date)
    weekly_run_days: Mapped[int | None] = mapped_column(Integer)
    changed_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )


class TrainingBlockModel(TimestampMixin, Base):
    __tablename__ = "training_blocks"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    primary_goal_type: Mapped[str] = mapped_column(String(64), nullable=False)
    target_time_sec: Mapped[int | None] = mapped_column(Integer)
    start_date: Mapped[date | None] = mapped_column(Date)
    end_date: Mapped[date | None] = mapped_column(Date)
    weekly_run_days: Mapped[int | None] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(32), default="active", nullable=False)


class SourceConnectionModel(TimestampMixin, Base):
    __tablename__ = "source_connections"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    source: Mapped[str] = mapped_column(String(32), nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="connected", nullable=False)
    details_json: Mapped[dict | None] = mapped_column(JSON)


class WorkoutRawModel(Base):
    __tablename__ = "workout_raw"
    __table_args__ = (
        UniqueConstraint("user_id", "source", "source_workout_id", name="uq_workout_raw_source_key"),
    )

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    source: Mapped[str] = mapped_column(String(32), nullable=False)
    source_workout_id: Mapped[str] = mapped_column(String(128), nullable=False)
    raw_payload: Mapped[dict | None] = mapped_column(JSON)
    raw_payload_url: Mapped[str | None] = mapped_column(String(255))
    imported_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )


class WorkoutSessionModel(TimestampMixin, Base):
    __tablename__ = "workout_sessions"
    __table_args__ = (
        UniqueConstraint("user_id", "source", "source_workout_id", name="uq_workout_session_source_key"),
    )

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    source: Mapped[str] = mapped_column(String(32), nullable=False)
    source_workout_id: Mapped[str] = mapped_column(String(128), nullable=False)
    started_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    ended_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    duration_sec: Mapped[int] = mapped_column(Integer, nullable=False)
    distance_m: Mapped[float] = mapped_column(Float, nullable=False)
    avg_pace_sec_per_km: Mapped[float | None] = mapped_column(Float)
    avg_heart_rate: Mapped[float | None] = mapped_column(Float)
    max_heart_rate: Mapped[float | None] = mapped_column(Float)
    calories_active: Mapped[float | None] = mapped_column(Float)
    calories_total: Mapped[float | None] = mapped_column(Float)
    avg_power: Mapped[float | None] = mapped_column(Float)
    avg_cadence: Mapped[float | None] = mapped_column(Float)
    avg_stride_length: Mapped[float | None] = mapped_column(Float)
    avg_ground_contact_time: Mapped[float | None] = mapped_column(Float)
    avg_vertical_oscillation: Mapped[float | None] = mapped_column(Float)
    total_ascent_m: Mapped[float | None] = mapped_column(Float)
    total_descent_m: Mapped[float | None] = mapped_column(Float)
    is_outdoor: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    has_route: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    data_completeness: Mapped[str | None] = mapped_column(String(32))
    confidence_score: Mapped[float | None] = mapped_column(Float)

    laps: Mapped[list["WorkoutLapModel"]] = relationship(back_populates="workout_session")
    streams: Mapped[list["WorkoutStreamModel"]] = relationship(back_populates="workout_session")
    distributions: Mapped[list["WorkoutDistributionModel"]] = relationship(back_populates="workout_session")


class WorkoutLapModel(Base):
    __tablename__ = "workout_laps"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    workout_session_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("workout_sessions.id"), nullable=False)
    lap_index: Mapped[int] = mapped_column(Integer, nullable=False)
    distance_m: Mapped[float] = mapped_column(Float, nullable=False)
    duration_sec: Mapped[int] = mapped_column(Integer, nullable=False)
    avg_pace_sec_per_km: Mapped[float | None] = mapped_column(Float)
    avg_heart_rate: Mapped[float | None] = mapped_column(Float)
    avg_power: Mapped[float | None] = mapped_column(Float)
    avg_stride_length: Mapped[float | None] = mapped_column(Float)
    avg_cadence: Mapped[float | None] = mapped_column(Float)
    avg_ground_contact_time: Mapped[float | None] = mapped_column(Float)
    avg_vertical_oscillation: Mapped[float | None] = mapped_column(Float)
    ascent_m: Mapped[float | None] = mapped_column(Float)
    descent_m: Mapped[float | None] = mapped_column(Float)

    workout_session: Mapped[WorkoutSessionModel] = relationship(back_populates="laps")


class WorkoutStreamModel(Base):
    __tablename__ = "workout_streams"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    workout_session_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("workout_sessions.id"), nullable=False)
    metric_type: Mapped[str] = mapped_column(String(64), nullable=False)
    offset_sec: Mapped[int] = mapped_column(Integer, nullable=False)
    value: Mapped[float] = mapped_column(Float, nullable=False)
    unit: Mapped[str | None] = mapped_column(String(32))
    source_type: Mapped[str | None] = mapped_column(String(32))
    availability_status: Mapped[str | None] = mapped_column(String(32))
    confidence_score: Mapped[float | None] = mapped_column(Float)

    workout_session: Mapped[WorkoutSessionModel] = relationship(back_populates="streams")


class WorkoutDistributionModel(Base):
    __tablename__ = "workout_distributions"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    workout_session_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("workout_sessions.id"), nullable=False)
    distribution_type: Mapped[str] = mapped_column(String(64), nullable=False)
    bucket_key: Mapped[str] = mapped_column(String(64), nullable=False)
    duration_sec: Mapped[int | None] = mapped_column(Integer)
    distance_m: Mapped[float | None] = mapped_column(Float)
    percentage: Mapped[float | None] = mapped_column(Float)

    workout_session: Mapped[WorkoutSessionModel] = relationship(back_populates="distributions")


class WorkoutRouteModel(Base):
    __tablename__ = "workout_routes"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    workout_session_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("workout_sessions.id"), nullable=False, unique=True)
    route_storage_key: Mapped[str | None] = mapped_column(String(255))
    summary_json: Mapped[dict | None] = mapped_column(JSON)


class FeedbackTagModel(Base):
    __tablename__ = "feedback_tags"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    tag_key: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)
    display_name: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)
    category: Mapped[str] = mapped_column(String(32), nullable=False)
    sort_order: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)


class PostWorkoutFeedbackModel(TimestampMixin, Base):
    __tablename__ = "post_workout_feedback"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    workout_session_id: Mapped[UUID] = mapped_column(
        Uuid,
        ForeignKey("workout_sessions.id"),
        nullable=False,
        unique=True,
    )
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    rpe: Mapped[int | None] = mapped_column(Integer)
    fatigue: Mapped[int | None] = mapped_column(Integer)
    soreness: Mapped[int | None] = mapped_column(Integer)
    breathing_load: Mapped[int | None] = mapped_column(Integer)
    confidence: Mapped[int | None] = mapped_column(Integer)
    free_text: Mapped[str | None] = mapped_column(Text)


class PostWorkoutFeedbackTagLinkModel(Base):
    __tablename__ = "post_workout_feedback_tag_links"
    __table_args__ = (
        UniqueConstraint("feedback_id", "tag_id", name="uq_feedback_tag_link"),
    )

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    feedback_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("post_workout_feedback.id"), nullable=False)
    tag_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("feedback_tags.id"), nullable=False)


class TrainingPlanModel(Base):
    __tablename__ = "training_plans"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    training_block_id: Mapped[UUID | None] = mapped_column(Uuid, ForeignKey("training_blocks.id"))
    source_analysis_snapshot_id: Mapped[UUID | None] = mapped_column(Uuid, ForeignKey("analysis_snapshots.id"))
    window_start: Mapped[date] = mapped_column(Date, nullable=False)
    window_days: Mapped[int] = mapped_column(Integer, default=7, nullable=False)
    version: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    is_current: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )


class TrainingPlanItemModel(Base):
    __tablename__ = "training_plan_items"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    training_plan_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("training_plans.id"), nullable=False)
    day_index: Mapped[int] = mapped_column(Integer, nullable=False)
    scheduled_date: Mapped[date] = mapped_column(Date, nullable=False)
    workout_type: Mapped[str] = mapped_column(String(64), nullable=False)
    duration_min: Mapped[int | None] = mapped_column(Integer)
    distance_m: Mapped[float | None] = mapped_column(Float)
    intensity: Mapped[str | None] = mapped_column(String(32))
    changed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    change_reason: Mapped[str | None] = mapped_column(Text)


class AnalysisJobModel(TimestampMixin, Base):
    __tablename__ = "analysis_jobs"

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    workout_session_id: Mapped[UUID | None] = mapped_column(Uuid, ForeignKey("workout_sessions.id"))
    trigger: Mapped[str] = mapped_column(String(32), nullable=False)
    status: Mapped[str] = mapped_column(String(32), default="queued", nullable=False)
    dedupe_key: Mapped[str | None] = mapped_column(String(128), unique=True)
    error_message: Mapped[str | None] = mapped_column(Text)


class AnalysisSnapshotModel(Base):
    __tablename__ = "analysis_snapshots"
    __table_args__ = (
        UniqueConstraint("workout_session_id", "version", name="uq_analysis_snapshot_version"),
    )

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    workout_session_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("workout_sessions.id"), nullable=False)
    analysis_job_id: Mapped[UUID | None] = mapped_column(Uuid, ForeignKey("analysis_jobs.id"))
    version: Mapped[int] = mapped_column(Integer, nullable=False)
    mode: Mapped[str] = mapped_column(String(32), nullable=False)
    decision_confidence: Mapped[str | None] = mapped_column(String(16))
    input_summary: Mapped[dict | None] = mapped_column(JSON)
    decision_json: Mapped[dict | None] = mapped_column(JSON)
    narrative_json: Mapped[dict | None] = mapped_column(JSON)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(UTC),
        nullable=False,
    )


class WorkoutDerivedFeatureModel(Base):
    __tablename__ = "workout_derived_features"
    __table_args__ = (
        UniqueConstraint("workout_session_id", "feature_key", name="uq_workout_feature_key"),
    )

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    workout_session_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("workout_sessions.id"), nullable=False)
    feature_key: Mapped[str] = mapped_column(String(64), nullable=False)
    value_float: Mapped[float | None] = mapped_column(Float)
    value_text: Mapped[str | None] = mapped_column(String(255))
    value_json: Mapped[dict | None] = mapped_column(JSON)
    value_source: Mapped[str] = mapped_column(String(16), default="derived", nullable=False)
    availability_status: Mapped[str] = mapped_column(String(16), default="available", nullable=False)
    confidence_score: Mapped[float | None] = mapped_column(Float)


class TrainingLoadSummaryDailyModel(Base):
    __tablename__ = "training_load_summary_daily"
    __table_args__ = (
        UniqueConstraint("user_id", "summary_date", name="uq_training_load_daily_date"),
    )

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    summary_date: Mapped[date] = mapped_column(Date, nullable=False)
    run_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    total_distance_m: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    total_duration_sec: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    high_intensity_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    load_score: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    fatigue_avg: Mapped[float | None] = mapped_column(Float)


class TrainingLoadSummaryRollingModel(Base):
    __tablename__ = "training_load_summary_rolling"
    __table_args__ = (
        UniqueConstraint("user_id", "reference_date", "window_days", name="uq_training_load_rolling_window"),
    )

    id: Mapped[UUID] = mapped_column(Uuid, primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(Uuid, ForeignKey("users.id"), nullable=False)
    reference_date: Mapped[date] = mapped_column(Date, nullable=False)
    window_days: Mapped[int] = mapped_column(Integer, nullable=False)
    total_distance_m: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    total_duration_sec: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    high_intensity_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)
    load_score: Mapped[float] = mapped_column(Float, default=0, nullable=False)
    fatigue_avg: Mapped[float | None] = mapped_column(Float)
