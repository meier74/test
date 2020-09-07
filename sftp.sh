#!/bin/sh

expect << 'EOS'
spawn sftp cpuftpusr1@cph@ftpuat.smart.gep.com:2380:/Integration
expect "fn#2n4mSpQ:"
send "PASSWORD\n"
expect "sftp>"
send "put test.txt\n"
expect "sftp>"
send "bye\n"
EOS
