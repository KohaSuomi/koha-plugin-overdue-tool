package Koha::Plugin::Fi::KohaSuomi::OverdueTool::Controllers::ItemController;

# This file is part of Koha.
#
# Koha is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3 of the License, or (at your option) any later
# version.
#
# Koha is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE.  See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Koha; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

use Modern::Perl;

use Mojo::Base 'Mojolicious::Controller';
use Try::Tiny;

=head1 API

=cut

sub patch {
    my $c = shift->openapi->valid_input or return;

    my $item;
    return try {
        my $itemnumber = $c->validation->param('itemnumber');
        $item = Koha::Items->find($itemnumber);
        my $body = $c->req->json;

        $item->set($body);
        $item->store;
        return $c->render( status => 200, openapi => $item);
    }
    catch {
        unless ($item) {
            return $c->render( status  => 404,
                               openapi => { error => "Item not found" } );
        }
    };
}

1;