#! /bin/bash

if [[ -z "${INITIAL_USERNAME}" ]]; then
  INITIAL_USERNAME="user"
fi

if [[ -z "${INITIAL_VNC_PASSWORD}" ]]; then
  INITIAL_VNC_PASSWORD="userland"
fi

if [ ! -f /home/$INITIAL_USERNAME/.vnc/passwd ]; then

prog=/usr/bin/vncpasswd

/usr/bin/expect <<EOF
spawn "$prog"
expect "Password:"
send "$INITIAL_VNC_PASSWORD\r"
expect "Verify:"
send "$INITIAL_VNC_PASSWORD\r"
expect "(y/n)?"
send "n\r"
expect eof
exit
EOF

fi

if [ ! -f /home/$INITIAL_USERNAME/.vnc/server.crt ]; then
   openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -keyout /home/$INITIAL_USERNAME/.vnc/server.pem -out /home/$INITIAL_USERNAME/.vnc/server.crt -subj "/C=NA"
fi

rm /tmp/.X51-lock
rm /tmp/.X11-unix/X51
vncserver -kill :51
vncserver :51 -x509key /home/$INITIAL_USERNAME/.vnc/server.pem -x509cert /home/$INITIAL_USERNAME/.vnc/server.crt

while [ ! -f /home/$INITIAL_USERNAME/.vnc/localhost:51.pid ]
do
  sleep 1
done
cd ~
DISPLAY=localhost:51 xterm -geometry 80x24+0+0 -e /bin/bash --login &
