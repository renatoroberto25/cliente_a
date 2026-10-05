(modinfo cramfs  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+cramfs\b' && ! lsmod | grep -q cramfs) || (! modinfo cramfs ) 
(modinfo squashfs  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+squashfs\b' && ! lsmod | grep -q squashfs) || (! modinfo squashfs ) 
(modinfo udf  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+udf\b' && ! lsmod | grep -q udf) || (! modinfo udf ) 
(modinfo hfs  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+hfs\b' && ! lsmod | grep -q hfs) || (! modinfo hfs ) 
(modinfo hfsplus  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+hfsplus\b' && ! lsmod | grep -q hfsplus) || (! modinfo hfsplus ) 
(modinfo jffs2  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+jffs2\b' && ! lsmod | grep -q jffs2) || (! modinfo jffs2 ) 
(modinfo freevxfs  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+freevxfs\b' && ! lsmod | grep -q freevxfs) || (! modinfo freevxfs ) 
(modinfo overlay  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+overlay\b' && ! lsmod | grep -q overlay) || (! modinfo overlay ) 
(modinfo usb-storage  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+usb_storage\b' && ! lsmod | grep -q usb_storage) || (! modinfo usb-storage ) 
(modinfo dccp  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+dccp\b' && ! lsmod | grep -q dccp) || (! modinfo dccp ) 
(modinfo sctp  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+sctp\b' && ! lsmod | grep -q sctp) || (! modinfo sctp ) 
(modinfo rds  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+rds\b' && ! lsmod | grep -q rds) || (! modinfo rds ) 
(modinfo tipc  && modprobe --showconfig | grep -Pq '\b(install|blacklist)\h+tipc\b' && ! lsmod | grep -q tipc) || (! modinfo tipc ) 

MOD=cramfs; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD" 2>/dev/null;
MOD=squashfs; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD" 2>/dev/null;
MOD=udf; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD" 2>/dev/null;
MOD=hfs; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD" 2>/dev/null;
MOD=hfsplus; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD" 2>/dev/null;
MOD=jffs2; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD" 2>/dev/null;
MOD=freevxfs; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD" 2>/dev/null;
MOD=overlay; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD" 2>/dev/null;
MOD=usb_storage; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD" 2>/dev/null;
MOD=dccp; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD" 2>/dev/null;
MOD=sctp; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD" 2>/dev/null;
MOD=rds; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD" 2>/dev/null;
MOD=tipc; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD" 2>/dev/null;




[root@rhel8-soft-20260108 renato]# modprobe tipc
[root@rhel8-soft-20260108 renato]# MOD=tipc; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD"
blacklist tipc
install tipc /bin/true
[root@rhel8-soft-20260108 renato]# sed -i '/tipc/d' /etc/modprobe.d/*.conf
[root@rhel8-soft-20260108 renato]# MOD=tipc; lsmod | grep "^$MOD" || modprobe --showconfig | grep -P "^\s*(install|blacklist)\s+$MOD\b" || modinfo -F name "$MOD"
tipc
[root@rhel8-soft-20260108 renato]#  

type    : CMD_EXEC
cmd     : "MOD=usb_storage; lsmod | grep \"^$MOD\" || modprobe --showconfig | grep -P \"^\\s*(install|blacklist)\\s+$MOD\\b\" || modinfo -F name \"$MOD\" 2>/dev/null"
expect  : "(?m)^\\s*(blacklist\\s+usb_storage|install\\s+usb_storage\\s+/bin/true)\\b"
