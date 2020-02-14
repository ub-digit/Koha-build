UPDATE search_field sf
  LEFT JOIN search_marc_to_field smtf ON sf.id = smtf.search_field_id
  LEFT JOIN search_marc_map smm ON smtf.search_marc_map_id = smm.id
SET smtf.sort = 0 WHERE sf.name = 'title' AND index_name = 'biblios' AND marc_type = 'marc21';

INSERT INTO search_marc_map (index_name, marc_type, marc_field) VALUES('biblios', 'marc21', '245a');

INSERT INTO search_marc_to_field(search_marc_map_id, search_field_id, facet, suggestible, sort, search)
SELECT LAST_INSERT_ID(), id, 0, 0, 1, 0 FROM search_field WHERE name = 'title';
