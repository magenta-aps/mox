#!/usr/bin/python

import os
import shutil
import subprocess
import random
import sys

# ------------------------------------------------------------------------------


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
            fp = open(outfile, 'a') if outfile else None
            subprocess.call(
                ['virtualenv', self.environment_dir], stdout=fp, stderr=fp
            )
            self.exists = True

        return create

    def run(self, outfile=None, *commands):
        # Warning: Be very sure what you put in commands,
        # since that gets executed in a shell
        if self.exists:
            while True:
                filename = "/tmp/foo.%d" % random.randint(0, (2**32)-1)
                if not os.path.isfile(filename):
                    break
            with open(filename, 'w') as file:
                file.write("#!/bin/bash\n")
                file.write("source %s/bin/activate\n" % self.environment_dir)
                for command in commands:
                    file.write("%s\n" % command)
                file.write("deactivate\n")
                file.close()
            os.chmod(filename, 0755)
            process = subprocess.Popen(
                filename, shell=True,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                universal_newlines=True
            )
            stdout_lines = iter(process.stdout.readline, "")
            fp = None
            if outfile is not None:
                fp = open(outfile, 'a')
            for stdout_line in stdout_lines:
                if fp:
                    fp.write(stdout_line)
                else:
                    print stdout_line,

            process.stdout.close()
            if fp:
                fp.close()
            return_code = process.wait()

            os.remove(filename)
            return return_code

    def add_moxlib_pointer(self, moxdir):
        fp = open(
            "%s/lib/python2.7/site-packages/mox.pth" % self.environment_dir,
            "w"
        )
        fp.write(os.path.abspath("%s/agentbase/python/mox" % moxdir))
        fp.close()


class Apache(object):

    INCLUDE_BEGIN_MARKER = "### MOX INCLUDE BEGIN ###"
    INCLUDE_END_MARKER = "### MOX INCLUDE END ###"
    lines = []
    beginmarker_index = None
    endmarker_index = None
    indent = ''

    def __init__(self, siteconf="/srv/mox/apache/mox.conf"):
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

    def __init__(self, wsgifile, conffile, wsgidir='/var/www/wsgi'):
        self.wsgifile = wsgifile
        self.conffile = conffile
        self.wsgidir = wsgidir

    def install(self, first_include=False):
        if not os.path.exists(self.wsgidir):
            subprocess.Popen(
                ['sudo', 'mkdir', "--parents", self.wsgidir]
            ).wait()
        subprocess.Popen(
            ['sudo', 'cp', '--remove-destination', self.wsgifile, self.wsgidir]
        ).wait()
        Apache().add_include(self.conffile, first_include)
