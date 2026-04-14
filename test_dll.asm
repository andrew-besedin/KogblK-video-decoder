format PE DLL
entry DllEntryPoint

include 'win32a.inc'

section '.text' code readable executable

DllEntryPoint:
  mov eax, 1
  ret

SampleFunction:
  mov eax, 123
  ret

GetSampleValueAddress:
  mov eax, sample_value
  ret

section '.data' data readable writeable

sample_value dd 123

section '.edata' export data readable

export 'test_dll.dll', \
  SampleFunction, 'SampleFunction', \
  GetSampleValueAddress, 'GetSampleValueAddress'

section '.reloc' fixups data readable discardable
