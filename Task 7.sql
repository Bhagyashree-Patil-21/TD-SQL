-- Create the table to store comparison results
CREATE TABLE IF NOT EXISTS comparison_results (
    source_feed VARCHAR(255),
    target_feed VARCHAR(255),
    record_data_col1 VARCHAR(255),
    comparison_status VARCHAR(255)
);

-- Clear old results
TRUNCATE TABLE comparison_results;

-- Compare Feed2 to Feed1
INSERT INTO comparison_results (source_feed, target_feed, record_data_col1, comparison_status)
SELECT 'Feed2', 'Feed1', s.col_1, 'In source only'
FROM Feed2 s LEFT JOIN Feed1 t ON s.col_1 = t.col_1
WHERE t.col_1 IS NULL;

INSERT INTO comparison_results (source_feed, target_feed, record_data_col1, comparison_status)
SELECT 'Feed2', 'Feed1', t.col_1, 'In target only'
FROM Feed1 t LEFT JOIN Feed2 s ON t.col_1 = s.col_1
WHERE s.col_1 IS NULL;

-- Compare Feed3 to Feed1
INSERT INTO comparison_results (source_feed, target_feed, record_data_col1, comparison_status)
SELECT 'Feed3', 'Feed1', s.col_1, 'In source only'
FROM Feed3 s LEFT JOIN Feed1 t ON s.col_1 = t.col_1
WHERE t.col_1 IS NULL;

INSERT INTO comparison_results (source_feed, target_feed, record_data_col1, comparison_status)
SELECT 'Feed3', 'Feed1', t.col_1, 'In target only'
FROM Feed1 t LEFT JOIN Feed3 s ON t.col_1 = s.col_1
WHERE s.col_1 IS NULL;