#!/usr/bin/php -c /etc/php.ini

<?php

/*  Copyright (C) 2015 Eduardo Dimas <eddimas@gmail.com>
    Copyright (C) 2011 shawnbrito@gmail.com 
      http://exchange.nagios.org/directory/Plugins/Others/Send-HTML-Alert-Email/details

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.*/

// Download the following .php files to the nagios/libexec/ folder and give them execution permission.
// Open the .php files and check if the 1st line path/to/php and .ini files are correct, 
// also change the $from email variable to something more meaningful. 
// Now rename both .php files so they dont have the .php extension. 

// Edit the nagios/etc/objects/command.cfg and replace the [notify-service-by-email] block with the following Block... 

// define command{
// command_name notify-service-by-email 
// command_line /usr/local/nagios/libexec/nagios_service_mail "$NOTIFICATIONTYPE$" "$HOSTNAME$" "$HOSTALIAS$" "$HOSTSTATE$" "$HOSTADDRESS$" "$SERVICEOUTPUT$" "$LONGDATETIME$" "$SERVICEDESC$" "$SERVICESTATE$" "$CONTACTEMAIL$" "$SERVICEDURATIONSEC$" "$SERVICEDOWNTIME$" "$TOTALSERVICESWARNING$" "$TOTALSERVICESCRITICAL$" "$TOTALSERVICESUNKNOWN$" 
// } 

//You can validate the script executing it like below:
/* /usr/local/nagios/libexec/nagios_service_mail "PROBLEM" "TestServer" "Test Health Check" "UP" "192.168.1.20" \
   "OK. TEST DISK STATS: / 57% of 1.1G, /home 2% of 4.1G, /tmp 1% of 4.1G, /usr 41% of 4.1G, /var 32% of 4.1G" "10-13-2015 00:30:28" "System disks" \
   "OK" "youremail@domain.com" "600" "0.10" "10" "500" "0" "1429110661" "1429130661" "0" 
*/


array_shift($argv);
 $f_notify_type =array_shift($argv);  /*1*/
 $f_host_name =array_shift($argv);    /*2*/
 $f_host_alias =array_shift($argv);   /*3*/
 $f_host_state =array_shift($argv);    /*4*/
 $f_host_address =array_shift($argv);   /*5*/
 $f_serv_output =array_shift($argv);   /*6*/
 $f_long_date =array_shift($argv);     /*7*/
 $f_serv_desc  =array_shift($argv);    /*8*/
 $f_serv_state  =array_shift($argv);   /*9*/
 $f_to  =array_shift($argv);           /*10*/
 $f_duration = round((array_shift($argv))/60,2);   /*11*/
 $f_exectime =array_shift($argv);       /*12*/
 $f_totwarnings =array_shift($argv);     /*13*/
 $f_totcritical =array_shift($argv);      /*14*/
 $f_totunknowns =array_shift($argv);     /*15*/
 $f_lastserviceok = array_shift($argv);    /*16*/
 $f_lastwarning = array_shift($argv);     /*17*/
 $f_attempts= array_shift($argv);     /*18*/

 $f_downwarn = $f_duration;
 $f_color="#dddddd";

   if($f_serv_state=="OK") {$f_color="#00b71a";$priority="Low";}
   if($f_serv_state=="CRITICAL") {$f_color="#f40000";$priority="High";}
   if($f_serv_state=="UNKNOWN") {$f_color="#cc00de";$priority="Normal";}
   if($f_serv_state=="WARNING") {$f_color="#f48400";$priority="Normal";}

// Check If File Exists ###########
if($f_notify_type=="PROBLEM") {
  $currenttime = time();
  $file_name = "/tmp/$f_host_name.$f_serv_desc.txt";
        if ($f_attempts==1) {
                if(file_exists($file_name)==true) {unlink($file_name);}
           $currenttime = $currenttime+round(($f_duration * 60),0);
           file_put_contents($file_name, "$currenttime");
        }
}

if($f_notify_type=="RECOVERY") {
   $oldtime = time();
   $currenttime = time();
   $file_name = "/tmp/$f_host_name.$f_serv_desc.txt";
        if (file_exists($file_name)==true) {
            $oldtime = intval(file_get_contents($file_name));
        }
   $f_downwarn = round(($currenttime - $oldtime)/60,2);
}

//Pharse specific health checks output (check disks)

$additional_info="<td>Additional Info:</td><td>$f_serv_output</td>\r\n";

$f_serv_output = str_replace("(","/",$f_serv_output);
$f_serv_output = str_replace(")","/",$f_serv_output);
$f_serv_output = str_replace("[","/",$f_serv_output);
$f_serv_output = str_replace("]","/",$f_serv_output);

#$subject = "$f_notify_type Service:$f_host_name/$f_serv_desc [$f_serv_state]";
$subject = "$f_host_alias/$f_host_name Service:$f_serv_desc [$f_serv_state]";

$from  ="Nagios agent <NoReply@testdomain.com>";

$body = "<!DOCTYPE html PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'>\r\n";
$body .= "<!DOCTYPE html PUBLIC '-//W3C//DTD HTML 4.01 Transitional//EN'>\r\n";
$body .= "<html>\r\n";
$body .= "    <head>\r\n";
$body .= "        <meta name='generator' content='Bluefish 2.2.7' >\r\n";
$body .= "        <STYLE TYPE='text/css'>\r\n";
$body .= "            <!--TD{font-family: 'Arial'; font-size: 12pt;}-->\r\n";
$body .= "        </STYLE>\r\n";
$body .= "        <title></title>\r\n";
$body .= "    </head>\r\n";
$body .= "    <body>\r\n";
$body .= "        <div style='width:800px; margin:0 auto;'>\r\n";
$body .= "            <table border='0' width='98%' cellpadding='0' cellspacing='0'>\r\n";
$body .= "                <tr>\r\n";
$body .= "                    <td valign='top'>\r\n";
$body .= "                        <table border='0' cellpadding='0' cellspacing='0' width='97%'>\r\n";
$body .= "                            <tr bgcolor='$f_color'>\r\n";
$body .= "                                <td width='140'><font color='#FFFFFF'>Notification:</font></td>\r\n";
$body .= "                                <td><font color='#FFFFFF'>$f_notify_type [$f_serv_state]</font></td>\r\n";
$body .= "                            </tr>\r\n";
$body .= "                            <tr bgcolor='#FFFFFF'>\r\n";
$body .= "                                <td>Service:</td><td><font color='#0000CC'>$f_serv_desc</font></td>\r\n";
$body .= "                            </tr>\r\n";
$body .= "                            <tr bgcolor='#EEEEFE'>\r\n";
$body .= "                                <td>Server:</td><td><font color='#005500'>$f_host_alias</font></td>\r\n";
$body .= "                            </tr>\r\n";
$body .= "                            <tr bgcolor='#FFFFFF'>\r\n";
$body .= "                                <td>Address:</td><td><font color='#005555'>$f_host_address</font></td>\r\n";
$body .= "                            </tr>\r\n";
$body .= "                            <tr bgcolor='#EEEEFE'>\r\n";
$body .= "                                <td>Date/Time:</td><td><font color='#005555'>$f_long_date</font></td>\r\n";
$body .= "                            </tr>\r\n";
$body .= "                            <tr bgcolor='#FFFFFF'>\r\n";
$body .= "                                <td>More Info:</td>\r\n";
$body .= "                                <td><a href='http://localhost/nagios/cgi-bin/extinfo.cgi?type=2&amp;host=$f_host_name&amp;service=$f_serv_desc'>\r\n";
$body .= "                                        Service details</a></td>\r\n";
$body .= "                            </tr>\r\n";
$body .= "                            <tr bgcolor='#EEEEFE'>\r\n";
$body .= "                                $additional_info";
$body .= "                            </tr>\r\n";
$body .= "                            <tr bgcolor='#FFFFFF'>\r\n";
$body .= "                                <td>State Duration:</td><td><font color='#CC0000'>$f_duration mins.</font></td>\r\n";
$body .= "                            </tr>\r\n";
$body .= "                            <tr bgcolor='#EEEEFE'>\r\n";
$body .= "                                <td>Service ExecTime:</td><td><font color='#CC0000'>$f_exectime</font></td>\r\n";
$body .= "                            </tr>\r\n";
$body .= "                        </table>\r\n";
$body .= "                        <font color='#CC0000'>Actions:</font>\r\n";
$body .= "                        <a href='/localhost/nagios/%20cgi-bin/cmd.cgi?cmd_typ=100&amp;host=$f_host_name&amp;service=$f_serv_desc'>\r\n";
$body .= "                            Stop Obsessing</a></td>\r\n";
$body .= "                    <td valign='top'>\r\n";
$body .= "                        <table border='0' cellpadding='0' cellspacing='0' width='250'>\r\n";
$body .= "                            <tr bgcolor='#000055'>\r\n";
$body .= "                                <td><font color='#FFFFFF'>Summary</font></td>\r\n";
$body .= "                                <td></td>\r\n";
$body .= "                            </tr>\r\n";
$body .= "                            <tr bgcolor='#FFFFFF'>\r\n";
$body .= "                                <td><font size='3'>Total Service Warnings:</font></td>\r\n";
$body .= "                                <td><font size='3'>$f_totwarnings</font></td>\r\n";
$body .= "                            </tr>\r\n";
$body .= "                            <tr bgcolor='#EEEEFE'>\r\n";
$body .= "                                <td><font size='3'>Total Service Critical:</font></td>\r\n";
$body .= "                                <td><font size='3'>$f_totcritical</font></td>\r\n";
$body .= "                            </tr>\r\n";
$body .= "                            <tr bgcolor='#FFFFFF'>\r\n";
$body .= "                                <td><font size='3'>Total Service Unknowns:</font></td>\r\n";
$body .= "                                <td><font size='3'>$f_totunknowns</font></td>\r\n";
$body .= "                            </tr>\r\n";
$body .= "                            <tr bgcolor='#EEEEFE'>\r\n";
$body .= "                                <td><font size='3'>Service <i>DOWN</i> For:</font></td>\r\n";
$body .= "                                <td><font size='3'>$f_downwarn</font><i>m</i></td>\r\n";
$body .= "                            </tr>\r\n";
$body .= "                        </table>\r\n";
$body .= "                    </td>\r\n";
$body .= "                </tr>\r\n";
$body .= "            </table>\r\n";
$body .= "            <p align='left'><font color='#606064' face='Arial' size='3'>Regards, <br>Operations team<br></font></p>\r\n";
$body .= "            <p align='left'><font color='#606064' face='Arial' size='2'>\r\n";
$body .= "                    Tip: If the above 'Service details' link does not work in\r\n";
$body .= "                    your email client, copy this URL into your browser:<br>\r\n";
$body .= "                    <a href='http://localhost/nagios/cgi-bin/extinfo.cgi?type=2&amp;host=$f_host_name&amp;service=$f_serv_desc'>\r\n";
$body .= "                        http://localhost/nagios/cgi-bin/extinfo.cgi?type=2&amp;host=$f_host_name&amp;service=$f_serv_desc</a>\r\n";
$body .= "                </font></p>\r\n";
$body .= "            <p align='center'><font color='#606064' face='Arial' size='2'>\r\n";
$body .= "                    This message was generated by an automated system. Please do not reply to this message.</font>\r\n";
$body .= "            </p>\r\n";
$body .= "        </div>\r\n";
$body .= "    </body>\r\n";
$body .= "</html>\r\n";


  // To send HTML mail, the Content-type header must be set
$headers  = 'MIME-Version: 1.0' . "\r\n";
$headers .= 'Content-type: text/html; charset=iso-8859-1' . "\r\n";
$headers .= "X-Priority: $priority\n";
$headers .= "X-MSMail-Priority: $priority\n";
$headers .= "Importance: $priority\n";
$headers .= "From: $from\r\n";
# $headers .= "Content-type: text/html\r\n";

/* Send eMail Now... */
$m_true = mail($f_to, $subject, $body, $headers);
//if the message is sent successfully print "Mail sent". Otherwise print "Mail failed"
echo $m_true ? "Mail sent" : "Mail failed";
?>
