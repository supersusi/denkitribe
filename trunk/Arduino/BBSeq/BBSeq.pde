#include <TimerOne.h>

const int kNumPitch = 16;   // ピッチの数
const int kBpm = 80;        // テンポ
const int kChannel = 0;     // MIDI チャンネル
const int kVelocity = 100;  // ベロシティ値

// ピッチ配列（ペンタトニックスケール）
int pitchArray[kNumPitch + 1] = {
  -1, // 休符
  48, 50, 52, 55, 57,
  60, 62, 64, 67, 69,
  72, 74, 76, 79, 81,
  84
};

// 音を取得し，送信する。
void sendNote() {
  static int currentStep;    // 現在のステップ位置
  static int prevNote = -1;  // 一つ前の音
  // マルチプレクサの設定（入力線を選ぶ）
  int select = 0xf - currentStep;
  digitalWrite(2, (select & 1) ? HIGH : LOW);
  digitalWrite(3, (select & 2) ? HIGH : LOW);
  digitalWrite(4, (select & 4) ? HIGH : LOW);
  digitalWrite(5, (select & 8) ? HIGH : LOW);
  delayMicroseconds(50);
  // ノートオフの送信
  if (prevNote >= 0) {
    Serial.write(0x80 + kChannel);
    Serial.write(prevNote);
    Serial.write(kVelocity);
  }
  // 音の取得
  int note = pitchArray[(analogRead(0) * kNumPitch + 512) / 1024];
  if (note >= 0) {
    // ノートオンの送信
    Serial.write(0x90 + kChannel);
    Serial.write(note);
    Serial.write(kVelocity);
  }
  // 次のステップへ進む
  currentStep = (currentStep + 1) & 0xf;
  prevNote = note;
}

// タイマーイベントハンドラー
void tick() {
  static int tickCount = -1;
  // 最初のチックは無視する。
  if (tickCount == -1) {
    tickCount = 0;
  } else {
    // タイミングクロックの送信
    Serial.write(0xf8);
    // ６回毎に１音処理（１６分音符）
    if (++tickCount == 6) {
      sendNote();
      tickCount = 0;
      digitalWrite(13, HIGH);  // 内蔵 LED 点灯
    } else {
      digitalWrite(13, LOW);   // 内蔵 LED 消灯
    }
  }
}

void setup() {
  // I/O ピンの初期化
  pinMode(2, OUTPUT);
  pinMode(3, OUTPUT);
  pinMode(4, OUTPUT);
  pinMode(5, OUTPUT);
  pinMode(13, OUTPUT);
  // シリアル通信の初期化 (31.250 kbps).
  Serial.begin(31250);
  // 「オールノートオフ」メッセージ
  Serial.write(0xb0 + kChannel);
  Serial.write(0x7b);
  Serial.write(byte(0));
  // 「スタート」メッセージ
  Serial.write(0xfa);
  // 最初のタイミングクロック
  Serial.write(0xf8);
  // タイマー割り込みの初期化
  Timer1.initialize(60L * 1000 * 1000 / (kBpm * 24));
  Timer1.attachInterrupt(tick);
}

void loop() {
}
