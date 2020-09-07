#!/bin/bash
HOST=ftpuat.smart.gep.com
PORT=2380
USER=cpuftpusr1@cph
PASSWORD=fn#2n4mSpQ
SOURCE_FILE=/tmp/test/test.txt
TARGET_DIR=/Integration/ToGEP/OrgEntities

/usr/bin/expect<<EOD > output.log

spawn /usr/bin/sftp -o Port=$PORT $USER@$HOST
expect "password:"
send "$PASSWORD\r"
expect "sftp>"
send "put $SOURCE_FILE $TARGET_DIR\r"
expect "sftp>"
send "bye\r"
EOD
RC=$?
if [[ ${RC} -ne 0 ]]; then
  cat output.log | mail -s "Errors Received" "thomas.meier@cph.dk"
else
  echo "Success" | mail -s "Transfer Successful" "thomas.meier@cph.dk"
fi
rm -fr /sti/til/filer/*.*
