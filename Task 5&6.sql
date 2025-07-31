DROP TABLE IF EXISTS temp_feed_with_pk;
CREATE TEMPORARY TABLE temp_feed_with_pk (
    pk INT AUTO_INCREMENT PRIMARY KEY,
    col_1 INT, col_2 VARCHAR(255), col_3 VARCHAR(255), col_4 VARCHAR(255), col_5 VARCHAR(255),
    col_6 VARCHAR(255), col_7 VARCHAR(255), col_8 VARCHAR(255), col_9 VARCHAR(255), col_10 VARCHAR(255)
);
INSERT INTO temp_feed_with_pk (col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10)
SELECT * FROM Feed1;

DROP TABLE IF EXISTS temp_pks_to_update;
CREATE TEMPORARY TABLE temp_pks_to_update AS
SELECT pk
FROM (
    SELECT pk,
           ROW_NUMBER() OVER(PARTITION BY col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10 ORDER BY pk) as rn
    FROM temp_feed_with_pk
) AS numbered_rows
WHERE rn > 1;

UPDATE temp_feed_with_pk
SET
    col_1 = pk, col_2 = SUBSTRING(MD5(RAND()), 1, 8), col_3 = SUBSTRING(MD5(RAND()), 1, 8),
    col_4 = SUBSTRING(MD5(RAND()), 1, 8), col_5 = SUBSTRING(MD5(RAND()), 1, 8), col_6 = SUBSTRING(MD5(RAND()), 1, 8),
    col_7 = SUBSTRING(MD5(RAND()), 1, 8), col_8 = SUBSTRING(MD5(RAND()), 1, 8), col_9 = SUBSTRING(MD5(RAND()), 1, 8),
    col_10 = SUBSTRING(MD5(RAND()), 1, 8)
WHERE pk IN (SELECT pk FROM temp_pks_to_update);

TRUNCATE TABLE Feed1;
INSERT INTO Feed1 (col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10)
SELECT col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10 FROM temp_feed_with_pk;

SELECT
    COUNT(*) AS number_of_duplicate_groups
FROM (
    SELECT COUNT(*)
    FROM Feed1
    GROUP BY
        col_1, col_2, col_3, col_4, col_5, col_6, col_7, col_8, col_9, col_10
    HAVING COUNT(*) > 1
) AS duplicate_counts;
