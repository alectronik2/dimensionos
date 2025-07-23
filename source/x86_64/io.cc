export module x86_64.io;

import types;

constexpr auto COM1_PORT = 0x3F8;  // COM1 base port

export namespace io {
    // Write a byte to the specified port
    void outb(unsigned short port, unsigned char val) {
        asm volatile ("out %1, %0" : : "a"(val), "Nd"(port));
    }

    // Read a byte from the specified port
    u8
    inb(unsigned short port) {
        unsigned char ret;
        asm volatile ("in %0, %1" : "=a"(ret) : "Nd"(port));
        return ret;
    }
}

export namespace serial {
    // Initialize serial port
    void init() {
        io::outb(COM1_PORT + 1, 0x00);    // Disable interrupts
        io::outb(COM1_PORT + 3, 0x80);    // Enable DLAB (set baud rate divisor)
        io::outb(COM1_PORT + 0, 0x03);    // Set divisor to 3 (38400 baud) (low byte)
        io::outb(COM1_PORT + 1, 0x00);    // High byte
        io::outb(COM1_PORT + 3, 0x03);    // 8 bits, no parity, one stop bit
        io::outb(COM1_PORT + 2, 0xC7);    // Enable FIFO, clear them, with 14-byte threshold
        io::outb(COM1_PORT + 4, 0x0B);    // IRQs enabled, RTS/DSR set
    }

    // Check if transmit FIFO is empty
    int is_transmit_empty() {
        return io::inb(COM1_PORT + 5) & 0x20;
    }

    // Write a character
    void write_char(char c) {
        while (is_transmit_empty() == 0);
        io::outb(COM1_PORT, c);
    }

    // Write a string
    void write_string(const char* str) {
        while (*str) {
            write_char(*str++);
        }
    }
}