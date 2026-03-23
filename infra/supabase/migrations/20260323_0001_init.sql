create extension if not exists pgcrypto;

create table if not exists users (
    id uuid primary key default gen_random_uuid(),
    timezone text,
    unit_preference text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists goal_profile_current (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null unique references users(id) on delete cascade,
    primary_goal_type text not null,
    secondary_goal_types jsonb,
    target_time_sec integer,
    target_date date,
    weekly_run_days integer,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists goal_profile_history (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    primary_goal_type text not null,
    secondary_goal_types jsonb,
    target_time_sec integer,
    target_date date,
    weekly_run_days integer,
    changed_at timestamptz not null default now()
);

create table if not exists training_blocks (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    primary_goal_type text not null,
    target_time_sec integer,
    start_date date,
    end_date date,
    weekly_run_days integer,
    status text not null default 'active',
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists source_connections (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    source text not null,
    status text not null default 'connected',
    details_json jsonb,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists workout_raw (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    source text not null,
    source_workout_id text not null,
    raw_payload jsonb,
    raw_payload_url text,
    imported_at timestamptz not null default now(),
    constraint uq_workout_raw_source_key unique (user_id, source, source_workout_id)
);

create table if not exists workout_sessions (
    id uuid primary key,
    user_id uuid not null references users(id) on delete cascade,
    source text not null,
    source_workout_id text not null,
    started_at timestamptz not null,
    ended_at timestamptz not null,
    duration_sec integer not null,
    distance_m double precision not null,
    avg_pace_sec_per_km double precision,
    avg_heart_rate double precision,
    max_heart_rate double precision,
    calories_active double precision,
    calories_total double precision,
    avg_power double precision,
    avg_cadence double precision,
    avg_stride_length double precision,
    avg_ground_contact_time double precision,
    avg_vertical_oscillation double precision,
    total_ascent_m double precision,
    total_descent_m double precision,
    is_outdoor boolean not null default true,
    has_route boolean not null default false,
    data_completeness text,
    confidence_score double precision,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint uq_workout_session_source_key unique (user_id, source, source_workout_id)
);

create table if not exists workout_laps (
    id uuid primary key default gen_random_uuid(),
    workout_session_id uuid not null references workout_sessions(id) on delete cascade,
    lap_index integer not null,
    distance_m double precision not null,
    duration_sec integer not null,
    avg_pace_sec_per_km double precision,
    avg_heart_rate double precision,
    avg_power double precision,
    avg_stride_length double precision,
    avg_cadence double precision,
    avg_ground_contact_time double precision,
    avg_vertical_oscillation double precision,
    ascent_m double precision,
    descent_m double precision
);

create table if not exists workout_streams (
    id uuid primary key default gen_random_uuid(),
    workout_session_id uuid not null references workout_sessions(id) on delete cascade,
    metric_type text not null,
    offset_sec integer not null,
    value double precision not null,
    unit text,
    source_type text,
    availability_status text,
    confidence_score double precision
);

create table if not exists workout_distributions (
    id uuid primary key default gen_random_uuid(),
    workout_session_id uuid not null references workout_sessions(id) on delete cascade,
    distribution_type text not null,
    bucket_key text not null,
    duration_sec integer,
    distance_m double precision,
    percentage double precision
);

create table if not exists workout_routes (
    id uuid primary key default gen_random_uuid(),
    workout_session_id uuid not null unique references workout_sessions(id) on delete cascade,
    route_storage_key text,
    summary_json jsonb
);

create table if not exists feedback_tags (
    id uuid primary key default gen_random_uuid(),
    tag_key text not null unique,
    display_name text not null unique,
    category text not null,
    sort_order integer not null default 0,
    is_active boolean not null default true
);

create table if not exists post_workout_feedback (
    id uuid primary key default gen_random_uuid(),
    workout_session_id uuid not null unique references workout_sessions(id) on delete cascade,
    user_id uuid not null references users(id) on delete cascade,
    rpe integer,
    fatigue integer,
    soreness integer,
    breathing_load integer,
    confidence integer,
    free_text text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table if not exists post_workout_feedback_tag_links (
    id uuid primary key default gen_random_uuid(),
    feedback_id uuid not null references post_workout_feedback(id) on delete cascade,
    tag_id uuid not null references feedback_tags(id) on delete cascade,
    constraint uq_feedback_tag_link unique (feedback_id, tag_id)
);

create table if not exists analysis_jobs (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    workout_session_id uuid references workout_sessions(id) on delete cascade,
    trigger text not null,
    status text not null default 'queued',
    dedupe_key text unique,
    error_message text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    constraint ck_analysis_jobs_status check (status in ('queued', 'running', 'succeeded', 'failed', 'partial', 'needs_retry'))
);

create table if not exists analysis_snapshots (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    workout_session_id uuid not null references workout_sessions(id) on delete cascade,
    analysis_job_id uuid references analysis_jobs(id) on delete set null,
    version integer not null,
    mode text not null,
    decision_confidence text,
    input_summary jsonb,
    decision_json jsonb,
    narrative_json jsonb,
    created_at timestamptz not null default now(),
    constraint uq_analysis_snapshot_version unique (workout_session_id, version)
);

create table if not exists training_plans (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    training_block_id uuid references training_blocks(id) on delete set null,
    source_analysis_snapshot_id uuid references analysis_snapshots(id) on delete set null,
    window_start date not null,
    window_days integer not null default 7,
    version integer not null default 1,
    is_current boolean not null default true,
    created_at timestamptz not null default now()
);

create table if not exists training_plan_items (
    id uuid primary key default gen_random_uuid(),
    training_plan_id uuid not null references training_plans(id) on delete cascade,
    day_index integer not null,
    scheduled_date date not null,
    workout_type text not null,
    duration_min integer,
    distance_m double precision,
    intensity text,
    changed boolean not null default false,
    change_reason text
);

create table if not exists workout_derived_features (
    id uuid primary key default gen_random_uuid(),
    workout_session_id uuid not null references workout_sessions(id) on delete cascade,
    feature_key text not null,
    value_float double precision,
    value_text text,
    value_json jsonb,
    value_source text not null default 'derived',
    availability_status text not null default 'available',
    confidence_score double precision,
    constraint uq_workout_feature_key unique (workout_session_id, feature_key)
);

create table if not exists training_load_summary_daily (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    summary_date date not null,
    run_count integer not null default 0,
    total_distance_m double precision not null default 0,
    total_duration_sec integer not null default 0,
    high_intensity_count integer not null default 0,
    load_score double precision not null default 0,
    fatigue_avg double precision,
    constraint uq_training_load_daily_date unique (user_id, summary_date)
);

create table if not exists training_load_summary_rolling (
    id uuid primary key default gen_random_uuid(),
    user_id uuid not null references users(id) on delete cascade,
    reference_date date not null,
    window_days integer not null,
    total_distance_m double precision not null default 0,
    total_duration_sec integer not null default 0,
    high_intensity_count integer not null default 0,
    load_score double precision not null default 0,
    fatigue_avg double precision,
    constraint uq_training_load_rolling_window unique (user_id, reference_date, window_days)
);
