-- Change description (was library(852bc))
UPDATE search_field sf
  SET sf.description = 'library' WHERE sf.name = 'library';

-- Change mapping (852bc => 852b)
UPDATE search_marc_map smm
  LEFT JOIN search_marc_to_field smtf ON smm.id = smtf.search_marc_map_id
  LEFT JOIN search_field sf ON sf.id = smtf.search_field_id
SET smm.marc_field = '852b'
  WHERE smm.index_name = 'biblios' AND smm.marc_type = 'marc21' AND sf.name = 'library';

-- Add new 'collection' field
INSERT INTO search_field(`name`, `label`, `type`) VALUES ('collection', 'collection', 'string');

-- Add mapping for 'collection' field
INSERT INTO search_marc_map(`index_name`, `marc_type`, `marc_field`) VALUES ('biblios', 'marc21', '852c');

-- Add 852c mapping to 'collection' field
INSERT INTO search_marc_to_field(search_marc_map_id, search_field_id, facet, suggestible, sort, search)
SELECT smm.id, sf.id, 0, 0, 0, 1 FROM search_field sf
JOIN search_marc_map smm ON index_name = 'biblios' AND marc_type = 'marc21' AND marc_field = '852c' AND name = 'collection';
