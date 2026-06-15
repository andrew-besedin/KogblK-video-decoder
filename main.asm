format PE DLL
entry DllEntryPoint

include 'win32wxp.inc'

section '.text' code readable executable

proc DllEntryPoint hinstDLL, fdwReason, lpvReserved
  xor eax, eax
  ret
endp

section '.data' data readable writeable

section '.edata' export data readable

section '.idata' import data readable writeable

section '.reloc' fixups data readable discardable