format PE console
entry start

include 'win32wxp.inc'

section '.text' code readable executable

start:
	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov [stdout_handle], eax

	invoke DllRegisterServer
	invoke wsprintfW, message, format_str, eax
	lea eax, [eax * 2 + 2]
	mov [message_len], eax

	invoke WriteFile, [stdout_handle], message, [message_len], bytes_written, 0
	invoke ExitProcess, 0

section '.data_r' data readable

format_str du '%08X', 13, 10

section '.data_rw' data readable writeable

stdout_handle dd ?
bytes_written dd ?

message du 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 0
message_len dd 0

section '.idata' import data readable writeable

library kernel32, 'KERNEL32.DLL', \
	user32, 'USER32.DLL', \
	testcomdll, './test_com_dll.dll'

include 'api/kernel32.inc'
include 'api/user32.inc'

import testcomdll, \
	DllRegisterServer, 'DllRegisterServer', \
	DllUnregisterServer, 'DllUnregisterServer' 

section '.reloc' fixups data readable discardable
