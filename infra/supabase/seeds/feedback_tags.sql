insert into feedback_tags (tag_key, display_name, category, sort_order)
values
    ('easy_feel', '偏轻松', 'intensity', 10),
    ('just_right', '合适', 'intensity', 20),
    ('hard_feel', '偏吃力', 'intensity', 30),
    ('very_hard', '非常吃力', 'intensity', 40),
    ('heavy_legs', '腿沉', 'body', 50),
    ('cardio_stress', '心肺压力大', 'body', 60),
    ('cadence_off', '步频不顺', 'body', 70),
    ('good_shape', '状态不错', 'body', 80),
    ('pace_on_target', '节奏完成好', 'execution', 90),
    ('fade_late', '后程掉速', 'execution', 100),
    ('pace_uncontrolled', '配速没控住', 'execution', 110),
    ('could_not_open', '没跑开', 'execution', 120)
on conflict (tag_key) do nothing;
