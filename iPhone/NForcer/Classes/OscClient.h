#ifndef INCLUDE_OSCCLIENT_H
#define INCLUDE_OSCCLIENT_H

class OscClient {
public:
  static void SetBasePath(const char* pPath);
  static void Open(const char* pAddress, int port);
  static void Close();
  static void SendTouchMessage(int slot, float pitch, bool press);
  static void SendAccelMessage(float x, float y, float z);
};

#endif
