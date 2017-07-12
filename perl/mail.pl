my $to = "francois.lebot\@gmail.com";
my $subject = "test";
my $attach = "5.log";
my $message="coucou\nLe fichier est mal formaté";
my @mailt = `(echo "$message" ;uuencode $attach $attach) | mailx -s "$subject" $to`;

