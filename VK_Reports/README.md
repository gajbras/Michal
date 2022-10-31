# VK_Reports

This script has been created to automate monthly VK reports. 

1) Download attachments from shared e-mail box
2) Unzip files
3) Sort to folders in destination folder

### Prerequisites

#### 1) Python3

```
https://www.python.org/downloads/

```

#### 2) Pip


![pip_install](/Images/pip.gif)

#### 3) exchangelib python library

```
pip install git+https://github.com/ecederstrand/exchangelib.git
```
![exchangelib](/Images/exchangelib.gif)
### Usage

```
python3 reports.py [source_folder] [destination_folder]
```

## Authors

* **Jiri Liska** - *Initial work* 

#### Known bugs:

-   Name of month in destination folder do not create December when the script is run in January
-   When processing on on MacOS hidden file .DS_Store can appier in the folder which unzip is not able to process 

## Acknowledgments

* Enjoy
* Aditional bugs please report to creator or contribute :)

