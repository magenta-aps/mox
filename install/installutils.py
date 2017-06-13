from __future__ import print_function

import errno
import collections
import datetime
import multiprocessing
import os
import pwd
import subprocess
import sys
import tempfile
import UserDict

import jinja2
import virtualenv

# ------------------------------------------------------------------------------

DIR = os.path.dirname(os.path.abspath(sys.modules['__main__'].__file__))
MOXDIR = os.path.dirname(os.path.dirname(os.path.realpath(
    os.path.splitext(__file__)[0] + '.py')
))

logfilename = os.path.join(DIR, 'install.log')


class _RedirectOutput(object):
    '''Context manager for temporarily redirecting stdout & stderr.

    Loosely based on contextlib._RedirectStream from the Python 3.4
    standard library.

    '''

    def __new__(cls, new_target):
        if new_target:
            return object.__new__(cls, new_target)

    def __init__(self, new_target):
        self._new_target = new_target
        # We use a list of old targets to make this CM re-entrant
        self._old_targets = []

    def __enter__(self):
        self._old_targets[:] = [sys.stdout, sys.stderr]
        if isinstance(self._new_target, basestring):
            sys.stdout = sys.stderr = open(self._new_target, 'a')
        else:
            sys.stdout = sys.stderr = self._new_target
        return sys.stdout

    def __exit__(self, exctype, excinst, exctb):
        if isinstance(self._new_target, basestring):
            os.fsync(sys.stdout)
            sys.stdout.close()

        sys.stdout, sys.stderr = self._old_targets


class Config(object, UserDict.DictMixin):
    def __init__(self, file, create=True):
        self.file = file
        self.lines = []
        self.data = collections.OrderedDict()
        self.lastline = 0
        if create:
            self.create()

    def load(self):
        if self.exists():
            self.lastline = 0
            fp = open(self.file, 'r')
            i = 0
            for line in fp:
                if '=' in line:
                    (key, value) = line.split('=', 1)
                    key = key.strip()
                    obj = {'key': key, 'value': value.strip()}
                    self.data[key] = obj
                    self.lines.append(obj)
                else:
                    self.lines.append(line.strip('\n'))
                i += 1
            fp.close()

    def exists(self):
        return os.path.isfile(self.file)

    def create(self):
        if not self.exists():
            if os.path.exists(self.file):
                # The path exists, but it's not a file
                raise ConfigCreationException(self.file)
            fp = open(self.file, 'w')
            fp.close()

    def __setitem__(self, key, value):
        if not self.exists():
            raise ConfigNotCreatedException(self.file)
        key = key.strip()
        if key in self.data:
            self.data[key]['value'] = value
        else:
            obj = {'key': key, 'value': value}
            self.data[key] = obj
            self.lines.append(obj)

    set = __setitem__

    def keys(self):
        return self.data.keys()

    def __getitem__(self, key):
        return self.data[key.strip()]['value']

    def __delitem__(self, key):
        del self.data[key.strip()]

    def save(self):
        if not self.exists():
            raise ConfigNotCreatedException(self.file)
        fp = open(self.file, 'w')
        for item in self.lines:
            if isinstance(item, basestring):
                fp.write("%s\n" % item)
            elif isinstance(item, dict):
                fp.write("%s = %s\n" % (item['key'], item['value']))
        fp.close()

    def prompt(self, config_translation, args, defaults={}):
        # config_translation must be a list of 2-tuples
        # args must be a map of args, where keys match the first value
        # in the tuples, and values are strings
        # default must be a dict of fallback values
        self.load()

        for (argkey, confkey) in config_translation:
            value = self.get(confkey, None) or getattr(args, argkey, None)

            if value is None:
                # Not good. We must have these values. Prompt the user
                default = self.get(confkey)
                if default is None:
                    default = defaults.get(argkey)
                if default is not None:
                    value = raw_input(
                        "%s = [%s] " % (confkey, default)
                    ).strip()
                    if len(value) == 0:
                        value = default
                else:
                    value = raw_input("%s = " % confkey).strip()
            else:
                print("%s = %s" % (confkey, value))
            self.set(confkey, value)


class ConfigNotCreatedException(Exception):
    def __init__(self, filename):
        super(ConfigNotCreatedException, self).__init__(
            "File %s has not been created yet" % filename
        )


class ConfigCreationException(Exception):
    def __init__(self, filename):
        super(ConfigCreationException, self).__init__(
            "File %s can not be created" % filename
        )

# ------------------------------------------------------------------------------


# Gets a single character from standard input.  Does not echo to the screen.
class _Getch:
    def __init__(self):
        try:
            self.impl = _GetchWindows()
        except ImportError:
            self.impl = _GetchUnix()

    def __call__(self):
        return self.impl()


class _GetchUnix:
    def __init__(self):
        import tty  # NOQA
        import termios  # NOQA

    def __call__(self):
        import tty
        import termios
        fd = sys.stdin.fileno()
        old_settings = termios.tcgetattr(fd)
        try:
            tty.setraw(sys.stdin.fileno())
            ch = sys.stdin.read(1)
        finally:
            termios.tcsetattr(fd, termios.TCSADRAIN, old_settings)
        if ord(ch) == 3:
            raise KeyboardInterrupt
        return ch


class _GetchWindows:
    def __init__(self):
        import msvcrt  # NOQA

    def __call__(self):
        import msvcrt
        ch = msvcrt.getch()
        if ord(ch) == 3:
            raise KeyboardInterrupt
        return ch


getch = _Getch()


# ------------------------------------------------------------------------------


class VirtualEnv(object):

    def __init__(self, environment_dir=None):
        self.environment_dir = \
            environment_dir or os.path.join(MOXDIR, 'python-env')

        if os.path.isdir(self.environment_dir):
            print("Using virtual environment %r" % self.environment_dir)
        else:
            print("Creating virtual enviroment %r" % self.environment_dir)

            with _RedirectOutput(logfilename):
                sys.stdout.write('\n{}\nVENV: create {}\n\n'.format(
                    datetime.datetime.now(), self.environment_dir
                ))

                virtualenv.create_environment(self.environment_dir)

    @property
    def executable(self):
        # based on virtualenv.py
        return os.path.join(self.environment_dir, 'bin',
                            os.path.basename(sys.executable))

    def run(self, *args):
        run(self.executable, *args)

    def call(self, func, *args, **kwargs):
        '''Call the given function within this environment

        In order to avoid polluting global namespaces, the function is
        called in a subprocess.

        '''
        this_file = os.path.join(self.environment_dir,
                                 'bin', 'activate_this.py')

        def init(this_file):
            execfile(this_file, dict(__file__=this_file))

        pool = multiprocessing.Pool(1, init, (this_file,))

        return pool.apply(func, args, kwargs)

    def expand_template(self, *args, **kwargs):
        kwargs.setdefault('ENVDIR', self.environment_dir)
        kwargs.setdefault('PYTHON', os.path.join(
            self.environment_dir, 'bin',
            os.path.basename(sys.executable),
        ))

        return expand_template(*args, **kwargs)

    def add_moxlib_pointer(self):
        with open(
            "%s/lib/python2.7/site-packages/mox.pth" % self.environment_dir,
            "w"
        ) as fp:
            fp.write(os.path.abspath("%s/agentbase/python/mox" % MOXDIR))


class Apache(object):

    INCLUDE_BEGIN_MARKER = "### MOX INCLUDE BEGIN ###"
    INCLUDE_END_MARKER = "### MOX INCLUDE END ###"
    lines = []
    beginmarker_index = None
    endmarker_index = None
    indent = ''

    def __init__(self, siteconf=MOXDIR + "/apache/mox.conf"):
        assert os.path.isdir(os.path.dirname(siteconf)), siteconf
        self.siteconf = siteconf

    def load_config(self):
        self.lines = []
        with open(self.siteconf, 'r') as infile:
            for line in infile:
                self.lines.append(line)

        self.beginmarker_index = self.index(self.INCLUDE_BEGIN_MARKER)
        if self.beginmarker_index is not None:
            line = self.lines[self.beginmarker_index]
            self.indent = line[0:-len(line.lstrip())]
            self.endmarker_index = self.index(
                self.INCLUDE_END_MARKER, start=self.beginmarker_index
            )

    def save_config(self):
        if len(self.lines) > 0:
            with open(self.siteconf, 'w') as outfile:
                for line in self.lines:
                    outfile.write(line)
            sudo('apachectl', "graceful")

    def index(self, search, start=0, end=None):
        if end is None:
            end = len(self.lines) - 1
        search = search.strip()
        for index, line in enumerate(self.lines[start:end]):
            if line and line.strip() == search:
                return start + index
        return None

    def add_include(self, file, first=False):
        self.load_config()
        try:
            if self.beginmarker_index or self.endmarker_index:
                line = "%sInclude %s\n" % (self.indent, file)
                index = self.index(line)
                if index is None:
                    if self.endmarker_index and not first:
                        self.lines.insert(self.endmarker_index, line)
                    else:
                        self.lines.insert(self.beginmarker_index + 1, line)
        finally:
            self.save_config()


class WSGI(object):

    def __init__(self, wsgifile, conffile, virtualenv, user=None):
        self.virtualenv = virtualenv
        self.wsgifile = wsgifile
        self.conffile = conffile
        # FIXME: we use apache's mod_wsgi, so we can't actually change the user
        self.user = user

    def install(self, first_include=False):
        if self.user:
            create_user(self.user)

        self.virtualenv.expand_template(self.wsgifile)
        conffile = self.virtualenv.expand_template(self.conffile)

        Apache().add_include(conffile, first_include)


def install_dependencies(file):
    if os.path.isfile(file):
        with open(file, 'r') as fp:
            packages = fp.read().split()
            if packages:
                sudo('apt-get', '--yes', 'install', *packages)


class File(object):

    def __init__(self, filename):
        self.filename = filename

    def open(self, mode):
        return open(self.filename, mode)

    def touch(self):
        sudo('touch', self.filename)

    def chmod(self, mode):
        sudo('chmod', mode, self.filename)

    def chown(self, owner):
        sudo('chown', owner, self.filename)

    def chgrp(self, group):
        sudo('chgrp', group, self.filename)


class LogFile(File):
    def __init__(self, filename, user='mox', group='mox'):
        super(LogFile, self).__init__(filename)

        self.user = user
        self.group = group

    def create(self):
        create_user(self.user, self.group)

        self.touch()
        self.chmod('666')
        self.chown(self.user)
        self.chgrp(self.group)


class Folder(object):

    def __init__(self, foldername):
        self.foldername = foldername

    def isdir(self):
        return os.path.isdir(self.foldername)

    def mkdir(self):
        if not self.isdir():
            sudo('mkdir', '--parents', self.foldername)

    def chmod(self, mode):
        sudo('chmod', mode, self.foldername)

    def chown(self, owner):
        sudo('chown', owner, self.foldername)

    def chgrp(self, group):
        sudo('chgrp', group, self.foldername)


class Service(object):
    USE_SYSTEMD = (os.path.islink("/sbin/init") and
                   os.path.basename(os.readlink("/sbin/init")) == "systemd")

    def __init__(self, script, user='mox', group='mox', after=()):
        self.script = os.path.join(DIR, script)
        self.user = user
        self.group = group
        self.after = after

    @property
    def name(self):
        return os.path.basename(os.path.splitext(self.script)[0])

    def install(self):
        create_user(self.user, self.group)

        service_name = self.name + '.service'
        systemd_service = '/etc/systemd/system/{}.service'.format(self.name)
        upstart_config = '/etc/init/{}.conf'.format(self.name)

        if os.path.exists(upstart_config):
            try:
                sudo('service', self.name, 'stop')
            except subprocess.CalledProcessError:
                log('failed to stop upstart service', self.name)

            sudo('rm', '-v', upstart_config)

        if os.path.exists(systemd_service):
            try:
                sudo('systemctl', 'stop', service_name)
            except subprocess.CalledProcessError:
                log('failed to stop systemd service', self.name)

            sudo('rm', '-v', systemd_service)

        if self.USE_SYSTEMD:
            template = \
                os.path.join(MOXDIR,
                             'install/templates/systemd-agent.service.in')

            expand_template(template,
                            systemd_service,
                            NAME=self.name, SCRIPT=self.script,
                            USER=self.user, GROUP=self.group,
                            AFTER=self.after)

            sudo('systemctl', 'enable', service_name)
            sudo('systemctl', 'start', service_name)

        else:
            template = \
                os.path.join(MOXDIR,
                             'install/templates/upstart-agent.conf.in')

            expand_template(template, upstart_config,
                            PYTHON=VirtualEnv().executable,
                            NAME=self.name, SCRIPT=self.script,
                            USER=self.user, GROUP=self.group)

            sudo('service', self.name, 'start')


def expand_template(template_file, dest_file=None, **kwargs):
    if not dest_file:
        dest_file = os.path.splitext(template_file)[0]

    print('Expanding {!r} to {!r}'.format(template_file, dest_file))
    template_file = os.path.join(DIR, template_file)
    dest_file = os.path.join(DIR, dest_file)

    kwargs.setdefault('DIR', DIR)
    kwargs.setdefault('MOXDIR', MOXDIR)

    with open(template_file) as fp:
        template = jinja2.Template(fp.read())

    text = template.render(**kwargs)

    if os.path.exists(dest_file):
        backup_file = '{}-{}.bak'.format(dest_file, timestamp())

        try:
            os.rename(dest_file, backup_file)
        except:
            sudo('mv', '-v', dest_file, backup_file)

    try:
        with open(dest_file, 'w') as fp:
            fp.write(text)
    except IOError as exc:
        if exc.errno not in (errno.EPERM, errno.EACCES):
            raise

        sudo_with_input(text, 'dd', 'of=' + dest_file)

    return dest_file


def log(*args):
    with open(logfilename, 'a') as logfp:
        print(*args, file=logfp)
        logfp.flush()


def run(*args):
    with open(logfilename, 'a') as logfp:
        logfp.write('\n{}\nCMD: {}\n\n'.format(datetime.datetime.now(),
                                               ' '.join(args)))
        logfp.flush()

        subprocess.check_call(args, cwd=DIR,
                              stdout=logfp, stderr=logfp)


def sudo(*args):
    return sudo_with_input('', *args)


def sudo_with_input(data, *args):
    with tempfile.TemporaryFile() as inputfp:
        if data:
            inputfp.write(data)
            inputfp.seek(0)

        with open(logfilename, 'a') as logfp:
            logfp.write('\n{}\nSUDO: {}\n\n'.format(datetime.datetime.now(),
                                                    ' '.join(args)))
            logfp.flush()

            subprocess.check_call(('sudo',) + args, cwd=DIR,
                                  stdout=logfp, stderr=logfp, stdin=inputfp)


def create_user(user, group='mox'):
    try:
        pwd.getpwnam(user)
        print('Using pre-existing user {!r}'.format(user))
    except KeyError:
        print('Creating user {!r}'.format(user))
        sudo(
            'useradd', '--system',
            '-s', '/usr/sbin/nologin',
            '-g', group, user,
        )


def timestamp(dt=None):
    if not dt:
        dt = datetime.datetime.now()
    return '%04d%02d%02d-%02d%02d%02d' % (dt.year, dt.month, dt.day,
                                          dt.hour, dt.minute, dt.second)
