# Scripts for Mattermost reporting

* `devices.txt` is used to identify and contact ELMs, RECs, ... see below.
* `vars.sh` contains various configurable variables and also a few functions. Antipattern?
* [mmost-sender](mmost-sender/) serves communication with MatterMost *per se* adding all the bells and whistles.
  * File `mmost-sender-templates.json` in this directory defines the templates to send.
  * `mmost-sender.pl` is the script that uses it.
* [tasks](tasks/) contains scripts for crontab tasks like `mailqueue.sh`.

## Very Manual Installation
1. Create new private channel in Mattermost named `MMost-X` where `X` is a familiar name.
2. Add purpose `Bad news beautifully decorated. Enjoy... ahem ahem... Read about the project at https://git.etb.tieto.com/SOC/soc-siem-operations/-/tree/master/MMost .`
3. Add header `MMost Checks running on some_nice_name (ESM_server_name)`
4. Create directory structure on ESM
		```
		cd /root && mkdir -p MMost/tmp && mkdir -p MMost/tasks && mkdir -p MMost/mmost-sender && cd MMost
		```
5. Copy the files to `/root/MMost` following structure of this project. Then add execution attributes
	```
	chmod +x /root/MMost/mmost-sender/mmost-sender.pl && chmod +x /root/MMost/tasks/*.sh && chmod +x /root/MMost/tasks/*.pl && chmod +x /root/MMost/vars.sh
	```
6. Run `sc`. Copy&paste the output to `/root/MMost/devices.txt`. The content of the file should look like
	```
	(1) Local ESM       10.251.115.67   (ESM) ESM Management Node
	(2) SIEMGESWE-REC01 10.248.41.202   (REC)EventReciever
	(3) SIEMGSWSWE-REC01 10.251.124.30   (REC)EventReciever
	(4) SIEMITASWE-REC01 10.238.38.147   (REC)EventReciever
	(5) SIEMREGSWE-REC01 10.238.38.145   (REC)EventReciever
	(6) SIEMSWE-ACE01   10.238.38.136   (ACE)AdvancedCorrelationEngine
	(7) SIEMSWE-ELM01   10.238.38.137   (ELM)EventLogManager
	(8) SIEMSWE-REC01   10.238.38.138   (REC)EventReciever
	(9) SIEMSWE-REC02   10.238.38.139   (REC)EventReciever
	(10) SIEMSWE-REC03   10.238.38.144   (REC)EventReciever
	(11) SIEMVOLSWE-REC01 10.238.38.146   (REC)EventReciever
	```
7. In `/root/MMost/vars.sh`: replace `MMOST_CHANNEL` according to where to send reports for the McAfee environment. It is "Friendly Name" of the channel:
	For the channel see *View Info* , URL (for example `https://mattermost.soc.tieto.com/soc/channels/mmost-swe` ) and use the `mmost-swe`
8. Just for aestetical pleasing also in `/root/MMost/vars.sh` set `HOST_NAME`. Please use "real" name like `SIEMSWE-ESM01`, it is used in scripts to display information from ESM server.

	!!! **The following step must be done after every reboot!**
9. Manually start script *custodian* (This script keeps username and password only in RAM and outside any source code which is favorite programmers' security mistake):
   1.  ```screen```
   2.  ```/root/MMost/tasks/custodian.sh```
   3.  Enter whole string for authentication. You will find the string in [Vault](https://vault.soc.tieto.com/ui/vault/secrets/CyberSec-SIEM/show/siem-public-api)
   4.  Detach from screen: *Ctrl-a* and then *d*

10. Set crontab. Use `crontab -e` to **add** lines like
	```
	0 * * * * /root/MMost/tasks/mailqueue.sh |& logger ; sleep 3 ; /root/MMost/tasks/nitrostarted.sh |& logger ; sleep 3 ; /root/MMost/tasks/thirdparty.sh |& logger ; sleep 3 ; /root/MMost/tasks/processingspeed.sh |& logger ; sleep 3 ; /root/MMost/tasks/lfinput.sh |& logger
	30 7 * * * /root/MMost/tasks/zonechecker.sh |& logger
	0 6 * * * /root/MMost/tasks/nitrotid.sh |& logger
	```



## mmost-sender-templates.json

If you want to create your template, it **must** contain line `"channel": "CHANNEL_MAGIC_VALUE"`, for example:


		"PLAIN": {
			"channel": "CHANNEL_MAGIC_VALUE",
			"templateComment": "Easiest message without attachments.",
			"username": "USERNAME_MAGIC_VALUE",
			"text": "TEXT_MAGIC_VALUE"
		},

Reason behind that is: we use "unlocked webhook" => it is the template/script (parameter `--channel`) responsibility to chose wisely where to send payload. If omitted, the payload will be sent to `mmost-swe` for historical reasons.

