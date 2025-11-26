SELECT * FROM groups;

DROP FUNCTION IF EXISTS get_groups_by_deparnment(VARCHAR);

CREATE FUNCTION get_groups_by_deparnment(department VARCHAR)
RETURNS void AS $$
DECLARE
    group_record RECORD;
BEGIN
    FOR group_record IN
        SELECT group_name
        FROM groups g
        WHERE g.department_name = department
    LOOP
        RAISE NOTICE '%', group_record.group_name;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM get_groups_by_deparnment('Информационные технологии и программирование');