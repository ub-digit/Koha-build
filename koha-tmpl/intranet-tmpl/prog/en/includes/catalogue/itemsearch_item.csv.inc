[%- USE Branches -%]
[%- USE Koha -%]
[%- USE ItemTypes -%]
[%- USE AuthorisedValues -%]
[%- SET biblio = item.biblio -%]
[%- SET biblioitem = item.biblioitem -%]
"[% biblio.title | html %] [% IF ( Koha.Preference( 'marcflavour' ) == 'UNIMARC' && biblio.author ) %]by [% END %][% biblio.author | html %]", "[% (biblioitem.publicationyear || biblio.copyrightdate) | html %]", "[% biblioitem.publishercode | html %]", "[% AuthorisedValues.GetByCode( 'CCODE', item.ccode ) | html %]", "[% item.barcode | html %]", "[% item.itemcallnumber | html %]", "[% Branches.GetName(item.homebranch) | html %]", "[% Branches.GetName(item.holdingbranch) | html %]", "[% AuthorisedValues.GetDescriptionByKohaField(frameworkcode => biblio.frameworkcode, kohafield => 'items.location', authorised_value => item.location) | html %]", "[% ItemTypes.GetDescription(item.itype) | html %]", "[% item.stocknumber | html %]", "[% AuthorisedValues.GetDescriptionByKohaField(frameworkcode => biblio.frameworkcode, kohafield => 'items.notforloan', authorised_value => item.notforloan) | html %]","[% AuthorisedValues.GetByCode( 'LOST', item.itemlost ) || "" | html %]","[% AuthorisedValues.GetByCode( 'WITHDRAWN', item.withdrawn ) || "" | html %]", "[% (item.issues || 0) | html %]"
