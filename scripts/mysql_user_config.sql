update user set host='%' where user='root' and host='127.0.0.1';
flush privileges;