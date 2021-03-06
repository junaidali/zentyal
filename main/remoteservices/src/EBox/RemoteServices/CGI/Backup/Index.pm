# Copyright (C) 2008-2013 Zentyal S.L.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

use strict;
use warnings;

package EBox::RemoteServices::CGI::Backup::Index;

use base qw(EBox::CGI::ClientBase);

use Error qw(:try);

use EBox::RemoteServices::Backup;
use EBox::Gettext;
use EBox::Global;
use EBox::Exceptions::Internal;
use EBox::Exceptions::External;

# Group: Public methods

sub new # (error=?, msg=?, cgi=?)
{
    my $class = shift;
    my $self = $class->SUPER::new('title' => __('Import/Export Configuration Remotely'),
                                  'template' => '/backupTabs.mas',
                                  @_);

    $self->setMenuNamespace('EBox/Backup');

    bless($self, $class);
    return $self;
}

sub optionalParameters
{
    my ($self) = @_;

    return ['selected'];
}

sub actuate
{
    my ($self) = @_;

    my $subscriptionLevel = $self->_subscriptionLevel();
    if ($subscriptionLevel <  0) {
        return;
    }

    try {
        my $backup = $self->_backupService();
        $self->{backups} =  $backup->listRemoteBackups();
    } otherwise {
        my $ex = shift;
        $self->setErrorFromException($ex);
        $self->setChain('RemoteServices/NoConnection');
    };
}

sub masonParameters
{
    my ($self) = @_;
    my @params = ();

    my $backups = {};
    if (defined($self->{backups})) {
        $backups = $self->{backups};
    }

    push @params, (backups => $backups);

    my $global = EBox::Global->getInstance();
    my $modulesChanged = grep { $global->modIsChanged($_) } @{ $global->modNames() };
    push @params, (modulesChanged => $modulesChanged);
    push @params, (selected => 'remote');

    my $subscriptionLevel = $self->_subscriptionLevel();
    my $subscribed =  ($subscriptionLevel >= 0);
    my $basic      =  ($subscriptionLevel == 0);

    push @params, (subscribed => $subscribed);
    push @params, (basic => $basic);

    return \@params;
}

# Group: Private methods

sub _backupService
{
    my ($self) = @_;
    if (not exists $self->{backupService}) {
        $self->{backupService} =  new EBox::RemoteServices::Backup();
    }

    return $self->{backupService}
}

# Check if this Zentyal is subscribed
sub _subscriptionLevel
{
    my ($self) = @_;

    my $rsMod = EBox::Global->modInstance('remoteservices');
    return $rsMod->subscriptionLevel();
}

1;
