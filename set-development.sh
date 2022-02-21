#!/bin/bash

kohaplugindir="$(grep -Po '(?<=<pluginsdir>).*?(?=</pluginsdir>)' $KOHA_CONF)"

rm -r $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/OverdueTool
rm $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/OverdueTool.pm

ln -s "/home/jraisa//koha-plugin-overdue-tool/Koha/Plugin/Fi/KohaSuomi/OverdueTool" $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/OverdueTool
ln -s "/home/jraisa//koha-plugin-overdue-tool/Koha/Plugin/Fi/KohaSuomi/OverdueTool.pm" $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/OverdueTool.pm

DATABASE=`xmlstarlet sel -t -v 'yazgfs/config/database' $KOHA_CONF`
HOSTNAME=`xmlstarlet sel -t -v 'yazgfs/config/hostname' $KOHA_CONF`
PORT=`xmlstarlet sel -t -v 'yazgfs/config/port' $KOHA_CONF`
USER=`xmlstarlet sel -t -v 'yazgfs/config/user' $KOHA_CONF`
PASS=`xmlstarlet sel -t -v 'yazgfs/config/pass' $KOHA_CONF`

mysql --user=$USER --password="$PASS" --port=$PORT --host=$HOST $DATABASE << END
DELETE FROM plugin_data where plugin_class = 'Koha::Plugin::Fi::KohaSuomi::OverdueTool';
DELETE FROM plugin_methods where plugin_class = 'Koha::Plugin::Fi::KohaSuomi::OverdueTool';
INSERT INTO plugin_data (plugin_class,plugin_key,plugin_value) VALUES ('Koha::Plugin::Fi::KohaSuomi::OverdueTool','__INSTALLED__','1');
INSERT INTO plugin_data (plugin_class,plugin_key,plugin_value) VALUES ('Koha::Plugin::Fi::KohaSuomi::OverdueTool','__INSTALLED_VERSION__','${VERSION}');
INSERT INTO plugin_data (plugin_class,plugin_key,plugin_value) VALUES ('Koha::Plugin::Fi::KohaSuomi::OverdueTool','__ENABLED__','1');

INSERT INTO plugin_methods (plugin_class, plugin_method) values 
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'abs_path'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'api_namespace'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'api_routes'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'as_heavy'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'bundle_path'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'canonpath'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'catdir'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'catfile'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'curdir'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'configure'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'decode_json'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'disable'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'enable'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'except'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'export'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'export_fail'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'export_ok_tags'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'export_tags'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'export_to_level'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'file_name_is_absolute'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'get_metadata'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'get_plugin_dir'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'get_plugin_http_path'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'get_qualified_table_name'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'get_template'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'go_home'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'import'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'install'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'intranet_catalog_biblio_enhancements_toolbar_button'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'is_enabled'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'max'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'mbf_dir'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'mbf_exists'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'mbf_open'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'mbf_path'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'mbf_read'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'mbf_validate'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'new'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'no_upwards'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'only'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'output'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'output_html'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'output_html_with_http_headers'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'output_with_http_headers'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'path'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'plugins'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'require_version'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'retrieve_data'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'rootdir'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'search_path'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'store_data'),
     ('Koha::Plugin::Fi::KohaSuomi::OverdueTool', 'updir');
END

