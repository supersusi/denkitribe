ブレッドボードシーケンサーのサポートページ

## ソースコード ##
下記のリンクから入手してください。

http://code.google.com/p/denkitribe/source/browse/trunk/Arduino/BBSeq/BBSeq.pde

コンパイルには Timer1 ライブラリが必要です。下記のリンクから入手しインストールしておいてください。

http://www.arduino.cc/playground/Code/Timer1

## コンフィギュレーション ##
  * MIDI チャンネルは定数 `kChannel` によって設定されたチャンネルを使用します。
  * テンポは定数 `kBpm` によって変更可能です。

## 簡単な改造 ##
  * 配列 `pitchArray` の中身を書き換えれば，ペンタトニック以外のスケールを使うことができます。
  * ベロシティは定数 `kVelocity` に設定された値を常に使うようになっていますが，ちょっと改造すれば，発音毎にベロシティを変化させることも可能です。
  * 長いブレッドボードを使えば広い音域を扱うことが可能になります。その際，列の数を定数 `kNumPitch` に設定してください。

## 演奏例 ##
<a href='http://www.youtube.com/watch?feature=player_embedded&v=PyQkUt-lY1g' target='_blank'><img src='http://img.youtube.com/vi/PyQkUt-lY1g/0.jpg' width='425' height=344 /></a>