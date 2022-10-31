from exchangelib import DELEGATE, IMPERSONATION, Account, Credentials, EWSDateTime, EWSDate, EWSTimeZone, Configuration, NTLM, GSSAPI, CalendarItem, Message, Mailbox, Attendee, Q, ExtendedProperty, FileAttachment, ItemAttachment, HTMLBody, Build, Version, FolderCollection, UTC_NOW
import datetime
import os
import zipfile
import sys
import calendar
import shutil
import csv
from itertools import islice
import re
import termcolor as tr
import time

def download_email_attachment(source_folder):
    print("Connecting to exchange..")
    # credentials = Credentials(username='siem_alarms', password='Ostrava2012')
    # account = Account('siem_alarms@tieto.com', credentials=credentials, autodiscover=True, access_type=DELEGATE)

    credentials = Credentials(username='siem_alarms',password='Ostrava2012')
    config = Configuration(server='cas.tieto.com', credentials=credentials)
    account = Account(primary_smtp_address='siem_alarms@tieto.com', config=config, autodiscover=False, access_type=DELEGATE)

    print('Connected..')
    hansel_siem = account.inbox / 'Other Security Serivices' / 'Hansel_SIEM'
    hansel_siem_filtered = hansel_siem.filter(subject__in=('FIN SIEM Valtiokonttori Hanselvironemnt Reports', 'FIN SIEM Valtiokonttori Shared Environment Reports' ))
    q = (Q(body__contains='HANSEL_REPORTS BODY_TEXT') | Q(body__contains='Valtiokonttori reports from shared SIEM'))
    print("Preparing search.")
    now = datetime.datetime.now()
    day = now.day
    month = now.month
    year = now.year
    tz = EWSTimeZone.localzone()
    hansel_siem_filtered = hansel_siem_filtered.filter(datetime_received__range=(tz.localize(EWSDateTime(year, month, 1)), tz.localize(EWSDateTime(year, month, day))))
    messages = hansel_siem.all().filter(q).filter(datetime_received__range=(tz.localize(EWSDateTime(year, month, 1)), tz.localize(EWSDateTime(year, month, day))))
    print("Execute search and loop through the result set")
    print("There are {} results".format(messages.count()))
    for email in messages:
        # a = messages.size
        print("Processing {1} - {0}".format(email.subject, email.datetime_received))
        for attachment in email.attachments:
            if isinstance(attachment, FileAttachment):
                local_path = os.path.join(source_folder, email.body + '_' + attachment.name)
                with open(local_path, 'wb') as f, attachment.fp as fp:
                    buffer = fp.read(1024)
                    while buffer:
                        f.write(buffer)
                        buffer = fp.read(1024)
                print('\tSaved attachment to ', local_path)

def unzip(source_folder):
    files = os.listdir(source_folder)
    extracted_files = []
    for i in files:
        if i.lower().endswith('.zip'):
            with zipfile.ZipFile(os.path.join(source_folder, i), "r") as zip_ref:

                print("Unziping ", os.path.join(source_folder, i))
                zip_ref.setpassword(b'test7')
                print(zip_ref.testzip())
                # zip_ref.extractall(source_folder, pwd=b'test7')
                filesInZip = zip_ref.namelist()
                for fileName in filesInZip:
                    if fileName.lower().endswith('.csv') or fileName.lower().endswith('.pdf'):
                        extracted_files.append((fileName, zip_ref.read(fileName)))


    return extracted_files

def sort_to_folders(extracted_files, folder, folder1, folder2, folder_csv, folder1_csv, folder2_csv):

    i = 0
    for report in extracted_files:
        name = report[0]
        data = report[1]
        print("Sorting : " + name)
        dest = None
        if ".pdf" in name.lower():
            if "SIEM_CLOUD" in name or "SIEM_INFRA" in name or "SIEM_TREASURY" in name or "SIEM_Devices" in name:
                dest = os.path.join(folder, name)
                #_New_Reports_From_SIEM_Cloud-1-30
            elif ("KIEKU_FTP_Linux" in name):
                dest = os.path.join(folder2, name)
                #_New_Reports_From_SIEM_Hansel-1-30_FTP_Linux
            elif ("SIEM_KaK" in name):
                dest = os.path.join(folder1, name)
                #_New_Reports_From_SIEM_Hansel-1-30
        elif ".csv" in name.lower():
            if "SIEM_CLOUD" in name or "SIEM_INFRA" in name or "SIEM_TREASURY" in name or "SIEM_Devices" in name:
                dest = os.path.join(folder_csv, name)
            elif ("KIEKU_FTP_Linux" in name):
                dest = os.path.join(folder2_csv, name)
            elif ("SIEM_KaK" in name):
                dest = os.path.join(folder1_csv, name)
        else:
            print("Not categorized: {}".format(name))

        if dest:
            with open(dest, 'wb+') as f:
                f.write(data)

def creation_date_check(destination_folder, csv1, csv2, csv3, time_now):
    csv_list = [csv1, csv2, csv3]
    for x in range(0, 3):
        print("\n\n\n", csv_list[x])
        files = os.listdir(csv_list[x])
        for i in files:
            print(i)
            with open(csv_list[x]+i) as csvfile:
                spamreader = csv.reader(csvfile)
                for row in islice(spamreader, 2):
                    r1=str(row)
                    r2=re.search(r'Created Date:(.*?)\'', r1)
                    r3=re.search(r'\s\d{4}.(\d{2})', r1)
                if int(r3.group(1)) != time_now:
                    print("Created date:", tr.colored(r2.group(1), 'red'))
                else:
                    print("Created date:",  r2.group(1))

def prepare_dest(destination_folder, source_folder):
    now = datetime.datetime.now()
    time_now = now.month
    month = calendar.month_name[now.month - 1]
    year = now.year

    root_dir = os.path.join(destination_folder, "Reports from SIEM - " + month + " " + str(year))

    folder = os.path.join(root_dir, "Reports_" + month + "_New_Reports_From_SIEM_Cloud-1-30")
    folder_csv = (folder + "/csv/")
    folder1 = os.path.join(root_dir, "Reports_" + month + "_New_Reports_From_SIEM_Hansel-1-30")
    folder1_csv = (folder1 + "/csv/")
    folder2 = os.path.join(root_dir, "Reports_" + month + "_New_Reports_From_SIEM_Hansel-1-30_FTP_Linux")
    folder2_csv = (folder2 + "/csv/")

    os.makedirs(folder, exist_ok=True)
    os.makedirs(folder1, exist_ok=True)
    os.makedirs(folder2, exist_ok=True)
    os.makedirs(folder_csv, exist_ok=True)
    os.makedirs(folder1_csv, exist_ok=True)
    os.makedirs(folder2_csv, exist_ok=True)

    return folder, folder1, folder2, folder_csv, folder1_csv, folder2_csv, time_now

def main(source_folder="in", destination_folder="out"):
    if len(sys.argv) < 3:
        print("Using default folder 'in'/'out' for attachment and reports storage.")
        print("Or hit Ctrl+C and can use: ./reports.py [source_folder] [destination_folder]")
        time.sleep(1)
    else:
        source_folder = sys.argv[1]
        destination_folder = sys.argv[2]

    download_attachments = True
    cwd = os.getcwd()
    source_folder = os.path.join(cwd, source_folder)
    destination_folder = os.path.join(cwd, destination_folder)

    #Check in/out folders emptiness
    if len(os.listdir(destination_folder)) != 0:
        print('Warning: Destination folder "{}" is not empty.\nDelete destination folder?'.format(destination_folder))
        userchar = input("[Y]es/[N]o - default [N]:")
        if userchar is not "":
            if userchar[0].lower() == 'y':
                shutil.rmtree(destination_folder)

    if len(os.listdir(source_folder)) != 0:
        download_attachments = False
        print('Warning: Source folder "{}" is not empty.\nDelete source folder?'.format(source_folder))
        print("[Y]es/[N]o - default [N]:")
        userchar = input("[Y]es/[N]o - default [N]:")
        if userchar is not "":
            if userchar[0].lower() == 'y':
                shutil.rmtree(source_folder)
                download_attachments = True


    #Create base source/destination folders
    if not os.path.isdir(source_folder):
        os.makedirs(source_folder)
        print("Created source folder")
    if not os.path.isdir(destination_folder):
        os.makedirs(destination_folder)
        print("Created destination folder")

    if download_attachments:
        download_email_attachment(source_folder)
    folder, folder1, folder2, folder_csv, folder1_csv, folder2_csv, time_now = prepare_dest(destination_folder, source_folder)
    extracted_files = unzip(source_folder)
    #sort_to_folders(destination_folder, source_folder)
    sort_to_folders(extracted_files, folder, folder1, folder2, folder_csv, folder1_csv, folder2_csv)
    creation_date_check(destination_folder, folder_csv, folder1_csv, folder2_csv, time_now)



if __name__ == '__main__':
    main()

