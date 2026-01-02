#!/usr/bin/env python3
import fcntl
import termios
import struct
import sys

def get_info():
    # struct winsize { unsigned short ws_row, ws_col, ws_xpixel, ws_ypixel; };
    # The format 'HHHH' stands for 4 unsigned short integers
    fmt = 'HHHH'
    
    try:
        # Query the kernel for terminal window size on standard output
        result = fcntl.ioctl(sys.stdout.fileno(), termios.TIOCGWINSZ, struct.pack(fmt, 0, 0, 0, 0))
        rows, cols, width_px, height_px = struct.unpack(fmt, result)

        print(f"\033[1;34m--- Terminal Geometry ---\033[0m")
        print(f"Grid Size   : \033[1m{cols}\033[0m cols x \033[1m{rows}\033[0m rows")
        
        # Some terminals (like pure TTYs) return 0 for pixels. We check for that.
        if width_px > 0 and height_px > 0:
            print(f"Window Size : {width_px}px x {height_px}px")
            
            # Calculate individual character size
            char_w = width_px / cols
            char_h = height_px / rows
            
            print(f"\n\033[1;34m--- Character Estimates ---\033[0m")
            print(f"Width       : {char_w:.2f}px")
            print(f"Height      : {char_h:.2f}px")
        else:
            print("\n\033[33mNote: Your terminal emulator is not reporting pixel dimensions to the kernel.\033[0m")

    except Exception as e:
        print(f"Error retrieving terminal size: {e}")

if __name__ == "__main__":
    get_info()
