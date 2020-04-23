-- ----------------------------------------------------
-- Adds indexes and constraints on geonames tables
-- ----------------------------------------------------

--
-- Drop existing constraints if any
-- 
ALTER TABLE ONLY alternatename DROP CONSTRAINT IF EXISTS alternatenameid_pkey;
ALTER TABLE ONLY geoname DROP CONSTRAINT IF EXISTS geonameid_pkey;
ALTER TABLE ONLY countryinfo DROP CONSTRAINT IF EXISTS iso_alpha2_pkey;
ALTER TABLE ONLY countryinfo DROP CONSTRAINT IF EXISTS countryinfo_geonameid_fkey;
ALTER TABLE ONLY alternatename DROP CONSTRAINT IF EXISTS alternatename_geonameid_fkey;

--
-- Drop existing indexes if any
-- 
DROP INDEX IF EXISTS countryinfo_geonameid_idx;
DROP INDEX IF EXISTS alternatename_geonameid_idx;
DROP INDEX IF EXISTS geoname_name_idx;
DROP INDEX IF EXISTS geoname_asciiname_idx;
DROP INDEX IF EXISTS geoname_fclass_idx;
DROP INDEX IF EXISTS geoname_fcode_idx;
DROP INDEX IF EXISTS geoname_country_idx;
DROP INDEX IF EXISTS geoname_cc2_idx;
DROP INDEX IF EXISTS geoname_admin1_idx;
DROP INDEX IF EXISTS geoname_admin2_idx;
DROP INDEX IF EXISTS geoname_admin3_idx;
DROP INDEX IF EXISTS geoname_admin4_idx;
DROP INDEX IF EXISTS alternatename_isolanguage_idx;
DROP INDEX IF EXISTS alternatename_alternatename_idx;
DROP INDEX IF EXISTS alternatename_ispreferredname_idx;
DROP INDEX IF EXISTS alternatename_isshortname_idx;
DROP INDEX IF EXISTS alternatename_iscolloquial_idx;
DROP INDEX IF EXISTS alternatename_ishistoric_idx;
DROP INDEX IF EXISTS postalcodes_countrycode_idx;
DROP INDEX IF EXISTS postalcodes_admin1name_idx;
DROP INDEX IF EXISTS postalcodes_admin1code_idx;
DROP INDEX IF EXISTS postalcodes_admin2name_idx;
DROP INDEX IF EXISTS postalcodes_admin2code_idx;
DROP INDEX IF EXISTS postalcodes_admin3name_idx;
DROP INDEX IF EXISTS postalcodes_admin3code_idx;

-- 
-- Create constraints and indexes
--

-- PKs
ALTER TABLE ONLY alternatename
    ADD CONSTRAINT alternatenameid_pkey PRIMARY KEY (alternatenameid);
ALTER TABLE ONLY geoname
    ADD CONSTRAINT geonameid_pkey PRIMARY KEY (geonameid);
ALTER TABLE ONLY countryinfo
    ADD CONSTRAINT iso_alpha2_pkey PRIMARY KEY (iso_alpha2);

-- Indexes needed to build FK constraints
CREATE INDEX countryinfo_geonameid_idx ON countryinfo USING btree (geonameid);
CREATE INDEX alternatename_geonameid_idx ON alternatename USING btree (geonameid);

-- FK constraints
ALTER TABLE ONLY countryinfo
    ADD CONSTRAINT countryinfo_geonameid_fkey FOREIGN KEY (geonameid) REFERENCES geoname(geonameid);
ALTER TABLE ONLY alternatename
    ADD CONSTRAINT alternatename_geonameid_fkey FOREIGN KEY (geonameid) REFERENCES geoname(geonameid);
    
-- Remaining indexes
CREATE INDEX geoname_name_idx ON geoname USING btree (name);
CREATE INDEX geoname_asciiname_idx ON geoname USING btree (asciiname);
CREATE INDEX geoname_fclass_idx ON geoname USING btree (fclass);
CREATE INDEX geoname_fcode_idx ON geoname USING btree (fcode);
CREATE INDEX geoname_country_idx ON geoname USING btree (country);
CREATE INDEX geoname_cc2_idx ON geoname USING btree (cc2);
CREATE INDEX geoname_admin1_idx ON geoname USING btree (admin1);
CREATE INDEX geoname_admin2_idx ON geoname USING btree (admin2);
CREATE INDEX geoname_admin3_idx ON geoname USING btree (admin3);
CREATE INDEX geoname_admin4_idx ON geoname USING btree (admin4);

CREATE INDEX alternatename_isolanguage_idx ON alternatename USING btree (isolanguage);
CREATE INDEX alternatename_alternatename_idx ON alternatename USING btree (alternatename);
CREATE INDEX alternatename_ispreferredname_idx ON alternatename USING btree (ispreferredname);
CREATE INDEX alternatename_isshortname_idx ON alternatename USING btree (isshortname);
CREATE INDEX alternatename_iscolloquial_idx ON alternatename USING btree (iscolloquial);
CREATE INDEX alternatename_ishistoric_idx ON alternatename USING btree (ishistoric);

CREATE INDEX postalcodes_countrycode_idx ON postalcodes USING btree (countrycode);
CREATE INDEX postalcodes_admin1name_idx ON postalcodes USING btree (admin1name);
CREATE INDEX postalcodes_admin1code_idx ON postalcodes USING btree (admin1code);
CREATE INDEX postalcodes_admin2name_idx ON postalcodes USING btree (admin2name);
CREATE INDEX postalcodes_admin2code_idx ON postalcodes USING btree (admin2code);
CREATE INDEX postalcodes_admin3name_idx ON postalcodes USING btree (admin3name);
CREATE INDEX postalcodes_admin3code_idx ON postalcodes USING btree (admin3code);
