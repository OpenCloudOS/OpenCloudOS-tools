# pygpgme - a Python wrapper for the gpgme library
# Copyright (C) 2006  James Henstridge
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA

"""Utilities related to editing keys.

Currently only contains a utility function for editing the owner trust
value of a key in a keyring.
"""

__metaclass__ = type

__all__ = ['edit_trust']

import os
import StringIO
import gpgme


class _EditData:
    """Simple base class to wrap 'edit key' interactions"""

    STATE_START = 0
    STATE_ERROR = -1

    def __init__(self):
        self.state = self.STATE_START
        self.transitions = {}
        # a default state transition to try and quit the edit on error
        self.addTransition(self.STATE_ERROR,
                           gpgme.STATUS_GET_LINE, 'keyedit.prompt',
                           self.STATE_ERROR, 'quit\n')

    def addTransition(self, state, status, args, newstate, data):
        self.transitions[state, status, args] = newstate, data

    def do_edit(self, ctx, key):
        output = StringIO.StringIO()
        ctx.edit(key, self.callback, output)

    def callback(self, status, args, fd):
        if status in (gpgme.STATUS_EOF,
                      gpgme.STATUS_GOT_IT,
                      gpgme.STATUS_NEED_PASSPHRASE,
                      gpgme.STATUS_GOOD_PASSPHRASE,
                      gpgme.STATUS_BAD_PASSPHRASE,
                      gpgme.STATUS_USERID_HINT,
                      gpgme.STATUS_SIGEXPIRED,
                      gpgme.STATUS_KEYEXPIRED,
                      gpgme.STATUS_PROGRESS,
                      gpgme.STATUS_KEY_CREATED,
                      gpgme.STATUS_ALREADY_SIGNED):
            return

        #print 'S: %s (%d)' % (args, status)

        if (self.state, status, args) in self.transitions:
            self.state, data = self.transitions[self.state, status, args]
            #print 'C: %r' % data
            if data is not None:
                os.write(fd, data)
        else:
            self.state = STATE_ERROR
            raise gpgme.error(gpgme.ERR_SOURCE_UNKNOWN, gpgme.ERR_GENERAL)


class _EditTrust(_EditData):
    # states
    STATE_COMMAND = 1
    STATE_VALUE   = 2
    STATE_CONFIRM = 3
    STATE_QUIT    = 4

    def __init__(self, trust):
        _EditData.__init__(self)

        self.addTransition(self.STATE_START,
                           gpgme.STATUS_GET_LINE, 'keyedit.prompt',
                           self.STATE_COMMAND, 'trust\n')

        self.addTransition(self.STATE_COMMAND,
                           gpgme.STATUS_GET_LINE, 'edit_ownertrust.value',
                           self.STATE_VALUE, '%d\n' % trust)

        self.addTransition(self.STATE_VALUE,
                           gpgme.STATUS_GET_LINE, 'keyedit.prompt',
                           self.STATE_QUIT, 'quit\n')

        self.addTransition(self.STATE_VALUE,
                           gpgme.STATUS_GET_BOOL, 'edit_ownertrust.set_ultimate.okay',
                           self.STATE_CONFIRM, 'Y\n')

        self.addTransition(self.STATE_CONFIRM,
                           gpgme.STATUS_GET_LINE, 'keyedit.prompt',
                           self.STATE_QUIT, 'quit\n')

        self.addTransition(self.STATE_QUIT,
                           gpgme.STATUS_GET_BOOL, 'keyedit.save.okay',
                           self.STATE_CONFIRM, 'Y\n')

class _EditSign(_EditData):
    # states
    STATE_UID = 1
    STATE_COMMAND = 2
    STATE_QUIT = 3

    def __init__(self, index, command, expire, check):
        _EditData.__init__(self)

        self.addTransition(self.STATE_START,
                           gpgme.STATUS_GET_LINE, 'keyedit.prompt',
                           self.STATE_UID, 'uid %d\n' % index)

        self.addTransition(self.STATE_UID,
                           gpgme.STATUS_GET_LINE, 'keyedit.prompt',
                           self.STATE_COMMAND, '%s\n' % command)

        self.addTransition(self.STATE_COMMAND,
                           gpgme.STATUS_GET_BOOL, 'keyedit.sign_all.okay',
                           self.STATE_COMMAND, 'Y\n')
        self.addTransition(self.STATE_COMMAND,
                           gpgme.STATUS_GET_LINE, 'sign_uid.expire',
                           self.STATE_COMMAND, '%s\n' % (expire and 'Y' or 'N'))
        self.addTransition(self.STATE_COMMAND,
                           gpgme.STATUS_GET_LINE, 'sign_uid.class',
                           self.STATE_COMMAND, '%d\n' % check)
        self.addTransition(self.STATE_COMMAND,
                           gpgme.STATUS_GET_BOOL, 'sign_uid.okay',
                           self.STATE_COMMAND, 'Y\n')
        self.addTransition(self.STATE_COMMAND,
                           gpgme.STATUS_GET_LINE, 'keyedit.prompt',
                           self.STATE_QUIT, 'quit\n')

        self.addTransition(self.STATE_QUIT,
                           gpgme.STATUS_GET_BOOL, 'keyedit.save.okay',
                           self.STATE_COMMAND, 'Y\n')


def edit_trust(ctx, key, trust):
    if trust not in (gpgme.VALIDITY_UNDEFINED,
                     gpgme.VALIDITY_NEVER,
                     gpgme.VALIDITY_MARGINAL,
                     gpgme.VALIDITY_FULL,
                     gpgme.VALIDITY_ULTIMATE):
        raise ValueError('Bad trust value %d' % trust)
    statemachine = _EditTrust(trust)
    statemachine.do_edit(ctx, key)

def edit_sign(ctx, key, index=0, local=False, norevoke=False,
              expire=True, check=0):
    """Sign the given key.

    index:    the index of the user ID to sign, starting at 1.  Sign all
               user IDs if set to 0.
    local:    make a local signature
    norevoke: make a non-revokable signature
    command:  the type of signature.  One of sign, lsign, tsign or nrsign.
    expire:   whether the signature should expire with the key.
    check:    Amount of checking performed.  One of:
                 0 - no answer
                 1 - no checking
                 2 - casual checking
                 3 - careful checking
    """
    if index < 0 or index > len(key.uids):
        raise ValueError('user ID index out of range')
    command = 'sign'
    if local:
        command = 'l%s' % command
    if norevoke:
        command = 'nr%s' % command
    if check not in [0, 1, 2, 3]:
        raise ValueError('check must be one of 0, 1, 2, 3')
    statemachine = _EditSign(index, command, expire, check)
    statemachine.do_edit(ctx, key)
