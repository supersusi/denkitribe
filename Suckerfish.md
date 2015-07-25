Suckerfish の解説ページ

# 概要 #

Arduino を使用したミニマムな仕様の MIDI シーケンサーです。

![http://farm4.static.flickr.com/3567/3765703439_8c36754725.jpg](http://farm4.static.flickr.com/3567/3765703439_8c36754725.jpg)
![http://farm3.static.flickr.com/2575/3766571472_8dd1cf02c0.jpg](http://farm3.static.flickr.com/2575/3766571472_8dd1cf02c0.jpg)

[演奏デモビデオ](http://vimeo.com/5812001)

# 機能 #

Suckerfish は，いわゆる「パターンシーケンサー」とでも言うべきもので，内蔵している１６個のパターンを選択して再生することができます。パターンの切り替えはトグルスイッチによって行います。４つのトグルスイッチをつかって２進数的にパターン番号を指定するわけです。ちなみに，個人的な好みから左側が LSB になっています。

ボタンで再生開始，もう一回押すと再生終了。再生開始時に MIDI システムリアルタイムメッセージのスタート (0xFA) が送信され，再生停止時にストップ (0xFC) が送信されます。パターンの切り替えはパターンが一周したタイミングで適用されます。

パターンの再生速度 (BPM) に合わせてタイミングクロック (0xF8) を送信します。 BPM はあまり正確ではありません。従って，このデバイスを使用する場合は，このデバイスを同期のマスターにする必要があります。

# パターンの作成 #

パターンデータはソースコード内に埋め込まれる形になっています。 [Sequence.h](http://code.google.com/p/denkitribe/source/browse/trunk/Arduino/Suckerfish/Sequence.h) がそれです。このファイルは [Converter](http://code.google.com/p/denkitribe/source/browse/trunk/Arduino/Suckerfish/Converter) ディレクトリ内にある [Converter.py](http://code.google.com/p/denkitribe/source/browse/trunk/Arduino/Suckerfish/Converter/Converter.py) （Python スクリプト）によって自動生成されます。

Converter.py は，カレントディレクトリ内にある拡張子 .mid のファイルをスキャンし，変換・結合したうえで Sequence.h に出力するスクリプトです。中身はかなり手抜きの実装になっており，基本的に Ableton Live によって出力された .mid ファイルにしか対応していません。

Ableton Live から .mid ファイルの出力を行うには，クリップを選択したのちに右クリックメニューから "Export MIDI Clip" を選択します。

![http://farm3.static.flickr.com/2541/3797040920_d344001154_o.jpg](http://farm3.static.flickr.com/2541/3797040920_d344001154_o.jpg)

BPM の指定はソースコード中で行います。[Suckerfish.pde](http://code.google.com/p/denkitribe/source/browse/trunk/Arduino/Suckerfish/Suckerfish.pde) の先頭にある定数 `kBpm` がそれです。

# 部品リスト #

|品名|型番|数量|代表的な入手先|備考|
|:-|:-|:-|:------|:-|
|[Arduino Pro Mini (5V)](http://arduino.cc/en/Main/ArduinoBoardProMini)|[Sparkfun DEV-09218](http://www.sparkfun.com/commerce/product_info.php?products_id=9218)|1 |[スイッチサイエンス](http://www.switch-science.com/products/detail.php?product_id=170)|ATmega168 版でも OK ですが，3.3V 版は不可です。|
|ユニバーサル基板|DAISEN PU37x52|1 |千石電商，[共立エレショップ](http://eleshop.jp/shop/g/g7B7319/)|部品が収まれば何でもいいです。千石電商の店頭が入手しやすいです。|
|基板用トグルスイッチ|[Linkman 2A11N4B4U2SE](http://www.linkman.jp/user/shohin.php?p=57697)|4 |[マルツ](https://www.marutsu.co.jp/user/shohin.php?p=40286)，[秋月](http://akizukidenshi.com/catalog/g/gP-00300/)|- |
|照光スイッチ|[Linkman PB61303BL4102](http://www.linkman.jp/user/shohin.php?p=57348)|1 |[マルツ](https://www.marutsu.co.jp/user/shohin.php?p=10773)|モーメンタリーです。同じ見た目でオルタネイトの製品もありますので，間違えないように。|
|抵抗 150ohm|- |1 |-      |- |
|抵抗 220ohm|- |1 |-      |- |
|２ピンヘッダー|- |1 |[千石電商](http://www.sengoku.co.jp/mod/sgk_cart/search.php?toku=&cond8=and&dai=&chu=&syo=&cond9=&k3=0&list=2&pflg=n&multi=&code=7ANE-P8MG)|「ファン用コネクター」「ＥＩコネクター」「ナイロンコネクター」等の名前で売られています。|
|３ピンヘッダー|- |1 |[千石電商](http://www.sengoku.co.jp/mod/sgk_cart/search.php?toku=&cond8=and&dai=&chu=&syo=&cond9=&k3=0&list=2&pflg=n&multi=&code=3AZL-DBKC)|- |
|スペーサー|- |4 |[マルツ](https://www.marutsu.co.jp/user/shohin.php?p=34709), 千石電商|径サイズが M3 のものであれば何でもいいです。千石電商の店頭が入手しやすいです。|
|ネジ (M3)|- |4 |[マルツ](https://www.marutsu.co.jp/user/shohin.php?p=18770), 千石電商|見た目的にポリビスがおすすめです。千石電商の店頭が入手しやすいです。|

# 回路図・配線図 #

![http://farm4.static.flickr.com/3557/3794990037_ee602edbc8.jpg](http://farm4.static.flickr.com/3557/3794990037_ee602edbc8.jpg)

配線は以下のようになります（基板の裏側から見た図です）。

![http://farm3.static.flickr.com/2469/3794989977_b9261deeb4.jpg](http://farm3.static.flickr.com/2469/3794989977_b9261deeb4.jpg)

完成品の写真です。

![http://farm3.static.flickr.com/2589/3795822340_52f81da66b.jpg](http://farm3.static.flickr.com/2589/3795822340_52f81da66b.jpg)

上から見るとこうなっています。

![http://farm3.static.flickr.com/2663/3795001487_a8f2ae112e.jpg](http://farm3.static.flickr.com/2663/3795001487_a8f2ae112e.jpg)

# プログラム #

ソースリポジトリの `svntrunk/Arduino/Suckerfish/Suckerfish.pde` 以下にあります。ウェブインターフェースからちょっと覗いてみるには[こちら](http://code.google.com/p/denkitribe/source/browse/#svn/trunk/Arduino/Suckerfish)をどうぞ。

ビルドには [Timer1](http://www.arduino.cc/playground/Code/Timer1) ライブラリが必要になります。