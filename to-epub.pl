#!/usr/bin/ev perl
use v5.14;
use strict;
use utf8;
use encoding 'utf8';
use EBook::EPUB;
use File::Slurp qw(read_file);
use Mojo::DOM;
use Encode qw(decode_utf8);
use Unicode::Properties qw(uniprops);
use Unicode::Collate;
use Unicode::Collate::CJK::Stroke;
use DBI;
use JSON;
use Mojo::Template;
use List::MoreUtils qw(uniq);
use File::Temp;

sub mt { state $mt = Mojo::Template->new }

sub sort_by_cjk_strokes {
    state $sorter = Unicode::Collate->new(overrideCJK => \&Unicode::Collate::CJK::Stroke::weightStroke);
    return $sorter->sort(@_);
}

sub load_whole_dict {
    state $dict = JSON::decode_json(read_file("dict-revised-unicode.json"));
    state $chars_with_radical = do {
        my $x = {};
        for my $char (@$dict) {
            next if $char->{title} =~ m!{\[.+\]}!;
            push @{ $x->{$char->{radical}} ||=[]}, $char;
        }
        $x;
    };
    return ($dict, $chars_with_radical);
}

sub radicals {
    state @radicals;
    return @radicals if @radicals;

    @radicals = qw<一 丿 乙 二 亠 人 亻 儿 入 八 冂 冖 冫 几 凵 刀 力 勹 匕 匚 匸 十 卜 卩 厂 又 口 囗 土 士 夕 大 女 子 宀 寸 小 尢 尸 屮 山 巛 工 己 巾 干 幺 廾 弋 弓 彐 彳 心 戈 戶 手 支 攴 攵 文 斗 斤 方 无 日 曰 月 木 欠 止 歹 殳 毋 比 毛 氏 气 水 火 爪 父 爻 爿 片 牙 牛 犬 王 玄 玉 瓜 瓦 甘 生 用 田 疋 疒 癶 白 皮 皿 目 矛 矢 石 示 禸 禾 穴 立 竹 米 糸 缶 网 羊 羽 老 而 耒 耳 聿 肉 臣 自 至 臼 舌 舛 舟 艮 色 艸 虍 虫 血 行 衣 襾 西 系 見 角 言 谷 豆 豕 豸 貝 赤 走 足 身 車 辛 辰 辵 邑 酉 釆 里 金 長 門 阜 隶 隹 雨 青 非 貟 面 革 韋 韭 音 頁 風 飛 食 首 香 馬 骨 高 髟 鬥 鬯 鬲 鬼 魚 鳥 鹵 鹿 麥 麻 黃 黍 黑 黹 黽 鼎 鼓 鼠 鼻 齊 齒 龍 龜 龠 ⼁ ⼂ ⼅ ⼛ ⼡ ⼢ ⼴ ⼵ ⼺>;

    # my ($dict, undef) = load_whole_dict();
    # @radicals = uniq grep { $_ } map { $_->{radical} } @$dict;
    # @radicals = sort_by_cjk_strokes @radicals;

    return @radicals;
}

sub chars_with_radical {
    my $radical = shift;
    my ($dict, $chars_with_radical) = load_whole_dict();
    return $chars_with_radical->{$radical};
}

sub build_chapter {
    my ($radical, $characters) = @_;
    my $title = "$radical 部";
    my $content = "";

    for my $c (@$characters) {
        my $h = $c->{heteronyms};
        $content .= mt->render_file("views/character.html.ep", $c, $h);
    }

    $content = mt->render_file("views/chapter.html.ep", $title, $content);

    return {
        title => $title,
        content => $content
    }
}

sub build_epub {
    my @chapters;

    for my $radical (sort_by_cjk_strokes radicals) {
        push @chapters, build_chapter $radical => chars_with_radical $radical;
    }

    my $epub = EBook::EPUB->new;
    $epub->add_title('萌典');
    $epub->add_author('3du.tw');
    $epub->add_meta_item('cover', $epub->copy_image('img/icon.png', 'icon.png'));
    $epub->copy_stylesheet('stylesheets/main.css', 'css/main.css');

    for my $ch (@chapters) {
        my $fn_in_epub = join("_" => map { ord($_) } split("",$ch->{title})) . ".html";
        my $id = $epub->add_xhtml($fn_in_epub, $ch->{content}, linear => "yes");
        my $np = $epub->add_navpoint(
            label   => $ch->{title},
            id      => $id,
            content => $fn_in_epub
        );
    }

    $epub->pack_zip("moedict.epub");
    say "DONE: moedict.epub";
}

build_epub();
