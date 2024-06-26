#!/bin/bash

kohaplugindir="$(grep -Po '(?<=<pluginsdir>).*?(?=</pluginsdir>)' $KOHA_CONF)"
kohadir="$(grep -Po '(?<=<intranetdir>).*?(?=</intranetdir>)' $KOHA_CONF)"

rm -r $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/OverdueTool
rm $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/OverdueTool.pm

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ln -s "$SCRIPT_DIR/Koha/Plugin/Fi/KohaSuomi/OverdueTool" $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/OverdueTool
ln -s "$SCRIPT_DIR/Koha/Plugin/Fi/KohaSuomi/OverdueTool.pm" $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/OverdueTool.pm

rm $kohadir/misc/cronjobs/run_finvoice.pl
ln -s $kohaplugindir/Koha/Plugin/Fi/KohaSuomi/OverdueTool/cronjobs/run_finvoice.pl $kohadir/misc/cronjobs/run_finvoice.pl

perl $kohadir/misc/devel/install_plugins.pl

