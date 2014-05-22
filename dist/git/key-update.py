#!/usr/bin/python

import os, sys
import shutil
import fileinput

def key_update(src):
	home = os.getenv('HOME')
	log = home + '/.gitolite.log'
	keydir = home + '/gitolite-admin/keydir'

	os.chdir(home)

	fp_log = open(log, 'a')
	fp_log.write('[%s]\n' % src)

	ga = 'gitolite-admin'
	if os.path.exists(ga):
		os.chdir(ga)
		os.system('git pull')
	else:
		os.system('git clone git@127.0.0.1:gitolite-admin.git')
		os.chdir(ga)

	try:
		fp_rsa = open(src, 'r')
	except Exception, e:
		print e

		fp_log.write('%s does NOT exists!\n' % src)
		fp_log.write('\n')

		fp_log.close()

		exit()

	sig = ''
	for line in fp_rsa:
		sig = line.split()[0]
		break

	if sig != 'ssh-rsa':
		print 'invalid %s' % src
		fp_log.write('invalid %s:\n' % src)

		fp_rsa.seek(0)
		for line in fp_rsa:
			fp_log.write(line)
		fp_log.write('\n')

		exit()

	key = ''
	fp_rsa.seek(0)
	for line in fp_rsa:
		key = line.split()[2]
		key = key.replace('@', '-')
		break

	dst = key + '.pub'

	conf = 'conf/gitolite.conf'
	if os.path.exists(keydir + '/' + dst):
		shutil.copyfile(src, keydir + '/' + dst)
		os.system('git commit -asm "update %s"' % dst)

		fp_log.write('update %s\n' % dst)

	else:
		shutil.copyfile(src, keydir + '/' + dst)

		devel_exist = False
		for line in fileinput.input(conf, inplace = 1):
			user = line.split()

			if user and user[0] == '@devel':
				print line[:-1] + ' ' + key + '\n',
				devel_exist = True
			else:
				print line,
		fileinput.close()

		if not devel_exist:
		    for line in fileinput.input(conf, inplace = 1):
		        if not devel_exist:
		            print '@devel = %s\n' % key + line,
		            devel_exist = True
		        else:
		            print line,
		    fileinput.close()


		os.system('git add %s/%s' % (keydir, dst))
		os.system('git commit -asm "add %s"' % dst)

		fp_log.write('add %s\n' % dst)

	os.system('git push')
	fp_log.write('\n')
	os.system('sudo rm -f ' + src)

	fp_rsa.close()
	fp_log.close()

if __name__ == '__main__':
	key_update(sys.argv[1])
