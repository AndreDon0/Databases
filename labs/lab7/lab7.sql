-- variant 1

-- Task 1
DROP TYPE IF EXISTS operation_sign CASCADE;
DROP TABLE IF EXISTS operation_log CASCADE;
DROP TABLE IF EXISTS operations CASCADE;

CREATE TYPE operation_sign AS ENUM ('+', '-');

CREATE TABLE operations (
    id BIGSERIAL PRIMARY KEY,
    account_number VARCHAR(20) NOT NULL,
    operation_name VARCHAR(100) DEFAULT 'undefined' NOT NULL,
    operation_sum DECIMAL(40, 2) NOT NULL
);

CREATE TABLE operation_log (
    operation_id BIGINT PRIMARY KEY,
    account_number VARCHAR(20) NOT NULL,
    operation_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    operation_type operation_sign NOT NULL,
    FOREIGN KEY (operation_id) REFERENCES operations(id)
);

-- Insert 10 rows into operations table
INSERT INTO operations (account_number, operation_name, operation_sum) VALUES
('ACC123', 'Initial Deposit', 5000.00),
('ACC123', 'Salary Credit', 75000.00),
('ACC123', 'ATM Withdrawal', 2500.00),
('ACC123', 'Online Payment', 1500.75),
('ACC123', 'Transfer Received', 3000.00),
('ACC123', 'Utility Bill', 850.50),
('ACC456', 'Freelance Payment', 25000.00),
('ACC456', 'Grocery Purchase', 3200.00),
('ACC456', 'Loan Repayment', 12000.00),
('ACC456', 'Investment Deposit', 10000.00);

-- Insert 10 rows into operation_log
INSERT INTO operation_log (operation_id, account_number, operation_type, operation_date) VALUES
(1, 'ACC123', '+', '2025-12-01 09:30:00'),     -- Initial Deposit (morning)
(2, 'ACC123', '+', '2025-12-01 17:45:00'),     -- Salary Credit (evening)
(3, 'ACC123', '-', '2025-12-02 14:20:00'),     -- ATM Withdrawal (afternoon)
(4, 'ACC123', '-', '2025-12-02 19:15:00'),     -- Online Payment (evening)
(5, 'ACC123', '+', '2025-12-03 11:10:00'),     -- Transfer Received (morning)
(6, 'ACC123', '-', '2025-12-03 20:30:00'),     -- Utility Bill (night)
(7, 'ACC456', '+', '2025-12-02 10:00:00'),     -- Freelance Payment (morning)
(8, 'ACC456', '-', '2025-12-03 16:45:00'),     -- Grocery Purchase (afternoon)
(9, 'ACC456', '-', '2025-12-04 08:20:00'),     -- Loan Repayment (morning)
(10, 'ACC456', '+', '2025-12-04 15:30:00');    -- Investment Deposit (afternoon)

-- Task 2
CREATE OR REPLACE FUNCTION statement_of_account(acc_number VARCHAR, start_date TIMESTAMP, end_date TIMESTAMP)
RETURNS VOID AS
$$
DECLARE
    rec RECORD;
    pos_cursor REFCURSOR;
    neg_cursor REFCURSOR;
    oper_count INT = 0;
    avg_sum DECIMAL(40,2) = 0;
    i INT = 0;
BEGIN

    OPEN pos_cursor FOR
        SELECT l.operation_type, o.operation_sum, l.operation_date
        FROM operations o
        JOIN operation_log l ON o.id = l.operation_id
        WHERE l.account_number = acc_number
          AND l.operation_type = '+'
          AND l.operation_date BETWEEN start_date AND end_date
        ORDER BY 2 DESC, 3 DESC;

    OPEN neg_cursor FOR
        SELECT l.operation_type, o.operation_sum, l.operation_date
        FROM operations o
        JOIN operation_log l ON o.id = l.operation_id
        WHERE l.account_number = acc_number
          AND l.operation_type = '-'
          AND l.operation_date BETWEEN start_date AND end_date
        ORDER BY 2 DESC, 3 DESC;
    
    RAISE NOTICE '--- Statement of Account for % from % to % ---', acc_number, start_date, end_date;

    LOOP
        FETCH pos_cursor INTO rec;
        EXIT WHEN NOT FOUND;
        IF i <> 3 THEN
            RAISE NOTICE '% | % | %', rec.operation_type, rec.operation_sum, rec.operation_date;
            i := i + 1;
        END IF;
        oper_count := oper_count + 1;
        avg_sum := avg_sum + rec.operation_sum;
    END LOOP;

    i := 0;
    LOOP
        FETCH neg_cursor INTO rec;
        EXIT WHEN NOT FOUND;
        IF i <> 3 THEN
            RAISE NOTICE '% | % | %', rec.operation_type, rec.operation_sum, rec.operation_date;
            i := i + 1;
        END IF;
        oper_count := oper_count + 1;
        avg_sum := avg_sum - rec.operation_sum;
    END LOOP;
    CLOSE pos_cursor;
    CLOSE neg_cursor;

    IF oper_count <> 0 THEN
        avg_sum := avg_sum / oper_count;
        RAISE NOTICE '--- Total operations: % | Average sum: % ---', oper_count, avg_sum;
    ELSE
        RAISE NOTICE 'No operations found in the given period.';
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT statement_of_account('ACC123', '2026-12-01 00:00:00', '2025-12-03 23:59:59');

-- Task 3
CREATE OR REPLACE PROCEDURE account_operation(
    acc_number VARCHAR,
    id BIGINT,
    oper_sum DECIMAL(40,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF oper_sum > 0 THEN
        INSERT INTO operations (id, account_number, operation_name, operation_sum)
        VALUES (id, acc_number, 'внесение денег на счет', oper_sum);

        INSERT INTO operation_log (operation_id, account_number, operation_type, operation_date)
        VALUES (id, acc_number, '+', now());
    END IF;

    COMMIT;
END;
$$;

CALL account_operation('ACC789', 23, -1500.00);

SELECT * FROM operations;
SELECT * FROM operation_log;

-- Task 4

SELECT * FROM workers;

SELECT
    w.id, w.fn, w.ln, w.sn,
    STRING_AGG(DISTINCT tech, ' | ' ORDER BY tech) AS technologies
FROM workers AS w
LEFT JOIN LATERAL (
    SELECT t
    FROM regexp_split_to_table(w.work_description, '[^A-z[:punct:]]+') AS t
    WHERE t IS NOT NULL AND t <> ''
) AS tech(tech) ON true
GROUP BY w.id
ORDER BY w.id;
