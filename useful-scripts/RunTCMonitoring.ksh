#!/bin/ksh
# Wrapper for TC Monitoring 
#PET
ssh -t amdocs@10.33.200.244 "ssh vivtools@vlts0478co '/vivnas/viv/vivtools/MONITOR/generateHTMLReport.sh ReportConfiguration.ini 15 2>>/vivnas/viv/vivtools/MONITOR/log/runMonitor.log'" > /tmp/tc_report.txt
cat /tmp/tc_report.txt | /usr/lib/sendmail -t
#PROD
ssh -t amdocs@10.33.200.244 "ssh vivtools@vlts0948sl '/vivnas/viv/prdtools/MONITOR/generateHTMLReport.sh ReportConfiguration.ini 15 2>>/vivnas/viv/prdtools/MONITOR/log/runMonitor.log'" > /tmp/tc_report_prod.txt
cat /tmp/tc_report_prod.txt | /usr/lib/sendmail -t
