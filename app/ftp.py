#!/usr/bin/python

import os
import shutil

def setup(dist, apps, conf):
	pub = conf['pub.path']

	if os.path.exists('/etc/vsftpd.conf'):
		src = '/etc/vsftpd.conf'
	elif os.path.exists('/etc/vsftpd/vsftpd.conf'):
		src = '/etc/vsftpd/vsftpd.conf'
	else:
		print 'vsftpd.conf does not exist!'
		return

	#os.system('chmod +r ' + src)

	dst = '/tmp/vsftpd.conf'

	try:
		fsrc = open(src)
		fdst = open(dst, 'w+')
	except Exception, e:
		print e
		return

	exist = {}
	exist['local_root'] = pub
	#exist['anon_root'] = pub
	exist['anonymous_enable'] = 'NO'
	exist['write_enable'] = 'YES'
	exist['local_umask'] = '022'

	for line in fsrc:
		entry = line.split('=')
		if len(entry) > 1:
			key = entry[0].strip()
			if key[0] == '#':
				key = key[1:]
			if key in exist:
				fdst.write('%s=%s\n' % (key, exist[key]))
				exist.pop(key)
			else:
				fdst.write(line)
		else:
			fdst.write(line)

	for (key, value) in exist.items():
		fdst.write('%s=%s\n' % (key, value))

	fsrc.close()
	fdst.close()

	shutil.copyfile(dst, src)

if __name__ == '__main__':
	pub = '/opt/vsftp'
	if not os.path.exists(pub):
		os.mkdir(pub)
	setup(None, None, {'pub.path': pub})
