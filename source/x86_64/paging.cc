export module x86_64.paging;
import types;

export namespace mem {
    enum {
        PML4_SHIFT      = 39,
        PDP_SHIFT       = 30,
        PD_SHIFT        = 21,
        PT_SHIFT        = 12,
    };

    enum {
        PG_PRESENT      = (1 << 0),
        PG_WRITABLE     = (1 << 1),
        PG_USER         = (1 << 2),
    };

    typedef union {
        struct {
            bool present       : 1;
            bool writable      : 1;
            bool user_access   : 1;
            bool write_through : 1;
            bool disable_cache : 1;
            bool accessed      : 1;
            bool dirty         : 1;
            bool huge_page     : 1;
            bool global        : 1;
            ulong custom       : 3;
            ulong addr         : 52;
        };
        ulong entry;
    } pte_t;
}