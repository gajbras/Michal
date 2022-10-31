import datetime
import csv
import zipfile
import os


# CurrentDate = datetime.datetime.today().strftime("%Y-%m-%d")
# print(CurrentDate)

# Unziping multiple files into folder for next time use
def unzip():
    with zipfile.ZipFile(r"C:\Users\zimcimic\Desktop\test_csv_multi.zip", 'r') as myzip:
        myzip.extractall(r'C:\Users\zimcimic\Desktop\test')


unzip()

folderPath = r"C:\Users\zimcimic\Desktop\test\test_csv_multi"
filePaths = [os.path.join(folderPath, name) for name in os.listdir(folderPath)]
all_files = []


# Open csv file from path and convert it into tuple
# def read_from_file():
#   with open(r'C:\Users\zimcimic\Desktop\test.CSV', newline='') as f:
#       reader = csv.reader(f)
#       data = [tuple(row) for row in reader]
#       print(data)


# read_from_file()

# Multiple opening files and appending to one tuple
def multiple_read():
    for path in filePaths:
        with open(path, 'r', newline='') as f:
            reader = csv.reader(f)
            file = [tuple(row) for row in reader]
            all_files.append(file)
            print(file)


multiple_read()
