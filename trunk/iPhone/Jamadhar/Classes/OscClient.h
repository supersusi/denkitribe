#ifndef INCLUDE_OSCCLIENT_H
#define INCLUDE_OSCCLIENT_H

namespace Jamadhar {

class OscClient {
public:
    static void Initialize(const char* pAddress, int port);
    static void Terminate();
    static void SendBang();
};

} // namespace Jamadhar

#endif
