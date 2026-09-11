import hashlib
import sys
import zipfile


with zipfile.ZipFile(sys.argv[1]) as package:
    for info in package.infolist():
        data = package.read(info.filename)
        print(f"{info.filename}\t{len(data)}\t{hashlib.sha256(data).hexdigest()}")
