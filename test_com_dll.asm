format PE GUI 4.0 DLL
entry DllEntryPoint

include 'win32a.inc'

S_OK = 0
S_FALSE = 1
E_NOTIMPL = 80004001h
E_NOINTERFACE = 80004002h
E_POINTER = 80004003h
E_OUTOFMEMORY = 8007000Eh
CLASS_E_NOAGGREGATION = 80040110h
CLASS_E_CLASSNOTAVAILABLE = 80040111h

MINIMAL_OBJECT_VTBL = 0
MINIMAL_OBJECT_REFCOUNT = 4
MINIMAL_OBJECT_SIZE = 8

section '.text' code readable executable

proc DllEntryPoint hinstDLL, fdwReason, lpvReserved
  mov eax, [hinstDLL]
  mov [g_hInstance], eax
  mov eax, 1
  ret
endp

proc DllCanUnloadNow
  mov eax, [g_objectCount]
  or eax, [g_lockCount]
  jnz .busy
  xor eax, eax
  ret
.busy:
  mov eax, S_FALSE
  ret
endp

proc DllGetClassObject rclsid, riid, ppv
  mov eax, [ppv]
  test eax, eax
  jz .pointer_error
  mov dword [eax], 0

  push CLSID_TinyComObject
  push dword [rclsid]
  call IsEqualGUID
  test eax, eax
  jz .bad_class

  push IID_IClassFactory
  push dword [riid]
  call IsEqualGUID
  test eax, eax
  jnz .return_factory

  push IID_IUnknown
  push dword [riid]
  call IsEqualGUID
  test eax, eax
  jz .no_interface

.return_factory:
  mov eax, [ppv]
  mov dword [eax], ClassFactory_Instance
  mov eax, S_OK
  jmp .done

.pointer_error:
  mov eax, E_POINTER
  jmp .done

.bad_class:
  mov eax, CLASS_E_CLASSNOTAVAILABLE
  jmp .done

.no_interface:
  mov eax, E_NOINTERFACE

.done:
  ret
endp

proc DllRegisterServer

  local hKeyClsid:DWORD, hKeyInproc:DWORD, dwDisposition:DWORD
  local dwPathLen:DWORD, result:DWORD
  local szPath[260]:BYTE

  mov dword [hKeyClsid], 0
  mov dword [hKeyInproc], 0

  lea eax, [szPath]
  push eax
  push [g_hInstance]
  call [GetModuleFileNameA]
  test eax, eax
  jz .error
  inc eax
  mov [dwPathLen], eax

  lea eax, [dwDisposition]
  push eax
  lea eax, [hKeyClsid]
  push eax
  push 0
  push KEY_WRITE
  push REG_OPTION_NON_VOLATILE
  push 0
  push 0
  push sz_clsid_key
  push HKEY_CLASSES_ROOT
  call [RegCreateKeyExA]
  test eax, eax
  jnz .error

  push 14
  push sz_friendly_name
  push REG_SZ
  push 0
  push 0
  push dword [hKeyClsid]
  call [RegSetValueExA]

  lea eax, [dwDisposition]
  push eax
  lea eax, [hKeyInproc]
  push eax
  push 0
  push KEY_WRITE
  push REG_OPTION_NON_VOLATILE
  push 0
  push 0
  push sz_inproc_subkey
  push dword [hKeyClsid]
  call [RegCreateKeyExA]
  test eax, eax
  jnz .error

  push dword [dwPathLen]
  lea eax, [szPath]
  push eax
  push REG_SZ
  push 0
  push 0
  push dword [hKeyInproc]
  call [RegSetValueExA]

  push 10
  push sz_apartment
  push REG_SZ
  push 0
  push sz_threading_model
  push dword [hKeyInproc]
  call [RegSetValueExA]

  xor eax, eax
  mov [result], eax
  jmp .cleanup

.error:
  mov dword [result], 80004005h

.cleanup:
  cmp dword [hKeyInproc], 0
  je .skip_inproc_close
  push dword [hKeyInproc]
  call [RegCloseKey]
.skip_inproc_close:
  cmp dword [hKeyClsid], 0
  je .skip_clsid_close
  push dword [hKeyClsid]
  call [RegCloseKey]
.skip_clsid_close:
  mov eax, [result]
  ret
endp

proc DllUnregisterServer
  push sz_inproc_full_key
  push HKEY_CLASSES_ROOT
  call [RegDeleteKeyA]

  push sz_clsid_key
  push HKEY_CLASSES_ROOT
  call [RegDeleteKeyA]

  xor eax, eax
  ret
endp

IsEqualGUID:
  mov edx, [esp+4]
  mov ecx, [esp+8]

  mov eax, [edx]
  cmp eax, [ecx]
  jne .not_equal

  mov eax, [edx+4]
  cmp eax, [ecx+4]
  jne .not_equal

  mov eax, [edx+8]
  cmp eax, [ecx+8]
  jne .not_equal

  mov eax, [edx+12]
  cmp eax, [ecx+12]
  jne .not_equal

  mov eax, 1
  ret 8

.not_equal:
  xor eax, eax
  ret 8

ClassFactory_QueryInterface:
  push ebp
  mov ebp, esp

  mov eax, [ebp+16]
  test eax, eax
  jz .pointer_error
  mov dword [eax], 0

  push IID_IClassFactory
  push dword [ebp+12]
  call IsEqualGUID
  test eax, eax
  jnz .return_self

  push IID_IUnknown
  push dword [ebp+12]
  call IsEqualGUID
  test eax, eax
  jz .no_interface

.return_self:
  mov eax, [ebp+16]
  mov edx, [ebp+8]
  mov [eax], edx
  push dword [ebp+8]
  call ClassFactory_AddRef
  mov eax, S_OK
  jmp .done

.pointer_error:
  mov eax, E_POINTER
  jmp .done

.no_interface:
  mov eax, E_NOINTERFACE

.done:
  mov esp, ebp
  pop ebp
  ret 12

ClassFactory_AddRef:
  mov eax, 2
  ret 4

ClassFactory_Release:
  mov eax, 1
  ret 4

ClassFactory_CreateInstance:
  push ebp
  mov ebp, esp
  sub esp, 4

  mov eax, [ebp+20]
  test eax, eax
  jz .pointer_error
  mov dword [eax], 0

  cmp dword [ebp+12], 0
  jne .no_aggregation

  call [GetProcessHeap]
  push MINIMAL_OBJECT_SIZE
  push HEAP_ZERO_MEMORY
  push eax
  call [HeapAlloc]
  test eax, eax
  jz .out_of_memory

  mov [ebp-4], eax
  mov dword [eax+MINIMAL_OBJECT_VTBL], MinimalObject_Vtbl
  mov dword [eax+MINIMAL_OBJECT_REFCOUNT], 1
  inc dword [g_objectCount]

  push dword [ebp+20]
  push dword [ebp+16]
  push dword [ebp-4]
  call MinimalObject_QueryInterface
  push eax
  push dword [ebp-4]
  call MinimalObject_Release
  pop eax
  jmp .done

.pointer_error:
  mov eax, E_POINTER
  jmp .done

.no_aggregation:
  mov eax, CLASS_E_NOAGGREGATION
  jmp .done

.out_of_memory:
  mov eax, E_OUTOFMEMORY

.done:
  mov esp, ebp
  pop ebp
  ret 16

ClassFactory_LockServer:
  push ebp
  mov ebp, esp

  cmp dword [ebp+12], 0
  je .unlock
  inc dword [g_lockCount]
  jmp .success

.unlock:
  cmp dword [g_lockCount], 0
  je .success
  dec dword [g_lockCount]

.success:
  xor eax, eax
  mov esp, ebp
  pop ebp
  ret 8

MinimalObject_QueryInterface:
  push ebp
  mov ebp, esp

  mov eax, [ebp+16]
  test eax, eax
  jz .pointer_error
  mov dword [eax], 0

  push IID_ITinyValue
  push dword [ebp+12]
  call IsEqualGUID
  test eax, eax
  jnz .return_self

  push IID_IUnknown
  push dword [ebp+12]
  call IsEqualGUID
  test eax, eax
  jz .no_interface

.return_self:
  mov eax, [ebp+16]
  mov edx, [ebp+8]
  mov [eax], edx
  push dword [ebp+8]
  call MinimalObject_AddRef
  xor eax, eax
  jmp .done

.pointer_error:
  mov eax, E_POINTER
  jmp .done

.no_interface:
  mov eax, E_NOINTERFACE

.done:
  mov esp, ebp
  pop ebp
  ret 12

MinimalObject_AddRef:
  push ebp
  mov ebp, esp

  mov eax, [ebp+8]
  inc dword [eax+MINIMAL_OBJECT_REFCOUNT]
  mov eax, [eax+MINIMAL_OBJECT_REFCOUNT]

  mov esp, ebp
  pop ebp
  ret 4

MinimalObject_Release:
  push ebp
  mov ebp, esp

  mov ecx, [ebp+8]
  dec dword [ecx+MINIMAL_OBJECT_REFCOUNT]
  mov eax, [ecx+MINIMAL_OBJECT_REFCOUNT]
  jnz .done

  dec dword [g_objectCount]
  push ecx
  call [GetProcessHeap]
  pop edx
  push edx
  push 0
  push eax
  call [HeapFree]
  xor eax, eax

.done:
  mov esp, ebp
  pop ebp
  ret 4

MinimalObject_GetValue:
  push ebp
  mov ebp, esp

  mov eax, [ebp+12]
  test eax, eax
  jz .pointer_error
  mov dword [eax], 1234
  xor eax, eax
  mov esp, ebp
  pop ebp
  ret 8

.pointer_error:
  mov eax, E_POINTER
  mov esp, ebp
  pop ebp
  ret 8

section '.data' data readable writeable

g_lockCount dd 0
g_objectCount dd 0
g_hInstance dd 0

sz_clsid_key       db 'CLSID\{7A5F4E21-8C1B-4AF1-9A2B-112233445566}',0
sz_inproc_subkey   db 'InprocServer32',0
sz_inproc_full_key db 'CLSID\{7A5F4E21-8C1B-4AF1-9A2B-112233445566}\InprocServer32',0
sz_friendly_name   db 'TinyComObject',0
sz_threading_model db 'ThreadingModel',0
sz_apartment       db 'Apartment',0

ClassFactory_Instance:
  dd ClassFactory_Vtbl

MinimalObject_Vtbl:
  dd MinimalObject_QueryInterface
  dd MinimalObject_AddRef
  dd MinimalObject_Release
  dd MinimalObject_GetValue

ClassFactory_Vtbl:
  dd ClassFactory_QueryInterface
  dd ClassFactory_AddRef
  dd ClassFactory_Release
  dd ClassFactory_CreateInstance
  dd ClassFactory_LockServer

IID_IUnknown:
  dd 00000000h
  dw 0000h
  dw 0000h
  db 0C0h,00h,00h,00h,00h,00h,00h,046h

IID_IClassFactory:
  dd 00000001h
  dw 0000h
  dw 0000h
  db 0C0h,00h,00h,00h,00h,00h,00h,046h

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

section '.edata' export data readable

export 'test_com_dll.dll', \
  DllCanUnloadNow, 'DllCanUnloadNow', \
  DllGetClassObject, 'DllGetClassObject', \
  DllRegisterServer, 'DllRegisterServer', \
  DllUnregisterServer, 'DllUnregisterServer'

section '.idata' import data readable writeable

library kernel32, 'KERNEL32.DLL', \
  advapi32, 'ADVAPI32.DLL'

include 'api/kernel32.inc'
include 'api/advapi32.inc'

section '.reloc' fixups data readable discardable