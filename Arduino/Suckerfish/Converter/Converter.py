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
    'Read and store a track event.'
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
  def MakeTuple(self):
    'returns a tuple of data.'
    return (self.delta, self.status, self.data1, self.data2)
           

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
    self.data = []
    self.startPoints = []
  def AddSequence(self, eventArray):
    self.startPoints.append(len(self.data))
    for event in eventArray:
      self.data.append(event.MakeTuple())
    self.data.append((0xff, 0, 0, 0))
  def Generate(self):
    temp = 'PROGMEM prog_uint8_t sequenceData[] = {\n'
    for line in self.data:
      temp += '  0x%02x,0x%02x,0x%02x,0x%02x,\n' % line
    temp += '};\n'
    temp += 'const uint16_t startPoints[] = {\n  '
    for offs in self.startPoints:
      temp += '0x%04x,' % (offs * 4)
    return temp + '\n};\n'

generator = CodeGenerator()

for filename in os.listdir('.'):
  if filename[-4:] == '.mid':
    file = open(filename, 'rb')
    CheckHeader(file)
    generator.AddSequence(ReadTrackChunk(file))
    file.close()

outFilePath = '../Sequence.h'
if os.path.isfile(outFilePath): os.unlink(outFilePath)
open(outFilePath, 'wb').write(generator.Generate())
