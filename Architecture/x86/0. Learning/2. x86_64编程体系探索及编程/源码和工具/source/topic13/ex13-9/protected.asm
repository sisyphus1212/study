; protected.asm
; Copyright (c) 2009-2012 mik 
; All rights reserved.


%include "..\inc\support.inc"
%include "..\inc\protected.inc"

; ���� protected ģ��

        bits 32
        
        org PROTECTED_SEG - 2

PROTECTED_BEGIN:
protected_length        dw        PROTECTED_END - PROTECTED_BEGIN       ; protected ģ�鳤��

entry:
        
;; �ر�8259
        call disable_8259

;; ���� #PF handler
        mov esi, PF_HANDLER_VECTOR
        mov edi, PF_handler
        call set_interrupt_handler        

;; ���� #GP handler
        mov esi, GP_HANDLER_VECTOR
        mov edi, GP_handler
        call set_interrupt_handler

; ���� #DB handler
        mov esi, DB_HANDLER_VECTOR
        mov edi, debug_handler
        call set_interrupt_handler


;; ���� sysenter/sysexit ʹ�û���
        call set_sysenter

; ����ִ�� SSE ָ��        
        mov eax, cr4
        bts eax, 9                                ; CR4.OSFXSR = 1
        mov cr4, eax
        
        
;���� CR4.PAE
        call pae_enable
        
; ���� XD ����
        call execution_disable_enable
                
; ��ʼ�� paging ����
        call init_pae_paging
        
;���� PDPT ����ַ        
        mov eax, PDPT_BASE
        mov cr3, eax
                                
; �򿪡�paging
        mov eax, cr0
        bts eax, 31
        mov cr0, eax               
                  
                
        
;; ʵ�� 13-9���������ݶϵ�

; 1) ���� CR4.DE
	mov eax, cr4
	bts eax, DE_BIT
	mov cr4, eax
	
;2) ����I/O�ϵ� enable λ
	mov eax, dr7
	or eax, 0xE0001					; L0=1, R/W0=10B, LEN0=11B
	mov dr7, eax

;3) ���� I/O�ϵ�
	mov eax, 0x93
	mov dr0, eax

	
; 4) ���� I/O �ϵ�
	in al, 0x92

; 5) ���� ins ָ��
;	mov dx, 0x90
;	mov ecx, 4
;	rep insb
        
        jmp $


        
; ת�� long ģ��
        ;jmp LONG_SEG
                                
                                
; ���� ring 3 ����
        push DWORD user_data32_sel | 0x3
        push DWORD USER_ESP
        push DWORD user_code32_sel | 0x3        
        push DWORD user_entry
        retf

        
;; �û�����

user_entry:
        mov ax, user_data32_sel
        mov ds, ax
        mov es, ax

user_start:

        jmp $


;--------------------------------
; #DB handler
;--------------------------------
debug_handler:
	jmp do_debug_handler
dh_msg1	db '>>> now, enter #DB handler', 10, 0
dh_msg2	db 'now, exit #DB handler <<<', 10, 0	
dh_msg3	db 'read 92 port(Byte): 0x',0
do_debug_handler:
	push ecx
	movzx ecx, al
	mov esi, dh_msg1
	call puts
	call dump_drs				; ��ӡ DR0-DR3
	call dump_dr6				; ��ӡ DR6
	call dump_dr7				; ��ӡ DR7
	mov esi, dh_msg3
	call puts
	mov esi, ecx
	call print_byte_value
	call println
	mov esi, dh_msg2
	call puts
	pop ecx
	iret





        
;******** include �ж� handler ���� ********
%include "..\common\handler32.asm"


;********* include ģ�� ********************
%include "..\lib\creg.asm"
%include "..\lib\cpuid.asm"
%include "..\lib\msr.asm"
%include "..\lib\pci.asm"
%include "..\lib\debug.asm"
%include "..\lib\page32.asm"
%include "..\lib\apic.asm"
%include "..\lib\pic8259A.asm"


;;************* ���������  *****************

; ��� lib32 �⵼������� common\ Ŀ¼�£�
; ������ʵ��� protected.asm ģ��ʹ��

%include "..\common\lib32_import_table.imt"


PROTECTED_END: