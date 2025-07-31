

DELIMITER $$

CREATE PROCEDURE generate_feed(
    IN table_name VARCHAR(255),
    IN num_cols INT,
    IN num_rows INT
)
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE j INT DEFAULT 1;
    DECLARE create_table_sql TEXT;
    DECLARE insert_sql TEXT;
    DECLARE col_list TEXT;
    DECLARE val_list TEXT;

    SET @drop_sql = CONCAT('DROP TABLE IF EXISTS ', table_name);
    PREPARE stmt FROM @drop_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET create_table_sql = CONCAT('CREATE TABLE ', table_name, ' (');
    WHILE i <= num_cols DO
        SET create_table_sql = CONCAT(create_table_sql, 'col_', i, ' VARCHAR(255)');
        IF i < num_cols THEN
            SET create_table_sql = CONCAT(create_table_sql, ', ');
        END IF;
        SET i = i + 1;
    END WHILE;
    SET create_table_sql = CONCAT(create_table_sql, ')');

    SET @create_sql = create_table_sql;
    PREPARE stmt FROM @create_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET i = 1;
    SET col_list = '';
    WHILE i <= num_cols DO
        SET col_list = CONCAT(col_list, 'col_', i);
        IF i < num_cols THEN
            SET col_list = CONCAT(col_list, ', ');
        END IF;
        SET i = i + 1;
    END WHILE;


    SET j = 1;
    WHILE j <= num_rows DO
        SET i = 1;
        SET val_list = '';
        WHILE i <= num_cols DO
            SET val_list = CONCAT(val_list, '''', SUBSTRING(MD5(RAND()), 1, 8), '''');
            IF i < num_cols THEN
                SET val_list = CONCAT(val_list, ', ');
            END IF;
            SET i = i + 1;
        END WHILE;

        SET @insert_sql = CONCAT('INSERT INTO ', table_name, ' (', col_list, ') VALUES (', val_list, ')');
        PREPARE stmt FROM @insert_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET j = j + 1;
    END WHILE;

    IF num_rows > 0 THEN
        SET @insert_sql = CONCAT('INSERT INTO ', table_name, ' (', col_list, ') SELECT ', col_list, ' FROM ', table_name, ' LIMIT 1');
        PREPARE stmt FROM @insert_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;


    SELECT CONCAT('Table ', table_name, ' created and populated with ', num_rows, ' rows and ', num_cols, ' columns.') AS Status;

END$$

DELIMITER ;

CREATE TABLE IF NOT EXISTS duplicates (
    table_name_source VARCHAR(255),
    duplicate_data JSON,
    count_of_duplicates INT
);


DELIMITER $$

CREATE PROCEDURE find_and_store_duplicates(IN source_table_name VARCHAR(255))
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE cols TEXT;
    DECLARE cur CURSOR FOR
        SELECT GROUP_CONCAT(COLUMN_NAME)
        FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_NAME = source_table_name AND TABLE_SCHEMA = DATABASE();
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;
    FETCH cur INTO cols;
    CLOSE cur;

    SET @sql = CONCAT(
        'INSERT INTO duplicates (table_name_source, duplicate_data, count_of_duplicates) ',
        'SELECT ''', source_table_name, ''', ',
        'JSON_OBJECT(',
        (SELECT GROUP_CONCAT(CONCAT('''', COLUMN_NAME, ''', ', COLUMN_NAME)) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = source_table_name AND TABLE_SCHEMA = DATABASE()),
        '), COUNT(*) ',
        'FROM ', source_table_name, ' ',
        'GROUP BY ', cols, ' ',
        'HAVING COUNT(*) > 1'
    );

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT CONCAT('Duplicate check for table ', source_table_name, ' is complete.') AS Status;

END$$


CREATE PROCEDURE replace_duplicates_with_unique(IN target_table_name VARCHAR(255))
BEGIN
    DECLARE cols TEXT;

    SELECT GROUP_CONCAT(COLUMN_NAME)
    INTO cols
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = target_table_name AND TABLE_SCHEMA = DATABASE();

    SET @temp_table_sql = CONCAT('CREATE TEMPORARY TABLE temp_distinct AS SELECT DISTINCT * FROM ', target_table_name);
    PREPARE stmt FROM @temp_table_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @truncate_sql = CONCAT('TRUNCATE TABLE ', target_table_name);
    PREPARE stmt FROM @truncate_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @insert_sql = CONCAT('INSERT INTO ', target_table_name, ' SELECT * FROM temp_distinct');
    PREPARE stmt FROM @insert_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    DROP TEMPORARY TABLE temp_distinct;

    SELECT CONCAT('Duplicates removed from ', target_table_name, '. The table now contains only unique rows.') AS Status;

END$$


CREATE PROCEDURE verify_no_duplicates(IN table_to_check VARCHAR(255))
BEGIN
    DECLARE duplicate_count INT;
    DECLARE cols TEXT;

    SELECT GROUP_CONCAT(COLUMN_NAME)
    INTO cols
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = table_to_check AND TABLE_SCHEMA = DATABASE();

    SET @sql = CONCAT(
        'SELECT COUNT(*) INTO @d_count FROM (',
        'SELECT ', cols, ', COUNT(*) as cnt ',
        'FROM ', table_to_check, ' ',
        'GROUP BY ', cols, ' ',
        'HAVING COUNT(*) > 1) AS duplicates'
    );

    PREPARE stmt FROM @sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET duplicate_count = @d_count;

    IF duplicate_count = 0 THEN
        SELECT CONCAT('Verification successful for ', table_to_check, ': No duplicate rows found.') AS Result;
    ELSE
        SELECT CONCAT('Verification failed for ', table_to_check, ': ', duplicate_count, ' duplicate sets found.') AS Result;
    END IF;

END$$


CREATE TABLE IF NOT EXISTS comparison_results (
    source_feed VARCHAR(255),
    target_feed VARCHAR(255),
    record_data JSON,
    comparison_status VARCHAR(255) -- e.g., 'In source only', 'In target only', 'Mismatch'
);



CREATE PROCEDURE compare_feeds(
    IN source_feed_name VARCHAR(255),
    IN target_feed_name VARCHAR(255)
)
BEGIN
    DECLARE source_cols TEXT;
    DECLARE target_cols TEXT;

    SET @source_col1 = 's.col_1';
    SET @target_col1 = 't.col_1';

    DELETE FROM comparison_results WHERE source_feed = source_feed_name AND target_feed = target_feed_name;

    SET @source_only_sql = CONCAT(
        'INSERT INTO comparison_results (source_feed, target_feed, record_data, comparison_status) ',
        'SELECT ''', source_feed_name, ''', ''', target_feed_name, ''', ',
        'JSON_OBJECT(',
            (SELECT GROUP_CONCAT(CONCAT('''', COLUMN_NAME, ''', ', COLUMN_NAME)) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = source_feed_name AND TABLE_SCHEMA = DATABASE()),
        '), ''In source only'' ',
        'FROM ', source_feed_name, ' s ',
        'LEFT JOIN ', target_feed_name, ' t ON ', @source_col1, ' = ', @target_col1, ' ',
        'WHERE t.col_1 IS NULL'
    );
    PREPARE stmt FROM @source_only_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SET @target_only_sql = CONCAT(
        'INSERT INTO comparison_results (source_feed, target_feed, record_data, comparison_status) ',
        'SELECT ''', source_feed_name, ''', ''', target_feed_name, ''', ',
        'JSON_OBJECT(',
            (SELECT GROUP_CONCAT(CONCAT('''', COLUMN_NAME, ''', ', COLUMN_NAME)) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = target_feed_name AND TABLE_SCHEMA = DATABASE()),
        '), ''In target only'' ',
        'FROM ', target_feed_name, ' t ',
        'LEFT JOIN ', source_feed_name, ' s ON ', @target_col1, ' = ', @source_col1, ' ',
        'WHERE s.col_1 IS NULL'
    );

    PREPARE stmt FROM @target_only_sql;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;

    SELECT CONCAT('Comparison between ', source_feed_name, ' and ', target_feed_name, ' is complete.') AS Status;

END$$


CREATE PROCEDURE run_automated_tests()
BEGIN
    DECLARE test_result VARCHAR(255);
    DECLARE row_count INT;

    CALL generate_feed('Feed1', 10, 10);
    SELECT COUNT(*) INTO row_count FROM Feed1;
    IF row_count = 11 THEN
        SELECT 'TC-01: Generate Feed-1 - PASSED' AS Test_Result;
    ELSE
        SELECT 'TC-01: Generate Feed-1 - FAILED' AS Test_Result;
    END IF;

    TRUNCATE TABLE duplicates;
    CALL find_and_store_duplicates('Feed1');
    SELECT COUNT(*) INTO row_count FROM duplicates WHERE table_name_source = 'Feed1';
    IF row_count = 1 THEN
        SELECT 'TC-04: Identify Duplicates in Feed-1 - PASSED' AS Test_Result;
    ELSE
        SELECT 'TC-04: Identify Duplicates in Feed-1 - FAILED' AS Test_Result;
    END IF;

    CALL replace_duplicates_with_unique('Feed1');
    SELECT COUNT(*) INTO row_count FROM Feed1;
    IF row_count = 10 THEN
        SELECT 'TC-05: Replace Duplicates in Feed-1 - PASSED' AS Test_Result;
    ELSE
        SELECT 'TC-05: Replace Duplicates in Feed-1 - FAILED' AS Test_Result;
    END IF;


    CALL verify_no_duplicates('Feed1');
    SELECT 'TC-06: Verify No Duplicates in Feed-1 - Check output manually' AS Test_Result;


    CALL generate_feed('Feed2', 15, 15);
    TRUNCATE TABLE comparison_results;
    CALL compare_feeds('Feed2', 'Feed1');
    SELECT COUNT(*) INTO row_count FROM comparison_results;
    IF row_count > 0 THEN
         SELECT 'TC-07: Compare Feed-2 to Feed-1 - PASSED (Results generated)' AS Test_Result;
    ELSE
         SELECT 'TC-07: Compare Feed-2 to Feed-1 - FAILED (No results)' AS Test_Result;
    END IF;


END$$

DELIMITER ;

CALL run_automated_tests();



