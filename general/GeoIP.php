<?php

/*
 * GeoIP class
 * Author: Nilesh Govindrajan <me@nileshgr.com>>
 */

/*
 * Load data from hostip.info into your database.
 *
 * Usage:
 * 
 * Create a GeoIP object and pass database configuration options and the method by which IP should be taken
 * 
 * $g = new GeoIP(array('user' => 'root', 'pass' => '', 'name' => 'hostip', 'host' => 'localhost'), GeoIP::IP_FROM_ENV);
 * 
 * The MySQL database configuration array takes user, pass, name, host, socket as options where name is the database name. Other options are self explanatory.
 * 
 * If socket is defined, it takes the preference. 
 * If MySQL listens on a port other than default defined in php.ini,
 * port can be specified in the host as 'localhost:3350'
 *
 * The second parameter, is defined as constant in the class, it takes two values 1 or 2 as integers, or constants-
 * GeoIP::IP_FROM_ENV and GeoIP::IP_FROM_ARG
 *
 * If nothing is specified for the second parameter, by default IP_FROM_ENV is taken.
 * IP_FROM_ENV means that the class should test the IP from environment variables.
 * IP_FROM_ARG means that IP will be provided using the setIP() method.
 *
 * The test method can be overriden later by setMethod():
 * $g->setMethod(GeoIP::IP_FROM_ARG) 
 *
 * Before calling the test() method, you must set countries to be tested using setCountries method:
 * $g->setCountries(array('IN', 'US', 'UK'))
 * The setCountries() method takes only country codes. Country codes specified will be tested for validity and
 * Exception will be thrown in case of failure.
 * 
 * Also, ensure that if you use setIP if you chose IP_FROM_ARG.
 *
 * A complete example to test an IP (testing Google's IP by IP_FROM_ARG):
 *
 * $g = new GeoIP(array('user' => 'root', 'pass' => '', 'name' => 'hostip', 'host' => 'localhost'), GeoIP::IP_FROM_ARG);
 * var_dump($g->setCountries(array('US', 'CN', 'RU'))->setIP('209.85.153.104')->test());
 * Output - bool(true)
 *
 * For convinience all methods except test() return $this. So method calls can be nested (quite evident from the above example).
 *
 */

class GeoIP {

  const IP_FROM_ENV = 1;
  const IP_FROM_ARG = 2;

  private $_IPMethod = self::IP_FROM_ENV;
  private $_IPArr;
  private $_IPContArr;

  private $_ip_isset = false;
  private $_cnt_isset = false;

  private $_db = array();

  /*
   * Available country codes
   * As given in hostip.info database
   */

  private $_availCodes = array(
    'AF','AL','DZ','AS','AD','AO','AI','AQ','AG','AR','AM','AW','AU','AT','AZ','BS','BH','BD','BB','BY','BE','BZ','BJ','BM','BT','BO','BA','BW','BV','BR','IO','BN',
    'BG','BF','BI','KH','CM','CA','CV','KY','CF','TD','CL','CN','CX','CC','CO','KM','CG','CD','CK','CR','CI','HR','CU','CY','CZ','DK','DJ','DM','DO','EC','EG','SV',
    'GQ','ER','EE','ET','FK','FO','FJ','FI','FR','GF','PF','TF','GA','GM','GE','DE','GH','GI','GR','GL','GD','GP','GU','GT','GN','GW','GY','HT','HM','VA','HN','HK',
    'HU','IS','IN','ID','IR','IQ','IE','IL','IT','JM','JP','JO','KZ','KE','KI','KP','KR','KW','KG','LA','LV','LB','LS','LR','LY','LI','LT','LU','MO','MK','MG','MW',
    'MY','MV','ML','MT','MH','MQ','MR','MU','YT','MX','FM','MD','MC','MN','MS','MA','MZ','MM','NA','NR','NP','NL','AN','NC','NZ','NI','NE','NG','NU','NF','MP','NO',
    'OM','PK','PW','PS','PA','PG','PY','PE','PH','PN','PL','PT','PR','QA','RE','RO','RU','RW','SH','KN','LC','PM','VC','WS','SM','ST','SA','SN','CS','SC','SL','SG',
    'SK','SI','SB','SO','ZA','GS','ES','LK','SD','SR','SJ','SZ','SE','CH','SY','TW','TJ','TZ','TH','TL','TG','TK','TO','TT','TN','TR','TM','TC','TV','UG','UA','AE',
    'GB','US','UM','UY','UZ','VU','VE','VN','VG','VI','WF','EH','YE','ZM','ZW','UK','EU','YU','AP','XX','AC','GG','IM','JE','TP'
  );

  public function __construct(array $db, $IPMethod = 0)
  {
    $this->setMethod($IPMethod);
    $checkKeys = array('user', 'name', 'pass');
    foreach($checkKeys as $k)
    {
      if(!isset($db["$k"]))
        throw new Exception('Key: ' . $k . ' is not defined');
      $this->_db["$k"] = $db["$k"];
    }
    $this->_db['constr'] = isset($db['socket']) ? ':' . $db['socket'] : $db['host'];
    if(empty($this->_db['constr']))
      throw new Exception('Host & Socket both were not defined');
    if(!extension_loaded('mysql') and !(ini_get('enable_dl') == "1" and (dl('mysql.so') or dl('mysql.dll'))))
        die("Please load mysql\n");
    if(!($con = mysql_connect($this->_db['constr'], $this->_db['user'], $this->_db['pass'])))
      throw new Exception('Could not connect to MySQL Server: ' . mysql_error($con));
    if(!mysql_select_db($this->_db['name'], $con))
      throw new Exception('Could not select database: ' . mysql_error($con));
    $this->_db['con'] = $con;
    return $this;
  }

  public function setIP($ip = null)
  {
    if($this->_IPMethod != self::IP_FROM_ARG)
      throw new Exception('setIP() is invalid here, because you chose to get IP from Environment variables');
    $this->_setIP($ip);
    return $this;
  }  

  public function setCountries(array $countries)
  {
    $intersection = array_intersect($countries, $this->_availCodes);
    if(count($intersection) != count($countries))
      throw new Exception('You passed one or more invalid country codes');    
    $this->_IPContArr = $countries;
    $this->_cnt_isset = true;
    return $this;
  }

  public function setMethod($IPMethod = 0)
  {
    if($IPMethod == self::IP_FROM_ENV or $IPMethod == self::IP_FROM_ARG)
      $this->_IPMethod = $IPMethod;
    return $this;
  }

  public function test()
  {
    if(!$this->_cnt_isset)
      throw new Exception('You did not set test countires');
    if(!$this->_ip_isset)
      if($this->_IPMethod == self::IP_FROM_ENV)
        $this->_setIPByEnv();
      else
        throw new Exception('You have chosen to test IP by function argument, but you have not set the IP to be tested');
    return $this->_test();
  }
  
  private function _setIP($ip)
  {
    $IPSplit = explode('.', $ip);
    array_walk($IPSplit, create_function('$a', 'return (int) $a;'));
    $IPSplit = array_filter($IPSplit, create_function('$a', 'return ($a > 0 and $a < 256) ? true : false;'));
    if(count($IPSplit) != 4)
      throw new Exception($ip . ' is an invalid IPv4 address');
    $this->_IPArr = $IPSplit;
    $this->_ip_isset = true;
  }

  private function _setIPByEnv()
  {
    $hkeys = array('HTTP_CLIENT_IP', 'HTTP_X_FORWARDED_FOR', 'REMOTE_ADDR');
    foreach($hkeys as $k)
      if(!empty($_SERVER["$k"])) 
      {
        $this->_setIP($_SERVER["$k"]);
        return;
      }    
  }

  private function _test()
  {
    $query = mysql_query(
      sprintf("SELECT code FROM countries WHERE id = ( SELECT country FROM ip4_%d WHERE b = %d AND c = %d )",
        $this->_IPArr[0],
        $this->_IPArr[1],
        $this->_IPArr[2]), $this->_db['con']);
    if(!$query)
      throw new Exception('Query to MySQL Database Failed: ' . mysql_error($this->_db['con']));
    $country = mysql_result($query, 0, 0);
    return in_array($country, $this->_IPContArr) ? true : false;
  }
}
