import os
import pwd
import shutil
import subprocess
import sys
import tempfile
import virtualenv

# ------------------------------------------------------------------------------

_basedir = os.path.dirname(os.path.dirname(os.path.realpath(
    os.path.splitext(__file__)[0] + '.py')
))


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


class Config(object):
    def __init__(self, file, create=True):
        self.file = file
        self.lines = []
        self.data = {}
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

    def set(self, key, value):
        if not self.exists():
            raise ConfigNotCreatedException(self.file)
        key = key.strip()
        if key in self.data:
            self.data[key]['value'] = value
        else:
            obj = {'key': key, 'value': value}
            self.data[key] = obj
            self.lines.append(obj)

    def get(self, key):
        try:
            return self.data[key.strip()]['value']
        except:
            return None

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
            value = None
            if hasattr(args, argkey):
                value = getattr(args, argkey)
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
                print "%s = %s" % (confkey, value)
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

    def __call__(self): return self.impl()


class _GetchUnix:
    def __init__(self):
        import tty
        import termios

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
        return ch


class _GetchWindows:
    def __init__(self):
        import msvcrt

    def __call__(self):
        import msvcrt
        return msvcrt.getch()

getch = _Getch()

# ------------------------------------------------------------------------------


class VirtualEnv(object):

    def __init__(self, environment_dir):
        self.environment_dir = environment_dir
        self.exists = os.path.isdir(self.environment_dir)

    def create(self, always_overwrite=False, never_overwrite=False,
               outfile=None):
        if os.path.isdir(self.environment_dir):
            self.exists = True
            if always_overwrite:
                create = True
            elif never_overwrite:
                create = False
            else:
                print "%s already exists" % self.environment_dir
                # raw_input("Do you want to reinstall it? (y/n)")
                print "Do you want to reinstall it? (y/n)",
                answer = None
                while answer != 'y' and answer != 'n':
                    answer = getch()
                create = (answer == 'y')
                print answer
            if create:
                shutil.rmtree(self.environment_dir)
        else:
            create = True

        if create:
            print "Creating virtual enviroment '%s'" % self.environment_dir
            with _RedirectOutput(outfile):
                virtualenv.create_environment(self.environment_dir)
            self.exists = True

        return create

    def run(self, args, outfile=None):
        # Warning: Be very sure what you put in commands,
        # since that gets executed in a shell
        if self.exists:
            # based on virtualenv.py
            pycmd = os.path.join(self.environment_dir, 'bin',
                                 os.path.basename(sys.executable))

            try:
                with _RedirectOutput(outfile):
                    output = subprocess.check_output([pycmd,] + args,
                                                     stderr=sys.stderr)
            except subprocess.CalledProcessError as e:
                return e.returncode

            return 0

    def add_moxlib_pointer(self):
        fp = open(
            "%s/lib/python2.7/site-packages/mox.pth" % self.environment_dir,
            "w"
        )
        fp.write(os.path.abspath("%s/agentbase/python/mox" % _basedir))
        fp.close()


class Apache(object):

    INCLUDE_BEGIN_MARKER = "### MOX INCLUDE BEGIN ###"
    INCLUDE_END_MARKER = "### MOX INCLUDE END ###"
    lines = []
    beginmarker_index = None
    endmarker_index = None
    indent = ''

    def __init__(self, siteconf=_basedir + "/apache/mox.conf"):
        assert os.path.isdir(_basedir + '/apache'), _basedir
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

    def __init__(self, wsgifile, conffile, user='mox',
                 wsgidir='/var/www/wsgi'):
        self.wsgifile = wsgifile
        self.conffile = conffile
        self.wsgidir = wsgidir
        # FIXME: we use apache's mod_wsgi, so we can't actually change the user
        self.user = user

    def _ensure_user(self):
        try:
            pwd.getpwnam(self.user)
        except KeyError:
            subprocess.check_call([
                'sudo', 'useradd', '--system',
                '-s', '/usr/sbin/nologin',
                '-g', 'mox', self.user,
            ])

    def _copy_files(self):
        destfile = os.path.join(self.wsgidir, os.path.basename(self.wsgifile))

        if not os.path.exists(self.wsgidir):
            subprocess.check_call(
                ['sudo', 'mkdir', "--parents", self.wsgidir]
            )

        with open(self.wsgifile) as fp:
            text = fp.read().replace('/srv/mox', _basedir)

        tempfd, tempfn = tempfile.mkstemp()

        try:
            os.write(tempfd, text)
            os.fsync(tempfd)
            os.close(tempfd)

            subprocess.check_call(
                ['sudo', 'install', '-m', '644', tempfn, destfile]
            )

        finally:
            os.remove(tempfn)

    def install(self, first_include=False):
        self._ensure_user()
        self._copy_files()
        Apache().add_include(self.conffile, first_include)
