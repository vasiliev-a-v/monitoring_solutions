--~ Установка индексов

CREATE INDEX CONCURRENTLY temp_changes_idx ON temp_changes(time);
CREATE INDEX CONCURRENTLY temp_changes_location_idx ON temp_changes(location);

CREATE INDEX CONCURRENTLY temp_static_location_idx ON temp_static(location);
CREATE INDEX CONCURRENTLY temp_static_idx ON temp_static(time);
VACUUM ANALYZE temp_changes;
VACUUM ANALYZE temp_static;