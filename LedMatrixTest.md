LED マトリクスの制御実験

## ブレッドボード上での実験 ##
![http://farm3.static.flickr.com/2486/3833187592_a8a4b2b8fa_m.jpg](http://farm3.static.flickr.com/2486/3833187592_a8a4b2b8fa_m.jpg)

MAX7219 を利用した LED の制御の実験。一列分だけ接続して点灯させてみた。

## テスト用シールドの製作 ##
![http://farm3.static.flickr.com/2606/3834352802_5f0e2f14f8_m.jpg](http://farm3.static.flickr.com/2606/3834352802_5f0e2f14f8_m.jpg)
![http://farm3.static.flickr.com/2558/3834353106_af8deb49a3_m.jpg](http://farm3.static.flickr.com/2558/3834353106_af8deb49a3_m.jpg)

LED マトリクスは配線が複雑なため，ブレッドボード上での実験には無理があると考え，実験用のシールドを製作することにした。やはり配線がひどく面倒だった。

## 独立輝度調整テスト ##
MAX7219 は表示全体での輝度調整しかサポートしていないが，ダイナミック点灯を使えば画素毎の輝度調整も不可能ではない。

![http://farm4.static.flickr.com/3439/3837345726_566d1fd240_m.jpg](http://farm4.static.flickr.com/3439/3837345726_566d1fd240_m.jpg)

段階を増やせば増やすほど全体の輝度が落ち，フリッカーも激しくなる。４段階ぐらいが限界と思われる。

## 水面エフェクト ##
古典的な水面エフェクトを実装してみた。

<a href='http://www.youtube.com/watch?feature=player_embedded&v=husfySm5MdY' target='_blank'><img src='http://img.youtube.com/vi/husfySm5MdY/0.jpg' width='425' height=344 /></a>

次にピエゾ素子を導入し，本体を叩くことで水面に波が立つようにしてみた。

<a href='http://www.youtube.com/watch?feature=player_embedded&v=4bieluRJAqA' target='_blank'><img src='http://img.youtube.com/vi/4bieluRJAqA/0.jpg' width='425' height=344 /></a>

[ソースコード](http://code.google.com/p/denkitribe/source/browse/trunk/Arduino/LedPond/LedPond.pde)

## 独立輝度調整テスト・その２ ##
タイマー割り込みを導入したうえで割り込み間隔を微調整することで，段階を増やしつつフリッカーを軽減することが可能になった。

![http://farm3.static.flickr.com/2668/3851931134_4ec69a92ce_m.jpg](http://farm3.static.flickr.com/2668/3851931134_4ec69a92ce_m.jpg)

[ソースコード](http://code.google.com/p/denkitribe/source/browse/trunk/Arduino/LedMatrixTest/LedMatrixTest.pde)