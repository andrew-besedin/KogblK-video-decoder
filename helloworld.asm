format PE console
entry start

include 'win32wxp.inc'

COINIT_APARTMENTTHREADED = 2h
CLSCTX_INPROC_SERVER = 0x1

section '.text' code readable executable

proc start
	local objPtr: DWORD, objVtblPtr: DWORD, getValuePtr: DWORD, value: DWORD
	local releasePtr: DWORD, message_len: DWORD, stdout_handle: DWORD, bytes_written: DWORD

	invoke GetStdHandle, STD_OUTPUT_HANDLE
	mov [stdout_handle], eax

	; invoke DllRegisterServer

	
	
	invoke CoInitializeEx, NULL, COINIT_APARTMENTTHREADED

	lea eax, [objPtr]
	invoke CoCreateInstance, \
		CLSID_TinyComObject, \
		NULL, \
		CLSCTX_INPROC_SERVER, \
		IID_ITinyValue, \
		eax

	test eax, eax
	jnz .cleanup
	
	mov ebx, [objPtr]
	mov eax, [ebx]
	mov [objVtblPtr], eax
	
	mov ebx, [objVtblPtr]
	mov eax, [ebx + 3 * 4] ; getValue is the 4th method in the vtable
	mov [getValuePtr], eax
	
	mov ebx, [objVtblPtr]
	mov eax, [ebx + 2 * 4] ; release is the 3rd method in the vtable
	mov [releasePtr], eax

	lea eax, [value]
	mov ebx, [objPtr]
	invoke getValuePtr, ebx, eax

	cinvoke wsprintfW, message, format_str, [value]
	lea eax, [eax * 2 + 2]
	mov [message_len], eax

	mov eax, [objPtr]
	invoke releasePtr, eax


	invoke WriteFile, [stdout_handle], message, [message_len], [bytes_written], 0

	jmp .cleanup

.error:
	invoke MessageBoxA, NULL, 'An error occurred', 'Error', MB_OK or MB_ICONERROR

.cleanup:
	invoke CoUninitialize
	invoke ExitProcess, 0

	ret
endp

section '.data_r' data readable

CLSID_TinyComObject:
  dd 07A5F4E21h
  dw 08C1Bh
  dw 04AF1h
  db 09Ah,02Bh,011h,022h,033h,044h,055h,066h

IID_ITinyValue:
  dd 04E2A4A10h
  dw 071E4h
  dw 04E6Ah
  db 0BEh,04Ch,0AAh,0BBh,0CCh,0DDh,0EEh,001h

format_str du '%08X', 13, 10

section '.data_rw' data readable writeable

stdout_handle dd ?
bytes_written dd ?

message du 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 0
message_len dd 0

section '.idata' import data readable writeable

library kernel32, 'KERNEL32.DLL', \
	user32, 'USER32.DLL', \
	ole, 'OLE32.DLL'

include 'api/kernel32.inc'
include 'api/user32.inc'

import ole, \
	CoInitializeEx, 'CoInitializeEx', \
	CoCreateInstance, 'CoCreateInstance', \
	CoUninitialize, 'CoUninitialize'

section '.reloc' fixups data readable discardable
