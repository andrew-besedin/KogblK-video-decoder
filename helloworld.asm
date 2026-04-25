format PE console
entry start

include 'win32a.inc'

section '.text' code readable executable

start:
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov [stdout_handle], eax
	invoke WriteFile, [stdout_handle], message, message_len, bytes_written, 0
	invoke ExitProcess, 0

section '.data_r' data readable

message db 'Hello, World!', 13, 10
message_len = $ - message

section '.data_rw' data readable writeable

stdout_handle dd ?
bytes_written dd ?

section '.idata' import data readable writeable

library kernel32, 'KERNEL32.DLL'

import kernel32, \
	ExitProcess, 'ExitProcess', \
	GetStdHandle, 'GetStdHandle', \
	WriteFile, 'WriteFile'

section '.reloc' fixups data readable discardable
