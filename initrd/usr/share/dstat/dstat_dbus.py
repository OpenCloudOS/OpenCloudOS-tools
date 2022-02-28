### Author: Dag Wieers <dag$wieers,com>

class dstat_plugin(dstat):
    """
    Number of active dbus sessions.
    """

    def __init__(self):
        self.name = 'dbus'
        self.type = 'd'
        self.width = 3
        self.scale = 100
        self.nick = ('sys', 'ses')
        self.vars = ('system', 'session')

    def check(self):
#       dstat.info(1, 'The dbus module is an EXPERIMENTAL module.')
        try:
            global dbus
            import dbus
        except:
            raise Exception, 'Needs python-dbus module'
        try:
            self.sysbus = dbus.Interface(dbus.SystemBus().get_object('org.freedesktop.DBus', '/org/freedesktop/DBus'), 'org.freedesktop.DBus')
        except:
            raise Exception, 'Unable to connect to dbus message bus'
        try:
            self.sesbus = dbus.Interface(dbus.SessionBus().get_object('org.freedesktop.DBus', '/org/freedesktop/DBus'), 'org.freedesktop.DBus')
        except:
            self.sesbus = None

        return True

    def extract(self):
        self.val['system'] = len(self.sysbus.ListNames()) - 1
        try:
            self.val['session'] = len(self.sesbus.ListNames()) - 1
        except:
            self.val['session'] = -1
#       print dir(b); print dir(s); print dir(d); print d.ListServices()
#       print dir(d)
#       print d.ListServices()

# vim:ts=4:sw=4:et
