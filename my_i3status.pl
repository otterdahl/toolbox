#!/usr/bin/perl
# Prepend i3status with offlineimap sync status

# This script is a simple wrapper which prefixes each i3status line with custom
# information. To use it, ensure your ~/.i3status.conf contains this line:
#     output_format = "i3bar"
# in the 'general' section.
# Then, in your ~/.i3/config, use:
#     status_command i3status | ~/i3status/contrib/wrapper.pl
# In the 'bar' section.

use strict;
use warnings;
# You can install the JSON module with 'cpan JSON' or by using your
# distribution’s package management system, for example apt-get install
# libjson-perl on Debian/Ubuntu.
use JSON;

# Don’t buffer any output.
$| = 1;

# Skip the first line which contains the version header.
print scalar <STDIN>;

# The second line contains the start of the infinite array.
print scalar <STDIN>;

# Read lines forever, ignore a comma at the beginning if it exists.
while (my ($statusline) = (<STDIN> =~ /^,?(.*)/)) {
    # Decode the JSON-encoded line.
    my @blocks = @{decode_json($statusline)};
    #my @blocks;

    # Prefix our own information (you could also suffix or insert in the
    # middle).
    my $status;
    my $color;
    open(IH, '<', "/home/i0davla/config/email_sync_enabled") or die $!;
    while(<IH>) {
        if($_ =~ /^1$/) {
            $status = "offlineimap: yes";
            $color = "#00FF00" # green
        } elsif($_ = /^2$/) {
            $status = "offlineimap: syncing";
            $color = "#FFFF00"
        } else {
            $status = "offlineimap: no";
            $color = "#FF0000" # red
        }
    }
    close(IH);
    @blocks = ({
        full_text => $status,
        name => 'offlineimap',
        color => $color
    }, @blocks);

    # Output the line as JSON.
    print encode_json(\@blocks) . ",\n";
}
