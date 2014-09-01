<?php

header("Cache-Control: no-cache, must-revalidate"); // HTTP/1.1
header("Expires: Sat, 26 Jul 1997 05:00:00 GMT"); // Date in the past

$host = "localhost";
$username = "osamalog_itcc";
$passwordDB = "test1234";
$database = "osamalog_itc";

$connection = mysql_connect("$host","$username","$passwordDB");
$dbselected = mysql_select_db("$database") or die(mysql_error());
$table = "SCORES";

$clientData = $_REQUEST["locallyStoredValues"];

$clientDataArray = json_decode($clientData, true);


$userName = $clientDataArray[0]["USER"];

mysql_query("DELETE FROM $table WHERE USER='$userName';") or die(mysql_error);
foreach($clientDataArray as $scoreEntry)
{
	$userName = $scoreEntry["USER"];
	$score = $scoreEntry["SCORE"];
	$id = $scoreEntry["ID"];
	mysql_query("INSERT INTO $table(USER,SCORE,clientID) VALUES('$userName',$score,$id);") or die(mysql_error);	
}

$sth = mysql_query("SELECT * FROM $table where USER = '$userName' order by SCORE DESC;") or die(mysql_error());

$rows = array();
while($r = mysql_fetch_assoc($sth)) {
	$currentScore  = $r['SCORE'];
	$currentID = $r['clientID'];
	$sth2 = mysql_query("SELECT $currentID AS ID, count(*)+1 AS GLOBAL FROM $table where SCORE > $currentScore;") or die(mysql_error());
	$r2 = mysql_fetch_assoc($sth2);
        $rows[] = $r2;
}

mysql_close($connection);

print json_encode($rows);