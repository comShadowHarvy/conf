import psutil
import time
import logging
import datetime

# --- Configuration ---
LOG_FILE_NAME = f"system_performance_{datetime.datetime.now().strftime('%Y-%m-%d_%H-%M-%S')}.log"
LOG_FORMAT = "%(asctime)s - %(levelname)s - %(message)s"
MONITOR_INTERVAL_SECONDS = 5  # Time in seconds between each log entry

# --- Setup Logging ---
logging.basicConfig(
    filename=LOG_FILE_NAME,
    level=logging.INFO,
    format=LOG_FORMAT,
    datefmt="%Y-%m-%d %H:%M:%S"
)

console_handler = logging.StreamHandler()
console_handler.setLevel(logging.INFO)
console_handler.setFormatter(logging.Formatter(LOG_FORMAT, datefmt="%Y-%m-%d %H:%M:%S"))
logging.getLogger().addHandler(console_handler)

def get_system_performance():
    """
    Retrieves current CPU and memory usage.

    Returns:
        tuple: (cpu_usage_percent, memory_usage_percent, memory_used_mb, memory_total_mb)
               Returns (None, None, None, None) if an error occurs.
    """
    try:
        # Get CPU usage. interval=1 means it will compare CPU times over 1 second.
        # Using a non-zero interval provides a more accurate representation than an instantaneous reading.
        cpu_usage = psutil.cpu_percent(interval=1)

        # Get memory usage
        memory_info = psutil.virtual_memory()
        memory_percent = memory_info.percent
        memory_used_mb = memory_info.used / (1024 * 1024)  # Convert bytes to MB
        memory_total_mb = memory_info.total / (1024 * 1024) # Convert bytes to MB

        return cpu_usage, memory_percent, memory_used_mb, memory_total_mb
    except Exception as e:
        logging.error(f"Error retrieving system performance: {e}")
        return None, None, None, None

def main():
    """
    Main function to monitor system performance and log data.
    """
    logging.info("System Performance Monitor started.")
    logging.info(f"Logging data every {MONITOR_INTERVAL_SECONDS} seconds to {LOG_FILE_NAME}")
    logging.info("Press Ctrl+C to stop.")

    try:
        while True:
            cpu_usage, memory_percent, memory_used_mb, memory_total_mb = get_system_performance()

            if cpu_usage is not None and memory_percent is not None:
                log_message = (
                    f"CPU Usage: {cpu_usage:.2f}% | "
                    f"Memory Usage: {memory_percent:.2f}% "
                    f"({memory_used_mb:.2f} MB / {memory_total_mb:.2f} MB)"
                )
                logging.info(log_message)

            time.sleep(MONITOR_INTERVAL_SECONDS)

    except KeyboardInterrupt:
        logging.info("System Performance Monitor stopped by user.")
    except Exception as e:
        logging.error(f"An unexpected error occurred: {e}")
    finally:
        logging.info("System Performance Monitor finished.")

if __name__ == "__main__":
    # Check if psutil is installed
    try:
        import psutil
    except ImportError:
        print("Error: The 'psutil' library is not installed. Please install it by running:")
        print("pip install psutil")
        exit(1)
    main()

