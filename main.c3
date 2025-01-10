
fn void delay(int ms)
{
    const CYCLES_PER_MS = 90;  // Very roughly.
    for (int i = 0; i < ms * CYCLES_PER_MS; i++)
    {
        asm("nop");
    }
}

// Port B Data Register.
const ushort PORTB = 0x25;
// Port B Data Direction Register.
const ushort DDRB = 0x24;
// Port B Input Pins Address.
const ushort PINB = 0x23;

// Port D Data Register.
const ushort PORTD = 0x2B;
// Port D Data Direction Register.
const ushort DDRD = 0x2A;
// Port D Input Pins Address.
const ushort PIND = 0x29;

// We can't use enum because of following problem:
// LLVM ERROR: Unsupported expression in static initializer: ptrtoint (ptr @"$ct.int" to i64)
// enum PinMode
// {
//     INPUT,
//     OUTPUT,
// }

// We can't even use distinct - same reason as enum:
// LLVM ERROR: Unsupported expression in static initializer: ptrtoint (ptr @"$ct.char" to i64)
// distinct PinMode = char;
// const PinMode INPUT = 0;
// const PinMode OUTPUT = 1;

// This works.
def PinMode = char;
const PinMode INPUT = 0;
const PinMode OUTPUT = 1;

fn void pin_mode(int pin, PinMode mode)
{
    if (pin < 0 || pin > 7) return;

    char orig = $$volatile_load((char*)DDRD);
    char new;
    if (mode == INPUT)
    {
        new = orig & ~(1 << pin);
    }
    else
    {
        new = orig | (1 << pin);
    }
    $$volatile_store((char*)DDRD, new);
}

fn bool digital_read(int pin)
{
    if (pin < 0 || pin > 7) return false;

    char pind = $$volatile_load((char*)PIND);
    return pind & (1 << pin) != 0;
}

fn void digital_write(int pin, bool bit)
{
    if (pin < 0 || pin > 7) return;

    char portd = $$volatile_load((char*)PORTD);
    char new;
    if (bit)
    {
        new = portd | (1 << pin);
    }
    else
    {
        new = portd & ~(1 << pin);
    }
    $$volatile_store((char*)PORTD, new);
}

fn int main()
{
    pin_mode(3, OUTPUT);
    pin_mode(4, OUTPUT);
    pin_mode(5, OUTPUT);
    pin_mode(2, INPUT);

    while (true)
    {
        bool switchState = digital_read(2);
        if (switchState)
        {
            digital_write(3, false);
            digital_write(4, false);
            digital_write(5, true);
            delay(250);

            digital_write(4, true);
            digital_write(5, false);
            delay(250);
        }
        else
        {
            digital_write(3, true);  // Green LED.
            digital_write(4, false);  // Red LED.
            digital_write(5, false);  // Red LED.
        }
    }
}
