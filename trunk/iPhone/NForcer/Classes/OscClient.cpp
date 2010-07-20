#include "OscClient.h"
#include "osc/OscOutboundPacketStream.h"
#include "ip/UdpSocket.h"
#include <cstdio>
#include <string>

namespace {
  std::string s_basePath;
  char s_streamBuffer[1024];
  UdpTransmitSocket* s_pTransmitSocket;
  osc::OutboundPacketStream* s_pStream;
}

void OscClient::SetBasePath(const char* pPath) {
  s_basePath = pPath ? pPath : "";
}

void OscClient::Open(const char* pAddress, int port) {
  if (s_pStream) return;
  s_pTransmitSocket = new UdpTransmitSocket(IpEndpointName(pAddress, port));
  s_pStream = new osc::OutboundPacketStream(s_streamBuffer, sizeof s_streamBuffer);
}

void OscClient::Close() {
  if (!s_pStream) return;
  delete s_pStream;
  delete s_pTransmitSocket;
  s_pStream = NULL;
  s_pTransmitSocket = NULL;
}

void OscClient::SendTouchMessage(int slot, float pitch, bool press) {
  if (!s_pStream) return;
  
  float note = press ? 1.0f : 0.0f;

  char pathNote[64], pathPitch[64];
  std::snprintf(pathNote, sizeof pathNote, "%s/touch/%d/note",
                s_basePath.c_str(), slot);
  std::snprintf(pathPitch, sizeof pathPitch, "%s/touch/%d/pitch",
                s_basePath.c_str(), slot);
  
  *s_pStream << osc::BeginBundleImmediate
             << osc::BeginMessage(pathPitch) << pitch << osc::EndMessage
             << osc::BeginMessage(pathNote) << note << osc::EndMessage
             << osc::EndBundle;
  s_pTransmitSocket->Send(s_pStream->Data(), s_pStream->Size());
  s_pStream->Clear();
}

void OscClient::SendAccelMessage(float x, float y, float z) {
  if (!s_pStream) return;
  
  std::string msgx = s_basePath + "/accel/x";
  std::string msgy = s_basePath + "/accel/y";
  std::string msgz = s_basePath + "/accel/z";
  
  *s_pStream << osc::BeginBundleImmediate
             << osc::BeginMessage(msgx.c_str()) << x << osc::EndMessage
             << osc::BeginMessage(msgy.c_str()) << y << osc::EndMessage
             << osc::BeginMessage(msgz.c_str()) << z << osc::EndMessage
             << osc::EndBundle;
  s_pTransmitSocket->Send(s_pStream->Data(), s_pStream->Size());
  s_pStream->Clear();
}
