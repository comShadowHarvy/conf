# arip - ARM Docker Ripper Setup

A sarcastic yet helpful script that sets up the Automatic Ripping Machine (ARM) Docker container for DVD/Blu-ray ripping automation.

## 🚀 Features

- **Automatic Docker Setup**: Creates all required directories and starts the ARM container
- **Multi-device Support**: Supports up to 4 optical drives (/dev/sr0-sr3)
- **User Permission Management**: Automatically configures ARM_UID and ARM_GID for proper file permissions
- **Sarcastic Commentary**: Entertaining loading sequence and witty error messages
- **Robust Error Handling**: Checks Docker daemon status and validates configuration

## 📖 Usage

### Basic Usage

```bash
# Run the setup script
./arip
```

The script will:
1. Check if Docker daemon is running
2. Create required directories if they don't exist
3. Start the ARM container with proper configuration

### Command Options

```bash
arip

No command-line options - just run it and let it work.
```

## 📋 Requirements

### System Requirements
- **OS**: Linux (tested on Arch-based distributions)
- **Docker**: Docker service must be installed and running
- **Permissions**: User must be in the `docker` group

### Dependencies
- `docker` - Container runtime
- `id` - User/group ID utilities (standard on all Linux systems)

### Installation Commands
```bash
# Install Docker (Arch Linux)
sudo pacman -S docker

# Start Docker service
sudo systemctl enable --now docker

# Add user to docker group
sudo usermod -aG docker $USER
```

## 🛠️ Installation

### Quick Install
```bash
# Copy to local bin directory
cp arip ~/.local/bin/
chmod +x ~/.local/bin/arip
```

### System-wide Install
```bash
# Copy to system bin (requires sudo)
sudo cp arip /usr/local/bin/
sudo chmod +x /usr/local/bin/arip
```

## ⚙️ Configuration

### Directory Structure
The script automatically creates these directories in your home folder:
- `~/arm` - Main ARM working directory
- `~/Music` - For ripped music CDs
- `~/logs` - ARM operation logs
- `~/media` - Output directory for ripped media
- `~/config` - ARM configuration files

### Docker Container Configuration
- **Port**: 2323 (maps to container port 8080)
- **Devices**: `/dev/sr0` through `/dev/sr3` (optical drives)
- **Restart Policy**: `always` - container starts automatically with Docker
- **Container Name**: `arm-rippers`

### Access ARM Web Interface
After the container starts, access the ARM web interface at:
```
http://localhost:2323
```

## 📚 Examples

### Example 1: First Time Setup
```bash
./arip
```
Output:
```
Checking if Docker daemon is running...
Docker daemon looks okay. Proceeding...

Checking if required directories exist... because apparently, I have to do everything.
Directory '/home/user/arm' not found. Creating it for you. You're welcome.
Directory '/home/user/Music' already exists. Good job, I guess.
...
```

### Example 2: Container Already Running
If the container is already running, Docker will return an error. Stop it first:
```bash
docker stop arm-rippers
docker rm arm-rippers
./arip
```

## 🚨 Common Issues

### Issue 1: Docker Daemon Not Running
**Problem**: `Docker daemon does not seem to be running`
**Solution**: 
```bash
sudo systemctl start docker
# OR
sudo service docker start
```

### Issue 2: Permission Denied
**Problem**: `permission denied while trying to connect to Docker daemon`
**Solution**: Add your user to the docker group:
```bash
sudo usermod -aG docker $USER
# Log out and log back in, or run:
newgrp docker
```

### Issue 3: Port Already in Use
**Problem**: Container fails to start due to port 2323 being used
**Solution**: Check what's using the port:
```bash
sudo netstat -tulpn | grep :2323
# Kill the process or change the port in the script
```

## 🔍 Troubleshooting

### Check Container Status
```bash
docker ps                    # Running containers
docker ps -a                # All containers including stopped
docker logs arm-rippers      # View container logs
```

### Container Management
```bash
docker stop arm-rippers      # Stop the container
docker start arm-rippers     # Start existing container
docker restart arm-rippers   # Restart container
docker rm arm-rippers        # Remove container (stops first if needed)
```

### Directory Permissions
If you encounter permission issues with the mounted directories:
```bash
# Fix ownership (replace 'user' with your username)
sudo chown -R user:user ~/arm ~/Music ~/logs ~/media ~/config
```

## 🎬 About ARM (Automatic Ripping Machine)

ARM automatically rips DVDs and Blu-rays when inserted, with features like:
- **Automatic Detection**: Detects disc type and rips accordingly
- **MakeMKV Integration**: Uses MakeMKV for Blu-ray ripping
- **Handbrake Encoding**: Optional video encoding with Handbrake
- **Metadata Lookup**: Automatically fetches movie/show information
- **Web Interface**: Monitor progress and configure settings via web browser

## 🤝 Contributing

This script is part of a personal toolkit. If you find bugs or have suggestions:

1. Check the ARM Docker image documentation
2. Ensure your optical drives are properly detected by the system
3. Test changes in a safe environment

## 📄 License

Created by **ShadowHarvy**

This script is provided as-is for educational and personal use.

## 🔗 Related Tools

- [Automatic Ripping Machine](https://github.com/automatic-ripping-machine/automatic-ripping-machine) - The ARM project
- [MakeMKV](https://www.makemkv.com/) - DVD/Blu-ray ripping software
- [Handbrake](https://handbrake.fr/) - Video encoding software

---

*Part of the ShadowHarvy toolkit - Because manually ripping discs is so 2005*
