#!/usr/bin/python

import os, sys
from datetime import date
from lib.base import name_to_mail

def get_full_name():
	login = os.getenv('USER')
	full_name = ''

	fp_user = open('/etc/passwd', 'r')
	for line in fp_user:
		account = line.split(':')
		if login == account[0]:
			full_name = account[4]

	fp_user.close()

	return full_name

def config(dist, apps):
	conf = {}
	name = get_full_name()
	group = ['msmtp', 'fetchmail', 'procmail']
	home = os.getenv('HOME')

	email = name_to_mail(name)
	domain = email.split('@')[1]

	now = date.today()
	term = "cs%d%d" % (now.year % 100, (now.month + 1) / 2)
	epass = 'MW%s' % term

	maildir = 'Mail/Inbox/cur'
	if not os.path.exists(home + '/' + maildir):
		os.makedirs(home + '/' + maildir)

	rc_list = []
	for pkg in group:
		rc = '%s/.%src' % (home, pkg)

		if os.path.exists(rc):
			if not conf.has_key('email') and not conf.has_key('epass'):
				continue
			print 'updating %src ...' % pkg
		else:
			print 'generating %src ...' % pkg

		if pkg == 'msmtp':
			rc_list.append(rc)

			if os.path.exists(rc):
				for line in fileinput.input(rc, 1):
					s = line.split()

					if len(s) == 0:
						print line,
						continue

					if s[0] == 'user' or s[0] == 'from':
						if conf.has_key('email'):
							print line.replace(s[1], email),
						else:
							print line,
					elif s[0] == 'password':
						if conf.has_key('epass'):
							print line.replace(s[1], epass),
						else:
							print line,
					elif s[0] == 'host':
						print line.replace(s[1], 'smtp.%s' % domain),
					else:
						print line,

				continue

			fd = open(rc, 'w+')
			fd.write('defaults\n\n')
			fd.write('account %s\n' % domain)
			fd.write('host smtp.%s\n' % domain)
			fd.write('user %s\n' % email)
			fd.write('from %s\n' % email)
			fd.write('password %s\n' % epass)
			fd.write('auth login\n\n')
			fd.write('account default: %s' % domain)
			fd.close()
		elif pkg == 'fetchmail':
			rc_list.append(rc)

			if os.path.exists(rc):
				for line in fileinput.input(rc, 1):
					s = line.split()
					if len(s) > 0 and (s[0] == 'user'):
						if conf.has_key('email'):
							print line.replace(s[1], email),
						else:
							print line,
					elif len(s) > 0 and (s[0] == 'poll'):
						if conf.has_key('email'):
							print line.replace(s[1], 'pop.%s' % domain),
						else:
							print line,
					elif len(s) > 0 and (s[0] == 'password'):
						if conf.has_key('epass'):
							print line.replace(s[1], epass),
						else:
							print line,
					else:
						print line,

				continue

			fd = open(rc, 'w+')
			fd.write('set daemon 600\n')
			fd.write('poll pop.%s with protocol pop3\n' % domain)
			fd.write('uidl\n')
			fd.write('user "%s"\n' % email)
			fd.write('password "%s"\n' % epass)
			fd.write('keep\n')
			fd.write('mda "/usr/bin/procmail -d %T"\n')
			fd.close()
		elif pkg == 'procmail':
			rc_list.append(rc)

			if os.path.exists(rc):
				continue

			fd = open(rc, 'w+')
			fd.write('MAILDIR=$HOME/Mail\n')
			fd.write('DEFAULT=$MAILDIR/Inbox/\n')
			fd.close()

		os.chmod(rc, 0600)

	return rc_list
