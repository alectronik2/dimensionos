export module x86_64.cpu;
import types;
import x86_64.io;
import lib.print;

struct [[gnu::packed]] gdt_entry {
    uint16_t limit_low;
    uint16_t base_low;
    uint8_t  base_middle;
    uint8_t  access;
    uint8_t  granularity;
    uint8_t  base_high;
};

struct [[gnu::packed]] tss_descriptor {
    uint16_t limit_low;
    uint16_t base_low;
    uint8_t  base_middle1;
    uint8_t  access;
    uint8_t  granularity;
    uint8_t  base_middle2;
    uint32_t base_high;
    uint32_t reserved;
};

struct [[gnu::packed]] gdt_pointer {
    uint16_t limit;
    uint64_t base;
};

alignas(16) gdt_entry gdt[5];
alignas(16) gdt_pointer gdtp;

void set_gdt_entry(int idx, uint32_t base, uint32_t limit, uint8_t access, uint8_t gran)
{
    gdt[idx].limit_low    = limit & 0xFFFF;
    gdt[idx].base_low     = base & 0xFFFF;
    gdt[idx].base_middle  = (base >> 16) & 0xFF;
    gdt[idx].access       = access;
    gdt[idx].granularity  = ((limit >> 16) & 0x0F) | (gran & 0xF0);
    gdt[idx].base_high    = (base >> 24) & 0xFF;
}

extern "C" [[noreturn]]
void
kmain() {
    serial::init();
    printk( "Booting up...\n" );
    
    set_gdt_entry(0, 0, 0, 0, 0);                  // Null
    set_gdt_entry(1, 0, 0xFFFFF, 0x9A, 0xA0);      // Kernel code
    set_gdt_entry(2, 0, 0xFFFFF, 0x92, 0xA0);      // Kernel data
    set_gdt_entry(3, 0, 0xFFFFF, 0xFA, 0xA0);      // User code (DPL=3)
    set_gdt_entry(4, 0, 0xFFFFF, 0xF2, 0xA0);      // User data (DPL=3)

    gdtp.limit = sizeof(gdt) + sizeof(tss_descriptor) - 1;
    gdtp.base  = reinterpret_cast<uint64_t>(&gdt);

    asm("lgdt [%0]" :: "r"(&gdtp));
    asm("mov ax, 0x10");
    asm("mov ds, ax");
    asm("mov es, ax");
    asm("mov fs, ax");
    asm("push 0x8")
    asm("push 1f");

    asm("retf");
    asm("1:");
    for(;;);
}
