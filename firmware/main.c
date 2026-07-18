#include "xparameters.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "xuartlite_l.h"

// SPI adresler
#define SPI_BASE XPAR_SPI_IP_CORE_LITE_0_BASEADDR
#define SPI_TX_REG (SPI_BASE + 0x00)
#define SPI_RX_REG (SPI_BASE + 0x04)
#define SPI_CTRL_REG (SPI_BASE + 0x08)
#define SPI_STATUS_REG (SPI_BASE + 0x0C)
#define SPI_PRESCALER_REG (SPI_BASE + 0x10)

// Control register bit maskeleri
#define CTRL_ENABLE 0x01
#define CTRL_START 0x02
#define CTRL_CS_SHIFT 2

// Status register bit maskeleri
#define STATUS_BUSY 0x01
#define STATUS_DONE 0x02

// DA4 komut sabitleri
#define DA4_CMD_WRITE_UPDATE 0x03
#define DA4_CMD_INT_REF 0x08 // DA4 referans aktiflestirme 1.25V
#define DA4_ADDR_DAC_A 0x00 // DA4 cıkıs portu

// UART base adresi
#define UART_BASE XPAR_AXI_UARTLITE_0_BASEADDR

#define NUM_SAMPLES 256 // Periyot basina sample sayisi
#define DAC_MAX 4095 // Max 12 bit

// Sinus dalga LUT'u
static const u16 sin_table[NUM_SAMPLES] = {
    2048, 2098, 2148, 2198, 2248, 2298, 2348, 2398,
    2447, 2496, 2545, 2594, 2642, 2690, 2737, 2784,
    2831, 2877, 2923, 2968, 3013, 3057, 3100, 3143,
    3185, 3226, 3267, 3307, 3346, 3385, 3423, 3459,
    3495, 3530, 3565, 3598, 3630, 3662, 3692, 3722,
    3750, 3777, 3804, 3829, 3853, 3876, 3898, 3919,
    3939, 3958, 3975, 3992, 4007, 4021, 4034, 4045,
    4056, 4065, 4073, 4080, 4085, 4089, 4093, 4095,
    4095, 4095, 4093, 4089, 4085, 4080, 4073, 4065,
    4056, 4045, 4034, 4021, 4007, 3992, 3975, 3958,
    3939, 3919, 3898, 3876, 3853, 3829, 3804, 3777,
    3750, 3722, 3692, 3662, 3630, 3598, 3565, 3530,
    3495, 3459, 3423, 3385, 3346, 3307, 3267, 3226,
    3185, 3143, 3100, 3057, 3013, 2968, 2923, 2877,
    2831, 2784, 2737, 2690, 2642, 2594, 2545, 2496,
    2447, 2398, 2348, 2298, 2248, 2198, 2148, 2098,
    2048, 1997, 1947, 1897, 1847, 1797, 1747, 1697,
    1648, 1599, 1550, 1501, 1453, 1405, 1358, 1311,
    1264, 1218, 1172, 1127, 1082, 1038,  995,  952,
     910,  869,  828,  788,  749,  710,  672,  636,
     600,  565,  530,  497,  465,  433,  403,  373,
     345,  318,  291,  266,  242,  219,  197,  176,
     156,  137,  120,  103,   88,   74,   61,   50,
      39,   30,   22,   15,   10,    6,    2,    0,
       0,    0,    2,    6,   10,   15,   22,   30,
      39,   50,   61,   74,   88,  103,  120,  137,
     156,  176,  197,  219,  242,  266,  291,  318,
     345,  373,  403,  433,  465,  497,  530,  565,
     600,  636,  672,  710,  749,  788,  828,  869,
     910,  952,  995, 1038, 1082, 1127, 1172, 1218,
    1264, 1311, 1358, 1405, 1453, 1501, 1550, 1599,
    1648, 1697, 1747, 1797, 1847, 1897, 1947, 1997
};

void spi_init(void);
void spi_transfer(u32 data);
void da4_init(void);
void da4_write(u16 dac_value);
void generate_square_wave(void);
void generate_sine_wave(void);
void generate_sawtooth_wave(void);
void generate_triangle_wave(void);

// SPI basla, formulu: prescaller=100MHz/(2*N)
void spi_init(void) {
    Xil_Out32(SPI_PRESCALER_REG, 50);
    Xil_Out32(SPI_CTRL_REG, CTRL_ENABLE);
    xil_printf("SPI baslatildi. Prescaler=50\r\n");
}

// SPI transfer 
void spi_transfer(u32 data) {
    Xil_Out32(SPI_TX_REG, data);

    u32 ctrl = Xil_In32(SPI_CTRL_REG);
    Xil_Out32(SPI_CTRL_REG, ctrl | CTRL_START);
    Xil_Out32(SPI_CTRL_REG, ctrl & ~CTRL_START);

    // Busy=1 bekle
    while (!(Xil_In32(SPI_STATUS_REG) & STATUS_BUSY));
    // Busy=0 bekle
    while (Xil_In32(SPI_STATUS_REG) & STATUS_BUSY);

    // Done sticky temizle
    Xil_Out32(SPI_STATUS_REG, STATUS_DONE);
}

// DA4 baslatma, 1.25V referansini veriyor 
void da4_init(void) {
    spi_transfer(0x08000001);
}

// DA4'e veri yazma
// frame: [0000][0011] [0000] [12 bit data] [00000000] 
void da4_write(u16 dac_value) {
    u32 frame = 0;
    frame |= ((u32)DA4_CMD_WRITE_UPDATE << 24);
    frame |= ((u32)DA4_ADDR_DAC_A << 20);
    frame |= ((u32)(dac_value & 0x0FFF) << 8);
    spi_transfer(frame);
}

// Kare dalga uretimi
void generate_square_wave(void) {
    xil_printf("Kare dalga uretimi basliyor...\r\n");
    u16 idx = 0;

    while (1) {
        if (idx < 128) {
            da4_write(DAC_MAX); // 2.5V
        } else {
            da4_write(0x000); // 0V
        }
        idx = (idx + 1) & 0xFF;

        if (!XUartLite_IsReceiveEmpty(UART_BASE)) {
            if (XUartLite_RecvByte(UART_BASE) == 0x00) {
                xil_printf("Durduruldu.\r\n");
                return;
            }
        }
    }
}

// Sinus dalga uretimi 
void generate_sine_wave(void) {
    xil_printf("Sinus dalgasi uretimi basliyor...\r\n");
    u16 idx = 0;

    while (1) {
        da4_write(sin_table[idx]);
        idx = (idx + 1) & 0xFF;

        if (!XUartLite_IsReceiveEmpty(UART_BASE)) {
            if (XUartLite_RecvByte(UART_BASE) == 0x00) {
                xil_printf("Durduruldu.\r\n");
                return;
            }
        }
    }
}

// Testere disi dalga uretimi
void generate_sawtooth_wave(void) {
    xil_printf("Testere disi dalgasi uretimi basliyor...\r\n");
    u16 idx = 0;

    while (1) {
        u16 dac_val = (u16)((u32)idx * DAC_MAX / (NUM_SAMPLES - 1));
        da4_write(dac_val);
        idx = (idx + 1) & 0xFF;

        if (!XUartLite_IsReceiveEmpty(UART_BASE)) {
            if (XUartLite_RecvByte(UART_BASE) == 0x00) {
                xil_printf("Durduruldu.\r\n");
                return;
            }
        }
    }
}

// Ucgen dalga uretimi 
void generate_triangle_wave(void) {
    xil_printf("Ucgen dalgasi uretimi basliyor...\r\n");
    u16 idx = 0; 

    while (1) {
        u16 dac_val;
        if (idx < 128) {
            dac_val = (u16)((u32)idx * DAC_MAX / 127);
        } else {
            dac_val = (u16)((u32)(255 - idx) * DAC_MAX / 127);
        }
        da4_write(dac_val);
        idx = (idx + 1) & 0xFF;

        if (!XUartLite_IsReceiveEmpty(UART_BASE)) {
            if (XUartLite_RecvByte(UART_BASE) == 0x00) {
                xil_printf("Durduruldu.\r\n");
                return;
            }
        }
    }
}

int main(void) {
    spi_init();
    da4_init();
    xil_printf("\r\nKomutlar:\r\n");
    xil_printf("  0x00 = Sistemi Durdur\r\n");
    xil_printf("  0x01 = Kare Dalga\r\n");
    xil_printf("  0x02 = Sinus Dalga\r\n");
    xil_printf("  0x03 = Testere Disi\r\n");
    xil_printf("  0x04 = Ucgen Dalga\r\n");

    while (1) {
        u8 cmd = XUartLite_RecvByte(UART_BASE);

        switch (cmd) {
            case 0x00:
                spi_init();
                da4_init();
                xil_printf("Reset tamamlandi. Komut bekleniyor...\r\n");
                break;
            case 0x01:
                generate_square_wave();
                xil_printf("Komut bekleniyor...\r\n");
                break;
            case 0x02:
                generate_sine_wave();
                xil_printf("Komut bekleniyor...\r\n");
                break;
            case 0x03:
                generate_sawtooth_wave();
                xil_printf("Komut bekleniyor...\r\n");
                break;
            case 0x04:
                generate_triangle_wave();
                xil_printf("Komut bekleniyor...\r\n");
                break;
            default:
                xil_printf("Bilinmeyen komut: 0x%02x\r\n", cmd);
                break;
        }
    }

    return 0;
}


