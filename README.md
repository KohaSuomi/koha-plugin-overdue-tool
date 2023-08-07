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

Ohjeet pääkäyttäjille löytyy [repostitorion wikistä](https://github.com/KohaSuomi/koha-plugin-overdue-tool/wiki/Laskutusty%C3%B6kalun-k%C3%A4ytt%C3%B6%C3%B6notto%E2%80%90ohjeet)
