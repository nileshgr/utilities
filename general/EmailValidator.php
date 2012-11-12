<?php

function checkMail($mail) {

  if(strlen($mail) <= 0) {
    return false;
  }

  $split = explode('@', $mail);

  if(count($split) > 2) {
    return false;
  }

  list($username, $domain) = $split;

  /*
   * Don't allow 
   * Two dots, Two @
   * !, #, $, ^, &, *, (, ), [, ], {, }, ?, /, \, ~, `, <, >, ', "
   */

  $userNameRegex1 = '/\.{2,}|@{2,}|[\!#\$\^&\*\(\)\[\]{}\?\/\\\|~`<>\'"]+/';
  
  /*
   * Username should consist of only 
   * A-Z, a-z, 0-9, -, ., _, +, %
   */

  $userNameRegex2 = '/[a-z0-9_.+%-]+/i';
  
  /*
   * Domain cannot contain two successive dots
   */

  $domainRegex1 = '/\.{2,}/';

  /*
   * Domain can contain only
   * A-Z, a-z, 0-9, ., -,
   */

  $domainRegex2 = '/[a-z0-9.-]+/i';

  if(preg_match($userNameRegex1, $username) or
    !preg_match($userNameRegex2, $username) or
     preg_match($domainRegex1, $domain) or 
    !preg_match($domainRegex2, $domain) or
    !checkdnsrr($domain, 'MX')) {
    return false;
  } else {
    return true;
  }

}
