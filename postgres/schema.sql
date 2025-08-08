
SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;


CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;



COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';



CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;



COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET search_path = public, pg_catalog;


CREATE TYPE test_behaviour AS ENUM (
    'allow',
    'block'
);



CREATE TYPE test_failure_severity AS ENUM (
    'warning',
    'critical'
);



CREATE TYPE test_outcome AS ENUM (
    'pass',
    'warning',
    'critical',
    'skip'
);



CREATE FUNCTION suite_execution_create_passkey() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
NEW.passkey := encode(digest(random()::text || NEW.ip || NEW.user_agent, 'sha1'), 'hex');
RETURN NEW;
END;
$$;



CREATE FUNCTION suite_execution_metadata(id integer) RETURNS TABLE(timestamp_iso8601 text, ip text, user_agent text)
    LANGUAGE plpgsql
    AS $_$
BEGIN
RETURN QUERY SELECT to_char(timestamp at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS timestamp_iso8601, host(suite_execution.ip) AS ip, suite_execution.user_agent FROM suite_execution WHERE suite_execution.id = $1;

IF NOT FOUND THEN
RAISE EXCEPTION USING ERRCODE = '22000', MESSAGE = 'Test suite execution ID ' || $1 || ' does not exist', TABLE = 'suite_execution', COLUMN = 'id';
END IF;
END;
$_$;



CREATE FUNCTION suite_execution_metadata(id integer, passkey character varying) RETURNS TABLE(timestamp_iso8601 text, ip text, user_agent text)
    LANGUAGE plpgsql
    AS $_$
BEGIN
RETURN QUERY SELECT to_char(timestamp at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') AS timestamp_iso8601, host(suite_execution.ip) AS ip, suite_execution.user_agent FROM suite_execution WHERE suite_execution.id = $1 AND suite_execution.passkey = $2;

IF NOT FOUND THEN
IF EXISTS (SELECT 1 FROM suite_execution WHERE suite_execution.id = $1) THEN
RAISE EXCEPTION USING ERRCODE = '22000', MESSAGE = 'Invalid passkey for test suite execution ID ' || $1, TABLE = 'suite_execution', COLUMN = 'passkey';
ELSE
RAISE EXCEPTION USING ERRCODE = '22000', MESSAGE = 'Test suite execution ID ' || $1 || ' does not exist', TABLE = 'suite_execution', COLUMN = 'id';
END IF;
END IF;
END;
$_$;



CREATE FUNCTION suite_execution_test_test_id_live() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
IF NOT EXISTS (SELECT 1 FROM test WHERE id = NEW.test_id AND live = true) THEN
RAISE EXCEPTION USING ERRCODE = '23000', MESSAGE = 'Test ID ' || NEW.test_id || ': test is not live', DETAIL = 'Tests must be live in order for results to be recorded for them.', TABLE = 'suite_execution_test', COLUMN = 'test_id', CONSTRAINT = 'test_id_live';
END IF;
RETURN NULL;
END;
$$;



CREATE FUNCTION test_outcome_array_add(a integer[], b integer[]) RETURNS integer[]
    LANGUAGE plpgsql
    AS $$
BEGIN
RETURN array[a[1]+b[1],a[2]+b[2],a[3]+b[3],a[4]+b[4]];
END;
$$;



CREATE FUNCTION test_outcome_to_array(test_outcome) RETURNS integer[]
    LANGUAGE plpgsql
    AS $_$
BEGIN
CASE $1
WHEN 'pass' THEN RETURN array[1,0,0,0];
WHEN 'warning' THEN RETURN array[0,1,0,0];
WHEN 'critical' THEN RETURN array[0,0,1,0];
WHEN 'skip' THEN RETURN array[0,0,0,1];
ELSE RETURN array[0,0,0,0];
END CASE;
END;
$_$;



CREATE FUNCTION test_suite_execution_hierarchy(id integer) RETURNS TABLE(type character, id integer, id_path integer[], title text, description text, behaviour test_behaviour, live boolean, test_function text, timeout smallint, parent integer, outcome test_outcome, reason text, duration integer, outcome_total integer[])
    LANGUAGE sql STABLE
    AS $_$
WITH RECURSIVE hierarchy AS (
(
SELECT 'c' as type, id, array[id] AS id_path, title, description, NULL::test_behaviour AS behaviour, live, NULL::text AS test_function, NULL::smallint AS timeout, parent, array[execute_order] AS execute_order
FROM category
WHERE parent IS NULL
) UNION (
SELECT e.type, e.id, (h.id_path || e.id), e.title, e.description, e.behaviour, (h.live and e.live), e.test_function, e.timeout, e.parent, (h.execute_order || e.execute_order)
FROM (
SELECT 't' as type, id, title, NULL::text AS description, behaviour, live, test_function, timeout, parent, execute_order
FROM test
WHERE id IN (SELECT test_id FROM suite_execution_test WHERE id = $1)
UNION
SELECT 'c' as type, id, title, description, NULL::test_behaviour AS behaviour, live, NULL::text AS test_function, NULL::smallint AS timeout, parent, execute_order
FROM category
) e, hierarchy h
WHERE e.parent = h.id AND h.type = 'c'
)
), hierarchy_results AS (
SELECT type, hierarchy.id, id_path, title, description, behaviour, live, test_function, timeout, parent, execute_order, outcome, reason, duration, test_outcome_to_array(outcome) AS outcome_count
FROM hierarchy
LEFT JOIN suite_execution_test ON suite_execution_test.id = $1 AND hierarchy.id = suite_execution_test.test_id AND type = 't'
), outcome_totals AS (
SELECT unnest(id_path[1:array_length(id_path,1)-1]) AS category_id, test_outcome_array_sum(outcome_count) AS outcome_total
FROM hierarchy_results
WHERE type = 't'
GROUP BY category_id
), hierarchy_with_outcome_totals AS (
SELECT type, id, id_path, title, description, behaviour, live, test_function, timeout, parent, execute_order, outcome, reason, duration, outcome_total
FROM hierarchy_results
LEFT JOIN outcome_totals ON hierarchy_results.id = outcome_totals.category_id AND type = 'c'
ORDER BY execute_order
), hierarchy_overall_outcome_totals AS (
SELECT 'c'::char AS type, 0 AS id, NULL::int[] AS id_path, 'Test suite execution'::text AS title, 'This is a meta-row summarising the outcome totals for this test suite execution.'::text AS description, NULL::test_behaviour AS behaviour, NULL::boolean AS live, NULL::text AS test_function, NULL::smallint AS timeout, NULL::int AS parent, NULL::test_outcome AS outcome, NULL::text AS reason, NULL::int AS duration, test_outcome_array_sum(outcome_total) AS outcome_total
FROM hierarchy_with_outcome_totals
WHERE type = 'c' AND parent IS NULL AND outcome_total IS NOT NULL
) (
SELECT type, id, id_path, title, description, behaviour, live, test_function, timeout, parent, outcome, reason, duration, outcome_total
FROM hierarchy_overall_outcome_totals
WHERE outcome_total <> array[0,0,0,0]
) UNION ALL (
SELECT type, id, id_path, title, description, behaviour, live, test_function, timeout, parent, outcome, reason, duration, outcome_total
FROM hierarchy_with_outcome_totals
WHERE type = 't' OR (type = 'c' AND outcome_total IS NOT NULL)
)
$_$;



COMMENT ON FUNCTION test_suite_execution_hierarchy(id integer) IS 'Returns a table representing the hierarchy of the BrowserAudit test suite that was executed for the given suite execution ID. Rows represent either categories or tests, and are ordered by when they begin executing (relative to each other; e.g., the row with order {2,2,5} executes before the row with order {2,3}). The column defining the ordering (execute_order) exists in the returned table for convenience.

Rows contain additional information specific to this test suite execution:
* Rows representing tests contain information about the outcome of this test during this execution, the reason for this outcome, and the amount of time the test function spent executing.
* Rows representing categories contain totals of the numbers of child tests ending in each possible outcome.

The table''s first row is a special "meta-row" (with id 0) that contains the total number of tests ending in each possible outcome for the entire test suite execution in the outcome_total column. Only the value of outcome_total will be of interest in this first row; the other columns can be ignored.

Note that this hierarchy may not comprise the default test suite that existed at the time at which this execution occurred: the user may have chosen not to some categories of tests.

Columns:
* type: what type of element this row represents in the hierarchy (''c'' = category; ''t'' = test)
* id: the ID of the category or test, as it appears in either the category or test table
* id_path: an array representing the path from the hypothetical root of the hierarchy to this element; all IDs except for the last are category IDs, and the last ID will be the one representing this element (and is thus either a category or test ID depending on the value in the type column)
* title: the title of this category or test; may contain unescaped HTML
description: the description of this category, or NULL if this element is a test; may contain unescaped HTML
behaviour: describes the behaviour the test function is testing (either ''allow'' or ''block''), or NULL if this element is a category
* live: whether this category or test is still live in the current BrowserAudit test suite; for this element to be live, its parent category must also be live
* test_function: the test function executed on the client side by the BrowserAudit test framework, or NULL if this element is a category
* timeout: the length of the timeout (in milliseconds) that the test function relies upon in order to execute, or NULL if this test does not rely on a timeout or if this element is a category
* parent: the (category) ID of this element''s parent element in the hierarchy
* execute_order: an array representing the order in which this category or test begins executing, relative to the other elements in the hierarchy
* outcome: the outcome of this test (''pass'', ''warning'', ''critical'' or ''skip''), or NULL if this element is a category
* reason: the reason for the above outcome, or NULL if this element is a category; contains user-malleable data (beware!)
* duration: the time in milliseconds that the test function spent executing, or NULL if this element is a category
* outcome_total: a 4-element array containing the number of tests beneath this category that passed, failed with a warning, failed critically, and were skipped respectively, or NULL if this element is a test

An empty table is returned if no test results have been recorded with the given test suite execution ID.';



CREATE AGGREGATE test_outcome_array_sum(integer[]) (
    SFUNC = test_outcome_array_add,
    STYPE = integer[],
    INITCOND = '{0,0,0,0}'
);


SET default_tablespace = '';

SET default_with_oids = false;


CREATE TABLE category (
    id integer NOT NULL,
    parent integer,
    title text NOT NULL,
    description text,
    execute_order integer NOT NULL,
    live boolean NOT NULL,
    in_default boolean NOT NULL,
    short_description text
);



CREATE SEQUENCE category_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE category_id_seq OWNED BY category.id;



CREATE TABLE suite_execution (
    id integer NOT NULL,
    passkey character(40) NOT NULL,
    "timestamp" timestamp with time zone DEFAULT now() NOT NULL,
    user_agent text NOT NULL,
    ip inet NOT NULL,
    browseraudit_version character(40) NOT NULL
);



CREATE SEQUENCE suite_execution_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE suite_execution_id_seq OWNED BY suite_execution.id;



CREATE TABLE suite_execution_setting (
    id integer NOT NULL,
    key character varying(20) NOT NULL,
    value character varying(20) NOT NULL,
    CONSTRAINT valid_pair CHECK (((((key)::text = 'displaymode'::text) AND ((value)::text ~ '^(?:full|summary|none)$'::text)) OR (((key)::text = 'sendresults'::text) AND ((value)::text ~ '^(?:true|false)$'::text))))
);



CREATE TABLE suite_execution_test (
    id integer NOT NULL,
    test_id integer NOT NULL,
    outcome test_outcome NOT NULL,
    reason text NOT NULL,
    duration integer NOT NULL,
    CONSTRAINT duration_nonnegative CHECK ((duration >= 0))
);



CREATE TABLE test (
    id integer NOT NULL,
    title text NOT NULL,
    timeout smallint,
    behaviour test_behaviour NOT NULL,
    failure_severity test_failure_severity NOT NULL,
    parent integer NOT NULL,
    execute_order integer NOT NULL,
    test_function text NOT NULL,
    live boolean NOT NULL
);



CREATE SEQUENCE test_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;



ALTER SEQUENCE test_id_seq OWNED BY test.id;



ALTER TABLE ONLY category ALTER COLUMN id SET DEFAULT nextval('category_id_seq'::regclass);



ALTER TABLE ONLY suite_execution ALTER COLUMN id SET DEFAULT nextval('suite_execution_id_seq'::regclass);



ALTER TABLE ONLY test ALTER COLUMN id SET DEFAULT nextval('test_id_seq'::regclass);



ALTER TABLE ONLY category
    ADD CONSTRAINT category_pkey PRIMARY KEY (id);



ALTER TABLE ONLY suite_execution
    ADD CONSTRAINT suite_execution_pkey PRIMARY KEY (id);



ALTER TABLE ONLY suite_execution_setting
    ADD CONSTRAINT suite_execution_setting_pkey PRIMARY KEY (id, key);



ALTER TABLE ONLY suite_execution_test
    ADD CONSTRAINT suite_execution_test_pkey PRIMARY KEY (id, test_id);



ALTER TABLE ONLY test
    ADD CONSTRAINT test_pkey PRIMARY KEY (id);



ALTER TABLE ONLY category
    ADD CONSTRAINT unique_parent_and_execute_order UNIQUE (parent, execute_order);



CREATE TRIGGER create_passkey BEFORE INSERT ON suite_execution FOR EACH ROW EXECUTE PROCEDURE suite_execution_create_passkey();



CREATE TRIGGER test_id_live AFTER INSERT ON suite_execution_test FOR EACH ROW EXECUTE PROCEDURE suite_execution_test_test_id_live();



ALTER TABLE ONLY category
    ADD CONSTRAINT category_parent_fkey FOREIGN KEY (parent) REFERENCES category(id);



ALTER TABLE ONLY suite_execution_setting
    ADD CONSTRAINT id_fkey FOREIGN KEY (id) REFERENCES suite_execution(id);



ALTER TABLE ONLY suite_execution_test
    ADD CONSTRAINT id_fkey FOREIGN KEY (id) REFERENCES suite_execution(id);



ALTER TABLE ONLY suite_execution_test
    ADD CONSTRAINT test_id_fkey FOREIGN KEY (test_id) REFERENCES test(id);



ALTER TABLE ONLY test
    ADD CONSTRAINT test_parent_fkey FOREIGN KEY (parent) REFERENCES category(id);



