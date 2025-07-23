OUTPUT_FORMAT( elf64-x86-64 )
OUTPUT_ARCH( i386 : x86_64 )

ENTRY( kmain )

PHDRS {
    limine_requests PT_LOAD;
    text            PT_LOAD;
    rodata          PT_LOAD;
    data            PT_LOAD;
}

SECTIONS {
     . = 0xffffffff80000000;

     . = ALIGN( 0x1000 );

    .limine_requests : {
        KEEP(*(.limine_requests_start))
        KEEP(*(.limine_requests))
        KEEP(*(.limine_requests_end))
    } :limine_requests

     . = ALIGN( 0x1000 );

     .text : {
        *(.text .text.*)
     }

     . = ALIGN( 0x1000 );

     .rodata : {
        *(.rodata; .rodata.* )
     }

     .init_array : {
        __init_array_start = .;
        KEEP(*(SORT_BY_INIT_PRIORITY(.init_array.*) SORT_BY_INIT_PRIORITY(.ctors.*)))
        KEEP(*(.init_array .ctors))
        __init_array_end = .;
     }

     . = ALIGN( 0x1000 );

     .data : {
        *(.data .data.*)
     } :data

     .bss : {
        *(.bss .bss.*)
        *(COMMON)
     } :data

     /DISCARD/ : {
        *(.eh_frame*)
        *(.note .note.*)
     }
}