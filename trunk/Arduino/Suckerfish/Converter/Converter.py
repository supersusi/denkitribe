#!/usr/bin/python

# Converts MIDI clips exported from Ableton Live
# to Arduino mini-sequencer.

import os, struct

def ReadVLValue(file):
  'Reads a variable length value.'
  value = 0
  while True:
    byte = ord(file.read(1))
    value = (value << 7) + (byte & 0x7f)
    if (byte & 0x80) == 0: return value

class TrackEvent:
  'Track event data class.'
  def __init__(self, file):
    'Reads and stores a track event.'
    delta = ReadVLValue(file)
    assert(delta % 0x18 == 0)   # 0x18 = length of 16th note
    code = ord(file.read(1))
    assert(code != 0xf0)       # SysEx is not allowed!
    if code == 0xff:
      # Meta event
      assert(delta == 0)
      meta = ord(file.read(1))
      length = ReadVLValue(file)
      data = file.read(length)
      self.meta = (meta == 0x2f) and 'end' or 'n/a'
    else:
      # MIDI event
      self.meta = None
      self.delta = delta / 0x18
      self.status = code
      self.data1 = ord(file.read(1))
      self.data2 = ord(file.read(1))
  def MakeStruct(self):
    'Make a C structure entry of the event.'
    return '{0x%02x,0x%02x,0x%02x,0x%02x},' % \
           (self.delta, self.status, self.data1, self.data2)

def CheckHeader(file):
  'Reads the header chunk and checks the precondition.'
  assert(file.read(4) == 'MThd')
  (length, format, trackNum, delta) = struct.unpack('>ihhh', file.read(10))
  assert(length == 6 and format == 0 and trackNum == 1 and delta == 96)

def ReadTrackChunk(file):
  'Reads the track chunk and returns MIDI event array.'
  assert(file.read(4) == 'MTrk')
  (chunkLength,) = struct.unpack('>i', file.read(4))
  eventArray = []
  while True:
    event = TrackEvent(file)
    if event.meta == 'end': break
    if event.meta == None: eventArray.append(event)
  return eventArray

class CodeGenerator:
  def __init__(self):
    self.seqBuffer = ''
    self.seqCount = 0
  def AddSequence(self, eventArray):
    temp = 'const EventData sequence%02d[] = {\n' % self.seqCount
    for event in eventArray:
      temp += '  %s\n' % event.MakeStruct()
    self.seqBuffer += temp + '  {0xff}\n};\n'
    self.seqCount += 1
  def Generate(self):
    temp = 'struct EventData {\n'
    temp += '  unsigned char delta;\n'
    temp += '  unsigned char status;\n'
    temp += '  unsigned char data1;\n'
    temp += '  unsigned char data2;\n'
    temp += '};\n'
    temp += self.seqBuffer
    temp += 'const EventData* sequences[] = {\n'
    for i in range(self.seqCount): temp += '  sequence%02d,\n' % i
    return temp + '};\n'

generator = CodeGenerator()

for filename in os.listdir('.'):
  if filename[-4:] == '.mid':
    file = open(filename, 'rb')
    CheckHeader(file)
    generator.AddSequence(ReadTrackChunk(file))
    file.close()

open('Sequence.h', 'wb').write(generator.Generate())
