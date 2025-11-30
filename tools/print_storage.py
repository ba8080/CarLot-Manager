import storage
p = storage._data_file()
print('DATA_FILE:', p)
print('EXISTS:', p.exists())
if p.exists():
    print(p.read_text())
else:
    print('No inventory.json present at that location')
