#!/usr/bin/env perl

use v5.10;
use strict;
use warnings;

use File::Basename qw(basename dirname);
use Getopt::Long qw(:config posix_default no_ignore_case bundling auto_help);
use Pod::Usage qw(pod2usage);

use constant DEBUG => $ENV{DEBUG};

GetOptions(
    \my %opt,
    "port|p=i",
    "open|o",
    "theme|t=s",
    "print-pdf|p",
);

my $markdown_path = shift;
if ( !$markdown_path || !-f $markdown_path ) {
    pod2usage(1);
}
my $markdown_filename = basename($markdown_path);

my $theme = $opt{theme};
if ( !$theme && $opt{"print-pdf"} ) {
    $theme = "original";
}

my $port = $opt{port} || 5000;

my $uri_abs = $opt{"print-pdf"} ? "/?print-pdf#/" : "/";

chdir dirname($markdown_path);

my @revealup_arg = ("serve", "--port=$port");
push @revealup_arg, "--theme=$theme" if $theme;
for my $key (qw(transition widhth height)) {
    # これらのオプションは revealup にあるので、存在すればそのまま採用
    push @revealup_arg, "--$key=$opt{$key}" if $opt{$key};
}
push @revealup_arg, $markdown_filename;

my $pid = fork // die "fork error" or do {
    # in child
    print "fork child (pid=$$)\n";
    print "\$ revealup @revealup_arg\n";
    system "revealup", @revealup_arg;
    exit;
};

# child が revealup とそれによって起こされる plackup をし終わるまでの待ちの塩梅
sleep 1;

# Mac の open コマンドは非同期ですぐ抜ける
my $url = "http://localhost:$port$uri_abs";
print "open URL $url by default browser\n";
system "open", $url;

# child の system "revealup" が終了して child が exit するまで待つ
print "child (pid=$pid) is exist. wait\n" if kill 0 => $pid;
wait;

# 親を ^C (SIGINT) などで終了させれば child も刈り取られる

exit;

__END__

=pod

=head1 NAME

slideup.pl - Perl入学式のスライドサーバを起動する

=head1 SYNOPSIS

  $ perl slideup.pl [--port=5000] [--theme=original] [--open] [--print-pdf] path/to/slide.md

  普通に起動したい場合（デフォルトで開きます）
  $ perl slideup.pl --open path/to/slide.md

  PDF作成モードで開きたい場合
  $ perl slideup.pl --open --print-pdf path/to/slide.md

=head1 DESCRIPTIONS

C<revealup> の起動コマンドを忘れがちなこともあり、それのメモ的な位置付けのスクリプトです。

=head1 OPTIONS

=head2 --port=5000 | -p 5000

ポート番号指定です。デフォルトは revealup のもの。たぶん 5000 番です。

=head2 --open | -o

そのままブラウザで開きます。revealup をバックグラウンドで開き、このスクリプトはそれの終了を待ちます。

=head2 --theme | -t

テーマCSSを選択します。拡張子 css は除きます。--theme=someone と指定した場合、
引数で指定された Markdown ファイルと同じ場所に someone.css が存在すると仮定します。

=head2 --print-pdf | -p

PDF で印刷できるデザインにします。指定した Markdown ファイルと同じディレクトリに original.css が存在する必要があります。
original.css 以外の CSS を指定する場合には、上記 --theme オプションで上書きできます。

=head1 AUTHOR

OGATA Tetsuji E<lt>tetsuji.ogata@gmail.comE<lt>

=cut