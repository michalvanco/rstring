node 'agent' {
include custom_mysql
}

class custom_mysql {
$password="hungcao"

package { ["mysql","mysql-server", "wget"]:
	ensure => latest
}

service { "mysqld":
	ensure => running,
	enable => true
}

exec { "check_mydb":
        subscribe => [ Package["mysql-server"], Package["mysql"]],
        command => "/usr/bin/mysql -umysql -p$password -e \"create database mydb\"",
        unless => "/usr/bin/mysql -umysql -p$password -e \"use mydb;\"",
}

exec { "check_mytable":
        subscribe => [ Package["mysql-server"], Package["mysql"]],
        command => "/usr/bin/mysql -umysql -p$password -e \"CREATE TABLE mydb.users ( id INT, username VARCHAR(40), path VARCHAR(200) )\"",
        unless => "/usr/bin/mysql -umysql -p$password -e \"select * from mydb.users;\"",
        require => Exec ["check_mydb"],
 }

exec { "check_newtable":
        subscribe => [ Package["mysql-server"], Package["mysql"]],
        command => "/usr/bin/mysql -umysql -p$password -e \"CREATE TABLE mydb.newusers ( username VARCHAR(40) )\"",
        unless => "/usr/bin/mysql -umysql -p$password -e \"select * from mydb.newusers;\"",
        require => Exec ["check_mydb"],
 }

file { "/tmp/puppet":
        ensure => "directory",
}


file { "/etc/puppet/modules/sqlscript":
	ensure => present,
	mode   => 660,
	owner  => puppet,
	group  => puppet,
        subscribe => [ file["/tmp/puppet"]],
}

exec { "sqlscript":
	command => "/bin/sh /etc/puppet/modules/sqlscript",
	subscribe => [ File["/etc/puppet/modules/sqlscript"]],
	require => Exec ["check_mytable","check_mydb","check_newtable"],
}
}
