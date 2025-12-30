# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "holidays",
# ]
# ///

import time
import sys
from datetime import datetime
import holidays

def get_next_holiday():
    """Finds the next upcoming holiday for Ontario, Canada."""
    now = datetime.now()
    # Get holidays for this year and next year to ensure we find one
    # subdiv='ON' ensures we get Ontario specifics like Family Day
    on_holidays = holidays.Canada(subdiv='ON', years=[now.year, now.year + 1])
    
    # Filter for dates in the future
    upcoming = []
    for date, name in on_holidays.items():
        # Convert date to datetime for comparison
        h_date = datetime(date.year, date.month, date.day)
        if h_date > now:
            upcoming.append((h_date, name))
            
    # Sort by date and return the first one
    upcoming.sort(key=lambda x: x[0])
    return upcoming[0] if upcoming else None

def countdown():
    target_date, holiday_name = get_next_holiday()
    
    if not target_date:
        print("Could not find an upcoming holiday.")
        return

    print(f"\nSearching for closest holiday...")
    print(f"Target Acquired: \033[1;32m{holiday_name}\033[0m") # Bold Green text
    print(f"Date: {target_date.strftime('%A, %B %d, %Y')}\n")

    try:
        while True:
            now = datetime.now()
            remaining = target_date - now

            # If we passed the date
            if remaining.total_seconds() <= 0:
                print("\n\n\033[1;31m!!! HAPPY HOLIDAY !!!\033[0m")
                break

            days = remaining.days
            hours, remainder = divmod(remaining.seconds, 3600)
            minutes, seconds = divmod(remainder, 60)

            # Format the time string
            # \033[K clears the rest of the line to prevent artifacts
            time_str = f"{days}d {hours:02}h {minutes:02}m {seconds:02}s"
            
            # Print with carriage return (\r) to overwrite the line
            sys.stdout.write(f"\r\033[1;36mTime Remaining:\033[0m {time_str} \033[K")
            sys.stdout.flush()
            time.sleep(1)
            
    except KeyboardInterrupt:
        print("\nCountdown stopped.")

if __name__ == "__main__":
    countdown()
