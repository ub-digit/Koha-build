[% USE Koha %]
<div class="gradient">
<h1 id="logo"><a href="/cgi-bin/koha/mainpage.pl">[% LibraryName|html %]</a></h1><!-- Begin Desks Resident Search Box -->
<div id="header_search">
        <div id="desk_search" class="residentsearch">
    <p class="tip">Desk search:</p>
        <form action="[% script_name|html %]" method="post">
        <input class="head-searchbox" type="text" name="desk_name" value="[% searchfield|html %]" size="40" />
                <input type="submit" name="submit" value="OK" class="submit" />
        </form>
        </div>

    [% INCLUDE 'patron-search-box.inc' %]

        [% IF ( CAN_user_catalogue ) %]
    <div id="catalog_search" class="residentsearch">
        <p class="tip">Enter search keywords:</p>
                <form action="/cgi-bin/koha/catalogue/search.pl"  method="get" id="cat-search-block">
             [% IF ( Koha.Preference('IntranetCatalogSearchPulldown') ) %][% INCLUDE 'search_indexes.inc' %][% END %]
             <input type="text" name="q" id="search-form" size="40" value="" title="Enter the terms you wish to search for." class="head-searchbox form-text" />
                                <input type="submit" value="Submit"  class="submit" />
                </form>
        </div>[% END %]
                        <ul>
            <li><a class="keep_text" href="#desk_search">Search desks</a></li>
            [% IF ( CAN_user_circulate_circulate_remaining_permissions ) %]<li><a class="keep_text" href="#circ_search">Check out</a></li>[% END %]
            [% IF ( CAN_user_catalogue ) %]<li><a class="keep_text" href="#catalog_search">Search the catalog</a></li>[% END %]
                        </ul>
</div>
</div>
<!-- End Desks Resident Search Box -->
