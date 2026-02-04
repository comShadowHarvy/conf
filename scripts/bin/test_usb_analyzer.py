import unittest
from unittest.mock import patch, MagicMock
import sys
import os
from pathlib import Path

# Add the bin directory to path so we can import usb_analyzer
sys.path.append('/home/mw/git/conf/scripts/bin')
import usb_analyzer

class TestUSBAnalyzer(unittest.TestCase):

    def test_find_usb_devices(self):
        # Mock lsblk data
        mock_data = {
            "blockdevices": [
                {
                    "name": "sda",
                    "tran": "sata",
                    "children": [
                        {"name": "sda1", "tran": "sata"}
                    ]
                },
                {
                    "name": "sdb",
                    "tran": "usb",
                    "model": "FlashDrive",
                    "children": [
                        {"name": "sdb1", "tran": "usb", "mountpoint": "/run/media/user/USBSTICK", "size": 1024000}
                    ]
                }
            ]
        }
        
        devices = usb_analyzer.find_usb_devices(mock_data)
        # Should find sdb (parent) and sdb1 (child)
        self.assertEqual(len(devices), 2)
        device_names = [d['name'] for d in devices]
        self.assertIn('sdb', device_names)
        self.assertIn('sdb1', device_names)

    @patch('usb_analyzer.os.walk')
    @patch('usb_analyzer.Path')
    def test_analyze_directory(self, mock_path, mock_walk):
        # Setup mock directory walk
        # root, dirs, files
        mock_walk.return_value = [
            ('/fake/path', [], ['script.py', 'image.png', 'notes.txt', 'program.c'])
        ]
        
        # Mock file size return
        mock_file_obj = MagicMock()
        mock_file_obj.stat.return_value.st_size = 1024 # 1KB per file
        # We need to make sure Path(root) / file works
        mock_path_instance = MagicMock()
        mock_path_instance.lstat.return_value.st_size = 1024
        mock_path_instance.suffix = '.py' # Default reset later
        
        # This is strictly a logic test for the counting mechainsm
        # It's easier to verify investigate logic by passing a real (temporary) dir, 
        # but let's try a simple unit test with manual injection if possible, 
        # or simplified:
        
        stats = {
            'file_count': 0,
            'extensions': {},
            'languages': {},
            'size_bytes': 0
        }
        
        # Let's bypass the complex mocking of pathlib and os.walk and just test the logic 
        # if I were to separate the logic. 
        # Instead, I'll write a integration test with a temp directory.
        pass

    def test_integration_temp_dir(self):
        import tempfile
        import shutil
        
        # Create a temp directory structure
        test_dir = tempfile.mkdtemp()
        try:
            # Create some dummy files
            Path(test_dir, "test.py").touch()
            Path(test_dir, "test.js").touch()
            Path(test_dir, "image.jpg").touch()
            Path(test_dir, "README.md").touch()
            
            # Analyze
            stats = usb_analyzer.analyze_directory(test_dir)
            
            self.assertEqual(stats['file_count'], 4)
            self.assertEqual(stats['skipped_count'], 0)
            self.assertEqual(stats['extensions']['.py'], 1)
            self.assertEqual(stats['languages']['Python'], 1)
            self.assertEqual(stats['languages']['JavaScript'], 1)
            # Size of 0 because touch creates empty files
            self.assertEqual(stats['languages_size']['Python'], 0)
            self.assertEqual(stats['languages']['Image'], 1)
            
        finally:
            shutil.rmtree(test_dir)

if __name__ == '__main__':
    unittest.main()
