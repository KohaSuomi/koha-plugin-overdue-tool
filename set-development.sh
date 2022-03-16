#!/bin/bash

kohaplugindir="$(grep -Po '(?<=<pluginsdir>).*?(?=</pluginsdir>)' $KOHA_CONF)"
kohadir="$(grep -Po '(?<=<intranetdir>).*?(?=</intranetdir>)' $KOHA_CONF)"

rm -r $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/OverdueTool
rm $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/OverdueTool.pm

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ln -s "$SCRIPT_DIR/koha-plugin-overdue-tool/Koha/Plugin/Fi/KohaSuomi/OverdueTool" $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/OverdueTool
ln -s "$SCRIPT_DIR/koha-plugin-overdue-tool/Koha/Plugin/Fi/KohaSuomi/OverdueTool.pm" $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/OverdueTool.pm

DATABASE=`xmlstarlet sel -t -v 'yazgfs/config/database' $KOHA_CONF`
HOSTNAME=`xmlstarlet sel -t -v 'yazgfs/config/hostname' $KOHA_CONF`
PORT=`xmlstarlet sel -t -v 'yazgfs/config/port' $KOHA_CONF`
USER=`xmlstarlet sel -t -v 'yazgfs/config/user' $KOHA_CONF`
PASS=`xmlstarlet sel -t -v 'yazgfs/config/pass' $KOHA_CONF`

mysql --user=$USER --password="$PASS" --port=$PORT --host=$HOST $DATABASE << END
DELETE FROM plugin_data where plugin_class = 'Koha::Plugin::Fi::KohaSuomi::OverdueTool';
DELETE FROM plugin_methods where plugin_class = 'Koha::Plugin::Fi::KohaSuomi::OverdueTool';
DELETE FROM message_transport_types where message_transport_type = 'finvoice';
DELETE FROM message_transport_types where message_transport_type = 'pdf';
INSERT INTO message_transport_types (message_transport_type) VALUES ('finvoice');
INSERT INTO message_transport_types (message_transport_type) VALUES ('pdf');
INSERT INTO plugin_data (plugin_class,plugin_key,plugin_value) VALUES ('Koha::Plugin::Fi::KohaSuomi::OverdueTool','__INSTALLED__','1');
INSERT INTO plugin_data (plugin_class,plugin_key,plugin_value) VALUES ('Koha::Plugin::Fi::KohaSuomi::OverdueTool','__INSTALLED_VERSION__','${VERSION}');
INSERT INTO plugin_data (plugin_class,plugin_key,plugin_value) VALUES ('Koha::Plugin::Fi::KohaSuomi::OverdueTool','__ENABLED__','1');
INSERT INTO plugin_data (plugin_class,plugin_key,plugin_value) VALUES ('Koha::Plugin::Fi::KohaSuomi::OverdueTool','invoicenumber','1');
END

perl $kohadir/misc/devel/install_plugins.pl

