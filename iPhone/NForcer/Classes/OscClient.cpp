#include "OscClient.h"
#include "osc/OscOutboundPacketStream.h"
#include "ip/UdpSocket.h"
#include <cstdio>

namespace Jamadhar {

namespace {
    
char s_streamBuffer[1024];
UdpTransmitSocket* s_pTransmitSocket;
osc::OutboundPacketStream* s_pStream;
    
} // anonymous namespace

void OscClient::Initialize(const char* pAddress, int port) {
    s_pTransmitSocket = new UdpTransmitSocket(IpEndpointName(pAddress, port));
    s_pStream = new osc::OutboundPacketStream(s_streamBuffer, 1024);
}

void OscClient::Terminate() {
    delete s_pStream;
    delete s_pTransmitSocket;
    
    s_pStream = NULL;
    s_pTransmitSocket = NULL;
}

void OscClient::SendMessage(const char* pPath, float value) {
    if (!s_pStream) return;
    
    *s_pStream 
    << osc::BeginMessage(pPath) 
    << value << osc::EndMessage;
    s_pTransmitSocket->Send(s_pStream->Data(), s_pStream->Size());
    s_pStream->Clear();
}

} // namespace Jamadhar
