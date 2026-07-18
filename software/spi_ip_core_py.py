import serial
import time

PORT     = "COM3"
BAUDRATE = 9600

CMD_RESET       = 0x00
CMD_SQUARE_WAVE = 0x01
CMD_SINE        = 0x02
CMD_SAWTOOTH    = 0x03
CMD_TRIANGLE    = 0x04

def main():
    try:
        ser = serial.Serial(PORT, BAUDRATE, timeout=1)
        time.sleep(0.5)

        # MicroBlaze baslangic mesajlarini okuma kismi
        while ser.in_waiting:
            print("[FPGA]:", ser.readline().decode(errors="ignore").strip())

    except Exception as e:
        print(f"port acilamadi: {e}")
        return

    print("\n ---SPI IP Core Lite---")
    print("  0 -> Sistemi Durdur")
    print("  1 -> Kare Dalga")
    print("  2 -> Sinus Dalga")
    print("  3 -> Testere Disi")
    print("  4 -> Ucgen Dalga")
    print("  q -> Cikis")
    print(" \n")

    try:
        while True:
            cmd = input("Komut gir: ").strip().lower()

            if cmd == "q":
                ser.write(bytes([CMD_RESET]))
                time.sleep(0.2)
                print("Cikiliyor...")
                break
            elif cmd == "0":
                ser.write(bytes([CMD_RESET]))
                print("-> Reset komutu gonderildi")
            elif cmd == "1":
                ser.write(bytes([CMD_SQUARE_WAVE]))
                print("-> Kare dalga baslatildi")
            elif cmd == "2":
                ser.write(bytes([CMD_SINE]))
                print("-> Sinus dalga baslatildi")
            elif cmd == "3":
                ser.write(bytes([CMD_SAWTOOTH]))
                print("-> Testere disi baslatildi")
            elif cmd == "4":
                ser.write(bytes([CMD_TRIANGLE]))
                print("-> Ucgen dalga baslatildi")
            else:
                print("Gecersiz komut!")
                continue

            time.sleep(0.3)

            while ser.in_waiting:
                print("[FPGA]:", ser.readline().decode(errors="ignore").strip())

    finally:
        ser.close()
        print("Port kapatildi")


main()



