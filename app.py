import datetime as dt

now = dt.datetime.now()

print('This is the main app')
print(f"Date: {now.strftime('%Y-%m-%d %H:%M:%S')}")