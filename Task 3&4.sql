CREATE TABLE IF NOT EXISTS duplicates (
    table_name_source VARCHAR(255),
    count_of_duplicates INT,
    col_1 VARCHAR(255), col_2 VARCHAR(255), col_3 VARCHAR(255), col_4 VARCHAR(255), col_5 VARCHAR(255),
    col_6 VARCHAR(255), col_7 VARCHAR(255), col_8 VARCHAR(255), col_9 VARCHAR(255), col_10 VARCHAR(255),
    col_11 VARCHAR(255), col_12 VARCHAR(255), col_13 VARCHAR(255), col_14 VARCHAR(255), col_15 VARCHAR(255),
    col_16 VARCHAR(255), col_17 VARCHAR(255), col_18 VARCHAR(255), col_19 VARCHAR(255), col_20 VARCHAR(255)
);

TRUNCATE TABLE duplicates;

INSERT INTO duplicates (
    table_name_source, count_of_duplicates,
    col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10
)
SELECT
    'Feed1' AS table_name_source, COUNT(*) AS count_of_duplicates,
    col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10
FROM Feed1
GROUP BY col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10
HAVING COUNT(*) > 1;

INSERT INTO duplicates (
    table_name_source, count_of_duplicates,
    col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10,
    col_11, col_12, col_13, col_14, col_15
)
SELECT
    'Feed2' AS table_name_source, COUNT(*) AS count_of_duplicates,
    col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10,
    col_11, col_12, col_13, col_14, col_15
FROM Feed2
GROUP BY col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10,
    col_11, col_12, col_13, col_14, col_15
HAVING COUNT(*) > 1;

INSERT INTO duplicates (
    table_name_source, count_of_duplicates,
    col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10,
    col_11, col_12, col_13, col_14, col_15, col_16, col_17, col_18, col_19, col_20
)
SELECT
    'Feed3' AS table_name_source, COUNT(*) AS count_of_duplicates,
    col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10,
    col_11, col_12, col_13, col_14, col_15, col_16, col_17, col_18, col_19, col_20
FROM Feed3
GROUP BY col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10,
    col_11, col_12, col_13, col_14, col_15, col_16, col_17, col_18, col_19, col_20
HAVING COUNT(*) > 1;