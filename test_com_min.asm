format PE DLL

include 'win32a.inc'

S_OK                      = 0
E_NOINTERFACE             = 80004002h
CLASS_E_NOAGGREGATION     = 80040110h
CLASS_E_CLASSNOTAVAILABLE = 80040111h

section '.text' code readable executable

DllGetClassObject:
  push ebp
  mov ebp, esp

  mov eax, [ebp+16]
  mov dword [eax], 0

  push CLSID_TinyUnknown
  push dword [ebp+8]
  call IsEqualGUID
  test eax, eax
  jz .bad_class

  push IID_IClassFactory
  push dword [ebp+12]
  call IsEqualGUID
  test eax, eax
  jnz .return_factory

  push IID_IUnknown
  push dword [ebp+12]
  call IsEqualGUID
  test eax, eax
  jz .no_interface

.return_factory:
  mov eax, [ebp+16]
  mov dword [eax], ClassFactory_Instance
  xor eax, eax
  jmp .done

.bad_class:
  mov eax, CLASS_E_CLASSNOTAVAILABLE
  jmp .done

.no_interface:
  mov eax, E_NOINTERFACE

.done:
  mov esp, ebp
  pop ebp
  ret 12

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
  xor eax, eax
  jmp .done

.no_interface:
  mov eax, E_NOINTERFACE

.done:
  mov esp, ebp
  pop ebp
  ret 12

Static_AddRef:
  mov eax, 1
  ret 4

Static_Release:
  mov eax, 1
  ret 4

ClassFactory_CreateInstance:
  push ebp
  mov ebp, esp

  cmp dword [ebp+12], 0
  jne .no_aggregation

  push dword [ebp+20]
  push dword [ebp+16]
  push TinyObject_Instance
  call TinyObject_QueryInterface
  jmp .done

.no_aggregation:
  mov eax, CLASS_E_NOAGGREGATION

.done:
  mov esp, ebp
  pop ebp
  ret 16

ClassFactory_LockServer:
  xor eax, eax
  ret 8

TinyObject_QueryInterface:
  push ebp
  mov ebp, esp

  mov eax, [ebp+16]
  mov dword [eax], 0

  push IID_IUnknown
  push dword [ebp+12]
  call IsEqualGUID
  test eax, eax
  jz .no_interface

  mov eax, [ebp+16]
  mov edx, [ebp+8]
  mov [eax], edx
  xor eax, eax
  jmp .done

.no_interface:
  mov eax, E_NOINTERFACE

.done:
  mov esp, ebp
  pop ebp
  ret 12

section '.data' data readable writeable

ClassFactory_Instance:
  dd ClassFactory_Vtbl

TinyObject_Instance:
  dd TinyObject_Vtbl

ClassFactory_Vtbl:
  dd ClassFactory_QueryInterface
  dd Static_AddRef
  dd Static_Release
  dd ClassFactory_CreateInstance
  dd ClassFactory_LockServer

TinyObject_Vtbl:
  dd TinyObject_QueryInterface
  dd Static_AddRef
  dd Static_Release

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

CLSID_TinyUnknown:
  dd 012345678h
  dw 1234h
  dw 5678h
  db 090h,0ABh,0CDh,0EFh,001h,023h,045h,067h

section '.edata' export data readable

export 'test_com_min.dll', \
  DllGetClassObject, 'DllGetClassObject'

section '.reloc' fixups data readable discardable