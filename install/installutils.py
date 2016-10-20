#!/usr/bin/python

import os
import shutil
import subprocess
import random

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
            fp = open(file, 'r')
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
            if os.path.exists(self.file): # The path exists, but it's not a file
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


class ConfigNotCreatedException(Exception):
    def __init__(self, filename):
        super(ConfigNotCreatedException, self).__init__("File %s has not been created yet" % filename)

class ConfigCreationException(Exception):
    def __init__(self, filename):
        super(ConfigCreationException, self).__init__("File %s can not be created" % filename)

#-------------------------------------------------------------------------------

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
        import tty, sys

    def __call__(self):
        import sys, tty, termios
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

#-------------------------------------------------------------------------------

class VirtualEnv(object):

    def __init__(self, environment_dir):
        self.environment_dir = environment_dir
        self.exists = os.path.isdir(self.environment_dir)

    def create(self, always_overwrite=False, never_overwrite=False):
        if os.path.isdir(self.environment_dir):
            self.exists = True
            if always_overwrite:
                shutil.rmtree(self.environment_dir)
                create = True
            elif never_overwrite:
                create = False
            else:
                print "%s already exists" % self.environment_dir
                # raw_input("Do you want to reinstall it? (y/n)")
                print "Do you want to reinstall it? (y/n)"
                answer = None
                while answer != 'y' and answer != 'n':
                    answer = getch()
                create = (answer == 'y')
        else:
            create = True

        if create:
            print "Creating virtual enviroment '%s'" % self.environment_dir
            subprocess.call(['virtualenv', self.environment_dir])
            self.exists = True

        return create

    def run(self, *commands):
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
            for stdout_line in stdout_lines:
                print stdout_line,

            process.stdout.close()
            return_code = process.wait()
            return return_code