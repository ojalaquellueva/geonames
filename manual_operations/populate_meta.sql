-- ------------------------------------------------------------------
-- Manually populate metadata table "meta"
-- 
-- Added to pipeline, will be handled automatically in
-- future DB builds
-- ------------------------------------------------------------------

\c gnrs_dev


INSERT INTO meta (
version,
data_uri, 
data_version, 
date_accessed
)
VALUES (
'2.0', 
'http://download.geonames.org/export/dump/', 
'2020-04-21', 
'2020-04-21'
);