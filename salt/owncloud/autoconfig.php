<?php
$AUTOCONFIG = array(
  "dbtype"        => "pgsql",
  "dbname"        => "owncloud",
  "dbuser"        => "owncloud",
  "dbpass"        => "{{ db_pass }}",
  "dbhost"        => "{{ db_host }}",
  "dbtableprefix" => "",
  {% if admin_user is defined %}
  "adminlogin"    => "{{ admin_user }}",
  {% if admin_pass is defined %}
  "adminpass"     => "{{ admin_pass }}",
  {% endif %}
  {% endif %}
  "directory"     => "{{ directory }}",

  "blacklisted_files" => array(
    ".htaccess",
    "Thumbs.Db",
    ".DS_Store"),
);
