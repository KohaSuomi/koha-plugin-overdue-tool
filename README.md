# Koha-Suomi Overdue tool plugin

This plugin is for creating and sending Finvoice, letter and PDF invoices.

# Installing

Koha's Plugin System allows for you to add additional tools and reports to Koha that are specific to your library. Plugins are installed by uploading KPZ ( Koha Plugin Zip ) packages. A KPZ file is just a zip file containing the perl files, template files, and any other files necessary to make the plugin work.

The plugin system needs to be turned on by a system administrator.

To set up the Koha plugin system you must first make some changes to your install.

Change <enable_plugins>0<enable_plugins> to <enable_plugins>1</enable_plugins> in your koha-conf.xml file
Confirm that the path to <pluginsdir> exists, is correct, and is writable by the web server
Remember to allow access to plugin directory from Apache

    <Directory <pluginsdir>>
        Options Indexes FollowSymLinks
        AllowOverride None
        Require all granted
    </Directory>

Restart your webserver

Once set up is complete you will need to alter your UseKohaPlugins system preference. On the Tools page you will see the Tools Plugins and on the Reports page you will see the Reports Plugins.

# Downloading

From the release page you can download the latest \*.kpz file

## Kehittäjien ohjeet
* Asetustiedosto luodaan etc:n alle nimellä finvoice-config.yaml:
  * laskutusryhmännimi ja sen alle _kaikki_ siihen kuuluvat kirjastopisteet
  * host, käyttäjänimi, salasana ja hakemistopolku, johon laskut palvelutarjoajan päässä lähetetään
  * TAI julkinen avain ssh:n alle (tarkka polku principiossa)

* Laskut muodostuvat kantaan message_queue-tauluun
  * löytyvät hakemalla message_transport_type = "finvoice"
  
* Laskut lähetetään eteenpäin ajamalla run_finvoice.pl, esimerkki ajo OUTI:ssa:
    
`cronjobs/run_finvoice.pl /var/spool/koha/finvoice/ -p /etc/koha/finvoice-config.yaml -c LASKUOU -v --noescape --xsd /var/lib/koha/plugins/Koha/Plugin/Fi/KohaSuomi/OverdueTool/finvoice/Finvoice3.0.xsd --pretty`
  * jokaisella laskutusryhmällä tulee olla oma ajo!
  * ajo kyllä valittaa, jos asetuksissa tms. on jotain pielessä, yleensä laskupohja (ODUECLAIM) ei ole Finvoice3.0 skeeman mukainen (Finvoice3.0.xsd) tai sitten finvoice-config.yaml:issa on sisennykset väärin
  * ajo valittaa melko usein (testeillä) puuttuvasta ssnkey-arvosta (Use of uninitialized value $ssnkey in substitution (s///)), ei ole vaarallista, laskut menee silti läpi (korjataan jossain vaiheessa)

## Ohjeet pääkäyttäjille
### Käyttöönotto
Käyttöönotto vaatii muutamien asetusten lisäämistä.

* Käyttöoikeudet: Laskuttajat tarvitsevat seuraavat käyttäjäoikeudet: Plugins->tool, updatecharges, edit_borrowers ja edit_items.
  * **HUOM!** Muista lisätä käyttäjä myös liitännäisen asetukseen "Sallitut käyttäjät" (Yleiset-asetukset)!

* Laskuja varten täytyy lisätä ilmoituspohja, **ODUECLAIM**, joihin sisältö laitetaan finvoice-, print-, tai pdf-viestityypin pohjalle (muita tyyppejä on mm. Sähköposti, Tekstiviesti). finvoice-pohjaan määritellään Finvoice-sanoman sisältö ja pdf-pohjaan PDF-lasku HTML-muodossa. E-kirjeitä varten tehdään viestipohja ODUECLAIM-viestipohjaan print-pohjaan. ODUECLAIM-pohjaa muokkaamalla voidaan laskea osoitetietoja oikeaan kohtaan, tämä vaatii hieman html/css-tuntemusta. 
  * Viestipohjista on esimerkit saatavilla [Githubista](https://github.com/KohaSuomi/koha-plugin-overdue-tool/tree/22.xx/Koha/Plugin/Fi/KohaSuomi/OverdueTool/examples).
  * [Viestipohjissa käytettävät tägit](https://github.com/KohaSuomi/koha-plugin-overdue-tool/wiki#viestipohjissa-k%C3%A4ytett%C3%A4v%C3%A4t-t%C3%A4git) kootusti.
* **FINVOICE-sanomaa** varten käytetään ODUECLAIM-viestipohjassa finvoice-pohjaa/osiota.
* **PDF-tulostusta** käytettäessä käytetään ODUECLAIM-viestipohjaa ja viestin sisältö laitetaan pdf-pohjaan/osioon. Muista tehdä tarvittaessa kaikki kieliversiot.
* **E-kirjeenä** lähtevien laskujen sisältö laitetaan ODUECLAIM-viestipohjaan Tuloste-pohjaan/osioon. Pohjaan laitetaan vain varsinainen viestin sisältö, ei lähettäjän tai vastaanottajan yhteystietoja. Viestin aihe -kentästä otetaan kirjeen "otsikko", joka tulostuu oikeaan yläreunaan. Muista tehdä tarvittaessa kaikki kieliversiot. Jos kieliversioita ei ole määritetty, käytetään Oletus-kielen tietoja.

* Myöhästymisilmoituksiin tulee määritellä sarake laskuille. Tästä asetuksesta käytetään vain viivettä, jolla haetaan laskutettava materiaali. Jos kaikilla kirjastoilla on sama viive, voi tehdä vain oletussäännön. Viestipohjakin pitää valita, koska ilman sitä tallennus ei onnistu.

* Laskutustyökalu löytyy työkaluliitännäisistä.
* Työkalun asetuksissa voidaan säätää laskuja yleisellä ja laskutusryhmä kohtaisesti.
* Yleisissä asetuksissa voi määrittää seuraavia asioita:
  * _Laskuttava kirjasto:_ toimiiko laskuttavana kirjastona lainaava kirjasto vai niteen omistava kirjasto.
  * _Näytä lainat eräpäivästä x kuukautta taaksepäin:_ oletusasetus, kuinka vanhoja lainoja näytetään laskutustyökalussa.
  * _Jätä laskuttamatta lainat, jotka ovat yli x vuotta vanhat:_ oletusasetus, kuinka vanhoja laskuttamattomia lainoja näytetään laskutustyökalussa.
  * _Laskutetun niteen "ei lainata"-tila:_ määritä tähän laskutettavalle aineistolle asetettavan notforloan-tilan arvo. Se on aika yleisesti arvo 6.
  * _Sallitut käyttäjät (borrowernumberit pilkulla erotettuna):_ kirjoita tähän niiden käyttäjien borrowernumberit, joilla on oikeus päästä laskutustyökaluun. Pääsy kannattaa sallia vain oikeasti laskutusta tekeville.
* Ryhmäasetuksiin tulee näkyviin jokainen määritelty laskutusryhmä ja näkyvät asetukset ovat säädettävissä laskutusryhmäkohtaisesti.
  * laskutusryhmät määritetään liitännäisessä
  * lisää kirjastot ryhmään alasvetovalikosta
* valitse ryhmän laskutustapa: Finvoice, E-lasku tai PDF-lasku
  * _Finvoice_ muodostaa laskuista finvoice-muotoisen xml-tiedoston, joka voidaan viedä kunnan laskutusjärjestelmään ja varsinaiset laksut lähetetään sieltä sitten asiakkalle.
  * _E-lasku_ muodostaa asiakkaille e-kirjeenä lähetettävän laskun. Tämä vaatii, että kimpassa on käytössä e-kirjeiden lähetyspalvelu.
  * _PDF-lasku_ muodostaa pdf-tiedoston/tiedostot, jotka laskuttaja voi itse tulostaa ja lähettää asiakkaille.

* Laskutusryhmän yhteystietoihin voi lisätä tarpeelliset tiedot.
  * **HUOM!** Tilinumero- ja BIC-tunnus-kentät ovat pakollisia kaikissa laskutusmuodoissa.

* Viitenumerot voivat olla kiinteitä tai juoksevia, kiinteän voi lisätä suoraan ODUECLAIM-pohjaan. Kunnan laskuttajilta tulee saada tiedot viitenumeroiden tekemiseen. 
  * **Juoksevaa viitenumeroa varten tarvitaan kehittäjän apua, plugin_data-tauluun pitää lisätä laskutusryhmälle siemenluku mistä viitenumero lasketaan. Siemennumero tulee lisätä OverdueTool-plugille ja plugin_key-kentän arvo pitää alkaa "REFNO_".**

        `INSERT INTO plugin_data (plugin_class, plugin_key, plugin_value) values ("Koha::Plugin::Fi::KohaSuomi::OverdueTool", "REFNO_<laskutusryhmän nimi>", "<siemenluku>");`

* Rajoitus voidaan asetettaa joko vain huollettavalle tai halutessa myös huoltajalle.
  * Huomioi, että huoltajalle lisätty rajoite ei poistu automaattisesti, kun laskutetut aineistot palautetaan. Laskutettavalta asiakkaalta rajoite poistuu automaattisesti.
* Niteen hinnan voi lisätä asiakkaan maksuihin, mutta kannattaa huomioida, että jos käytössä on verkkokirjastossa verkkomaksumahdollisuus, asiakas voi vahingossa maksaa samat korvaushinnat sekä verkkomaksuna, että laskulla.
* Laskutettavista niteistä syntyneet myöhästymismaksut voidaan myös lisätä laskulle. Tässäkin kannattaa ottaa huomioon, että jos kimpalla on verkkokirjastossa käytössä verkkomaksutoiminto, voi asiakas maksaa myöhästymismaksut vahingossa kahteen kertaan.
* _Laskutuslisä_ - kenttään syötetään laskutuslisä, jos sellainen halutaan lisätä laskutusryhmän laskuihin.
* _Viesti asiakkaalle_ -kenttään voit määrittää, minkälainen viesti laitetaan laskutetun asiakkaan (aikuisasiakas tai huoltaja) tietoihin. (Samanlainen viesti, mikä tulee Lisää viesti -toiminnolla)
* _Viesti huollettavalle tai virkaholhoojalle_ -kenttään voit määrittää huollettavalle tai virkaholhoojalle lisättävän viestin.
* _Muuta takaajakäsittely (asiakastyypit pilkulla eroteltuna)_ -kohdassa voi määrittää ne asiakastyypit, joilla on ns. virkaholhoojia. Jos tähän laitetaan asiakastyyppi, virkaholhoojan tiedot tallennetaan finvoice-sanomassa eriin kohtaan kuin se tapahtuisi "normaalissa" takaajakäsittelyssä. Tämä mahdollistaa laskutusjärjestelmissä virkaholhoojan tietojen viennin eri kenttiin kuin normaalitakaajan.

### Laskujen tekeminen

Laskutustyökalu löytyy Työkaluista kohdasta Työkaluliitännäiset. Se ajetaan valitsemalla Toiminnot-valikosta "Käynnistä työkalu".

* Laskutettava aineisto haetaan aikaväliltä. Sivulle tultaessa aikaväli muodostuu automaattisesti myöhästymisilmoituksissa olevan viiveen ja työkalun asetuksissa olevan "Näytä lainat eräpäivästä n kuukautta taaksepäin"-asetuksen mukaan. Aikaväliä voi muuttaa tarvittaessa.
* Laskutettava aineisto näkyy kunkin asiakkaan alla, tiedot saa auki asiakkaan tiedoissa olevasta nuolesta.
* Laskutettavasta aineistoista voi vielä tässä vaiheessa muokata korvaushintaa tai jättää jonkun aineiston pois laskulta ottamalla ruksin pois niteen kohdalta. Aineisto jolle ei ole määritelty korvaushintaa jätetään alustavasti pois laskulta, jos hinnan lisää aineisto laskutetaan. Jos hintatietoa muokkaa, tallennetaan uusi hinta myös niteen tietoihin.
* Kun on tarkistanut laskutettavan aineiston tiedot voi siitä luoda PDF:n, elasku-viestin tai Finvoice-sanoman. Tämä riippuu mitkä pohjat on lisätty laskutusryhmälle. Laskun luonti lisää niteille asetuksissa määritellyn "Laskutettu"-tilan. Jos sivun lataa uudestaan niin juuri äsken laskutettu aineisto ei enää näy listassa. Sen saa näkyviin kun valitsee "Näytä laskutetut".
  * PDF:n, elasku-viestin ja Finvoice-sanoman luontiin käytetään käyttäjän kirjautumiskirjaston viestipohjaa. Jos laskuttaa kerralla useamman kirjaston aineistoa, pitää kirjautua siihen kirjastoon, jolle on luotu ODUECLAIM- tai FINVOICE-pohjat. Yleensä tämä on kunnan pääkirjasto.
* Tuloksia voi myös suodattaa asiakasryhmän ja minimisumman mukaan. Minimisumma kannattaa säätää nollaan, jotta mukaan tulee myös ne asiakkaat, joiden laskutettavien niteiden kaikki korvaushinnat ovat nolla tai tyhjä.
* Ennen PDF:n tulostamista pääsee esikatselu-näkymään, missä näkee sivun asettelun.
* Lasku luodaan asiakkaan ilmoituksiin, jolloin siitä jää jälki järjestelmään. Finvoice-sanomat lähetetään eteenpäin ajastetusti, joten korjauksia voidaan tehdä ennen lähetystä.

### Laskutettujen palautus

Kun asiakkaan kaikki laskutetut niteet palautetaan, poistuu asiakkaalta rajoite. Jos osaa laskutetuista niteistä ei palauteta, jää rajoite paikalleen. Niteille jää laskutettu-tila ja asiakkaan tietoihin tieto (viesti), että hänelle on lähettetty lasku. Nämä tiedot pitää poistaa manuaalisesti.

## Viestipohjissa käytettävät tägit

Laskutuspohjissa voi käyttää seuraavia tägejä.

Laskun numero: `<<invoicenumber>>`<br>
Tilinumero: `<<accountnumber>>`<br>
BIC: `<<biccode>>`<br>
Laskun eräpäivä: `<<invoice_duedate>>`<br>
Laskun eräpäivä (Finvoice muoto): `<<finvoice_duedate>>`<br>
Viitenumero: `<<referencenumber>>`<br>
Lainaajan nimi: `<<issueborname>>`<br>
Lainaajan kirjastokortti: `<<issueborbarcode>>`<br>
Maksettava yhteensä: `<<totalfines>>`<br>
Y-tunnus: `<<businessid>>`<br>
Laskuttajan nimi: `<<grouplibrary>>`<br>
Laskuttajan osoite: `<<groupaddress>>`<br>
Laskuttajan postinumero: `<<groupzipcode>>`<br>
Laskuttajan postitoimipaikka: `<<groupcity>>`<br>
Laskuttajan puhelinnumero: `<<groupphone>>`<br>
Viimeiseksi lainatun niteen lainapäivä: `<<lastitemissuedate>>`<br>
Viimeiseksi lainatun niteen eräpäivä: `<<lastitemduedate>>`<br>

* Teostiedot pitää "ympäröidä" `<item>` ja `</item>` tägeillä, jotta teostiedot tulostuvat laskulle.

`<item>`<br>
`Eräpäivä: <<date_due>>`<br>
`Teos: <<biblio.title>> <<items.enumchron>> / <<biblio.author>>`<br>
`Aineistotyyppi: <<biblioitems.itemtype>>`<br>
`Viivakoodi: <<items.barcode>>`<br>
`Luokka: <<items.itemcallnumber>>`<br>
`Korvaushinta: <<items.replacementprice>> €`<br>
`</item>`<br>

