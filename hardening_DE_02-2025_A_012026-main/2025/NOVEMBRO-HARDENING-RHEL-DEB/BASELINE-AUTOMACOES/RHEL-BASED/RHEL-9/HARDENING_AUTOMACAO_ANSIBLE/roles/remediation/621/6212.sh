
echo "218 Ensure journald log file access is configured"
echo "--------EXEMPLO--------"
echo "sed -i 's\0700\0640\g' /usr/lib/tmpfiles.d/systemd.conf"
echo "sed -i 's\0755\0640\g' /usr/lib/tmpfiles.d/systemd.conf"
echo "sed -i 's\2755\0640\g' /usr/lib/tmpfiles.d/systemd.conf"
echo "--------EXEMPLO--------"