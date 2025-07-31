
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
