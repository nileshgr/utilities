<?php

ob_start();
header("Status: 200 OK");
header("Content-Type: text/plain");
echo "PHP Test - Success\n";
$con = mysql_connect("localhost", "<username>", "<password>");
if(!$con) {
        echo "MySQL Error: " . mysql_error();
        header("Status: 500 Error");
}
else {
        echo "MySQL Success\n";
}
echo "System Status: \n";
echo "\tUptime: " . explode(", ", `uptime`)[0] . "\n";
$load = sys_getloadavg();
echo "\t1 minute load: " . $load[0] * 100 . "%\n";
echo "\t5 minute load: " . $load[1] * 100 . "%\n";
echo "\t15 minute loaad: " . $load[2] * 100 . "%\n";
ob_flush();
