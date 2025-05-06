import os
import shutil
import fnmatch

input_dir = 'input'
archive_dir = 'archive'
file_masks = ['report_*.csv', 'sales_*.csv']

if not os.path.exists(archive_dir):
    os.makedirs(archive_dir)

for filename in os.listdir(input_dir):
    if any(fnmatch.fnmatch(filename, pattern) for pattern in file_masks):
        shutil.move(os.path.join(input_dir, filename), os.path.join(archive_dir, filename))
