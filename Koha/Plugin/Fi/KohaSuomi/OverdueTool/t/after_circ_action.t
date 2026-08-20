#!/usr/bin/perl

use Modern::Perl;
use FindBin qw($Bin);
use lib "$Bin/../../../../../..";

use Test::More;
use Test::MockModule;
use Test::MockObject;

use C4::Context;
use Koha::Database;
use t::lib::TestBuilder;

my $schema = Koha::Database->new->schema;
my $builder = t::lib::TestBuilder->new;

sub _build_plugin {
    my $plugin = bless {
        _plugin_data => { invoicenotforloan => 6 },
    }, 'Koha::Plugin::Fi::KohaSuomi::OverdueTool';

    my $mock = Test::MockModule->new('Koha::Plugin::Fi::KohaSuomi::OverdueTool');
    $mock->mock('retrieve_data', sub {
        my ($self, $key) = @_;
        return $self->{_plugin_data}->{$key} // '';
    });

    return $plugin;
}

sub _create_patron {
    return $builder->build_object({ class => 'Koha::Patrons' });
}

sub _create_item {
    my (%args) = @_;
    my $item = $builder->build_sample_item({
        homebranch => $args{homebranch},
    });
    if (defined $args{notforloan}) {
        C4::Context->dbh->do(
            "UPDATE items SET notforloan = ? WHERE itemnumber = ?",
            undef, $args{notforloan}, $item->itemnumber,
        );
    }
    return $item;
}

sub _create_debarment {
    my (%args) = @_;
    C4::Context->dbh->do(
        "INSERT INTO borrower_debarments (borrowernumber, type, comment, created, updated) VALUES (?, ?, ?, NOW(), NOW())",
        undef, $args{borrowernumber}, $args{type}, $args{comment},
    );
    return C4::Context->dbh->last_insert_id(undef, undef, 'borrower_debarments', undef);
}

sub _create_issue {
    my (%args) = @_;
    C4::Context->dbh->do(
        "INSERT INTO issues (borrowernumber, itemnumber, date_due, branchcode, issuedate) VALUES (?, ?, ?, ?, NOW())",
        undef, $args{borrowernumber}, $args{itemnumber}, $args{date_due}, $args{branchcode},
    );
    return C4::Context->dbh->last_insert_id(undef, undef, 'issues', undef);
}

subtest 'non-checkin action is ignored' => sub {
    plan tests => 1;

    my $plugin = _build_plugin();
    my $checkout = Test::MockObject->new;
    $checkout->mock('borrowernumber', sub { 1 });
    $checkout->mock('itemnumber', sub { 100 });

    my $result = $plugin->after_circ_action({
        action => 'checkout',
        payload => { checkout => $checkout },
    });

    ok(!$result, 'non-checkin action returns undef');
};

subtest 'non-invoiced item is ignored' => sub {
    plan tests => 1;

    $schema->storage->txn_begin;

    my $patron = _create_patron();
    my $item = _create_item(
        homebranch => $patron->branchcode,
        notforloan => 0,
    );

    my $plugin = _build_plugin();
    my $checkout = Test::MockObject->new;
    $checkout->mock('borrowernumber', sub { $patron->id });
    $checkout->mock('itemnumber', sub { $item->itemnumber });

    my $result = $plugin->after_circ_action({
        action => 'checkin',
        payload => { checkout => $checkout },
    });

    ok(!$result, 'non-invoiced item returns undef');

    $schema->storage->txn_rollback;
};

subtest 'invoiced item without debarment is ignored' => sub {
    plan tests => 1;

    $schema->storage->txn_begin;

    my $patron = _create_patron();
    my $item = _create_item(
        homebranch => $patron->branchcode,
        notforloan => 6,
    );

    my $plugin = _build_plugin();
    my $checkout = Test::MockObject->new;
    $checkout->mock('borrowernumber', sub { $patron->id });
    $checkout->mock('itemnumber', sub { $item->itemnumber });

    my $result = $plugin->after_circ_action({
        action => 'checkin',
        payload => { checkout => $checkout },
    });

    ok(!$result, 'no debarment returns undef');

    $schema->storage->txn_rollback;
};

subtest 'invoiced item with debarment but patron has overdue loans' => sub {
    plan tests => 1;

    $schema->storage->txn_begin;

    my $patron = _create_patron();
    my $item = _create_item(
        homebranch => $patron->branchcode,
        notforloan => 6,
    );
    my $overdue_item = _create_item(
        homebranch => $patron->branchcode,
        notforloan => 0,
    );
    _create_debarment(
        borrowernumber => $patron->id,
        type           => 'OVERDUES',
        comment        => 'Lainauskielto laskutetusta aineistosta',
    );
    _create_issue(
        borrowernumber => $patron->id,
        itemnumber     => $overdue_item->itemnumber,
        date_due       => '2020-01-01 00:00:00',
        branchcode     => $patron->branchcode,
    );

    my $plugin = _build_plugin();
    my $checkout = Test::MockObject->new;
    $checkout->mock('borrowernumber', sub { $patron->id });
    $checkout->mock('itemnumber', sub { $item->itemnumber });

    my $result = $plugin->after_circ_action({
        action => 'checkin',
        payload => { checkout => $checkout },
    });

    ok(!$result, 'overdue loans remain, debarment stays');

    $schema->storage->txn_rollback;
};

subtest 'invoiced item with debarment but patron has other invoiced loans' => sub {
    plan tests => 1;

    $schema->storage->txn_begin;

    my $patron = _create_patron();
    my $item = _create_item(
        homebranch => $patron->branchcode,
        notforloan => 6,
    );
    my $other_invoiced_item = _create_item(
        homebranch => $patron->branchcode,
        notforloan => 6,
    );
    _create_debarment(
        borrowernumber => $patron->id,
        type           => 'OVERDUES',
        comment        => 'Lainauskielto laskutetusta aineistosta',
    );
    _create_issue(
        borrowernumber => $patron->id,
        itemnumber     => $other_invoiced_item->itemnumber,
        date_due       => '2099-12-31 23:59:59',
        branchcode     => $patron->branchcode,
    );

    my $plugin = _build_plugin();
    my $checkout = Test::MockObject->new;
    $checkout->mock('borrowernumber', sub { $patron->id });
    $checkout->mock('itemnumber', sub { $item->itemnumber });

    my $result = $plugin->after_circ_action({
        action => 'checkin',
        payload => { checkout => $checkout },
    });

    ok(!$result, 'other invoiced loans remain, debarment stays');

    $schema->storage->txn_rollback;
};

subtest 'all invoiced items returned, no overdue loans - debarment removed' => sub {
    plan tests => 3;

    $schema->storage->txn_begin;

    my $patron = _create_patron();
    my $item = _create_item(
        homebranch => $patron->branchcode,
        notforloan => 6,
    );
    my $debarment_id = _create_debarment(
        borrowernumber => $patron->id,
        type           => 'OVERDUES',
        comment        => 'Lainauskielto laskutetusta aineistosta',
    );
    C4::Context->dbh->do(
        "UPDATE borrowers SET debarred = '2099-12-31', debarredcomment = 'test' WHERE borrowernumber = ?",
        undef, $patron->id,
    );

    my $plugin = _build_plugin();
    my $checkout = Test::MockObject->new;
    $checkout->mock('borrowernumber', sub { $patron->id });
    $checkout->mock('itemnumber', sub { $item->itemnumber });

    my $result = $plugin->after_circ_action({
        action => 'checkin',
        payload => { checkout => $checkout },
    });

    is($result, 1, 'returns 1 on successful debarment removal');

    my $dbh = C4::Context->dbh;
    my $sth = $dbh->prepare(
        "SELECT borrower_debarment_id FROM borrower_debarments WHERE borrower_debarment_id = ?"
    );
    $sth->execute($debarment_id);
    ok(!$sth->fetchrow_array(), 'DELETE FROM borrower_debarments was executed');

    $sth = $dbh->prepare(
        "SELECT debarred FROM borrowers WHERE borrowernumber = ? AND debarred IS NOT NULL"
    );
    $sth->execute($patron->id);
    ok(!$sth->fetchrow_array(), 'UPDATE borrowers SET debarred = NULL was executed');

    $schema->storage->txn_rollback;
};

subtest 'no remaining loans at all - debarment removed' => sub {
    plan tests => 2;

    $schema->storage->txn_begin;

    my $patron = _create_patron();
    my $item = _create_item(
        homebranch => $patron->branchcode,
        notforloan => 6,
    );
    my $debarment_id = _create_debarment(
        borrowernumber => $patron->id,
        type           => 'OVERDUES',
        comment        => 'Lainauskielto laskutetusta aineistosta',
    );

    my $plugin = _build_plugin();
    my $checkout = Test::MockObject->new;
    $checkout->mock('borrowernumber', sub { $patron->id });
    $checkout->mock('itemnumber', sub { $item->itemnumber });

    my $result = $plugin->after_circ_action({
        action => 'checkin',
        payload => { checkout => $checkout },
    });

    is($result, 1, 'returns 1 on successful debarment removal');

    my $sth = C4::Context->dbh->prepare(
        "SELECT borrower_debarment_id FROM borrower_debarments WHERE borrower_debarment_id = ?"
    );
    $sth->execute($debarment_id);
    ok(!$sth->fetchrow_array(), 'debarment deleted when patron has zero remaining loans');

    $schema->storage->txn_rollback;
};

subtest 'multiple matching debarments are all removed' => sub {
    plan tests => 2;

    $schema->storage->txn_begin;

    my $patron = _create_patron();
    my $item = _create_item(
        homebranch => $patron->branchcode,
        notforloan => 6,
    );
    _create_debarment(
        borrowernumber => $patron->id,
        type           => 'OVERDUES',
        comment        => 'Lainauskielto laskutetusta aineistosta',
    );
    _create_debarment(
        borrowernumber => $patron->id,
        type           => 'OVERDUES',
        comment        => 'Lainauskielto laskutetusta aineistosta',
    );

    my $plugin = _build_plugin();
    my $checkout = Test::MockObject->new;
    $checkout->mock('borrowernumber', sub { $patron->id });
    $checkout->mock('itemnumber', sub { $item->itemnumber });

    my $result = $plugin->after_circ_action({
        action => 'checkin',
        payload => { checkout => $checkout },
    });

    is($result, 1, 'returns 1 on successful debarment removal');

    my $sth = C4::Context->dbh->prepare(
        "SELECT COUNT(*) FROM borrower_debarments WHERE borrowernumber = ? AND type = 'OVERDUES' AND comment = 'Lainauskielto laskutetusta aineistosta'"
    );
    $sth->execute($patron->id);
    my ($count) = $sth->fetchrow_array();
    is($count, 0, 'all matching debarments removed, not just one');

    $schema->storage->txn_rollback;
};

subtest 'wrong comment on debarment is not removed' => sub {
    plan tests => 1;

    $schema->storage->txn_begin;

    my $patron = _create_patron();
    my $item = _create_item(
        homebranch => $patron->branchcode,
        notforloan => 6,
    );
    _create_debarment(
        borrowernumber => $patron->id,
        type           => 'OVERDUES',
        comment        => 'Wrong comment',
    );

    my $plugin = _build_plugin();
    my $checkout = Test::MockObject->new;
    $checkout->mock('borrowernumber', sub { $patron->id });
    $checkout->mock('itemnumber', sub { $item->itemnumber });

    my $result = $plugin->after_circ_action({
        action => 'checkin',
        payload => { checkout => $checkout },
    });

    ok(!$result, 'debarment with wrong comment is not matched');

    $schema->storage->txn_rollback;
};

subtest 'wrong notforloan status is not treated as invoiced' => sub {
    plan tests => 1;

    $schema->storage->txn_begin;

    my $patron = _create_patron();
    my $item = _create_item(
        homebranch => $patron->branchcode,
        notforloan => 3,
    );

    my $plugin = _build_plugin();
    my $checkout = Test::MockObject->new;
    $checkout->mock('borrowernumber', sub { $patron->id });
    $checkout->mock('itemnumber', sub { $item->itemnumber });

    my $result = $plugin->after_circ_action({
        action => 'checkin',
        payload => { checkout => $checkout },
    });

    ok(!$result, 'item with different notforloan status is ignored');

    $schema->storage->txn_rollback;
};

done_testing();
