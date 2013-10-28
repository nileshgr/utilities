<?php

$num_cores = 4;             // SET NUMBER OF CORES
$hyperthreading = true;     // SET THIS TO TRUE IF CPU HAS INTEL HT

ob_start();
header("Status: 200 OK");
header("Content-Type: text/plain");
echo "PHP Test - Success\n";
$con = new mysqli("localhost", "<username>", "<password>");
if($con->connect_errno) {
        echo "MySQL Error: " . $con->connect_errno . " " . $con->connect_error;
        header("Status: 500 Error");
}
else {
        echo "MySQL Success\n";
}

$con->close();

echo "System Status: \n";
echo "\tUptime: " . explode(", ", `uptime`)[0] . "\n";
$load = sys_getloadavg();

$multiplier = $hyperthreading ? 1.5 : 1;

echo "\t1 minute load: " . round($load[0] * 100/($num_cores * $multiplier), 2) . "%\n";
echo "\t5 minute load: " . round($load[1] * 100/($num_cores * $multiplier), 2) . "%\n";
echo "\t15 minute loaad: " . round($load[2] * 100/($num_cores * $multiplier), 2) . "%\n";
ob_flush();
