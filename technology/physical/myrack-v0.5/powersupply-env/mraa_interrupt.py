#!/usr/bin/env python

#http://www.ganssle.com/debouncing-pt2.htm

import mraa
import time
import datetime #timedelta
from systemdream import journal #virtualenv-capable systemd journal (only journal!) Python code

import signal
import sys

import yaml #pyyaml

with open("config.yml", "r") as configfile:
    cfg = yaml.load(configfile)

if ( cfg['debounce_strategy'] is not 'seconds' ):
   journal.send('Setting debounce_strategy to seconds.')
   cfg['debounce_strategy'] = 'seconds' # ;)

#grey
a = mraa.Gpio(18)
a.dir(mraa.DIR_OUT)
a.write(0)

#there was something about basic types not available within interrupts
#although the codes worked fine I still rather use the suggested workaround of a class
class Button20():
  pressed = False
  pressed_debounced = False

button20 = Button20()

def handleInterrupt(args):
    #print("handleInterrupt")
    button20.pressed = True #that's a fact, but...
    button20.pressed_debounced = False
    interrupted_at = datetime.datetime.now()

    if ( cfg['debounce_strategy'] == 'seconds' ):
        debounce_until = interrupted_at + datetime.timedelta(0,3)
    else: # fixme implement counter or other
        debounce_until = interrupted_at + datetime.timedelta(0,3)

    #print(interrupted_at,debounce_until,button20.pressed)
    journal.send('Button on GPIO20 pressed, not debounced yet.', FIELD2='GPIO20')

    # simple loop instead of interrupting for the other edge
    # no hint of electromagnetical interference on the GPIOs (yet)
    # so a triggered interrupt seems to corelate strongly with a human interaction
    while True:
      if (datetime.datetime.now() > debounce_until):
          #print("past debounce")
          journal.send('Button on GPIO20 pressed, DEBOUNCED.', FIELD2='GPIO20')
          button20.pressed_debounced = True
          return
      elif ( b.read() == 1 ): #was released
          #print("prematurely released")
          journal.send('Button on GPIO20 pressed, prematurely released.', FIELD2='GPIO20')
          return
      else:
          #print("not debounced yet")
          journal.send('Button on GPIO20 pressed, not debounced yet.', FIELD2='GPIO20')
      time.sleep(0.5) #inside this interrupt handler only

#white
b = mraa.Gpio(20)
b.dir(mraa.DIR_IN)
b.isr(mraa.EDGE_FALLING, handleInterrupt, handleInterrupt)

#https://nattster.wordpress.com/2013/06/05/catch-kill-signal-in-python/
#systemd sends a SIGTERM on stop
#ToDo do something useful
def signal_term_handler(signal, frame):
    #print('SIGTERM received')
    journal.send('SIGTERM received.')
    sys.exit(0)

signal.signal(signal.SIGTERM, signal_term_handler)

try:
  while True:
    #print(a.read())
    #print(b.read())
    time.sleep(10)
except KeyboardInterrupt:
    print('Ctrl-C received.')
    journal.send('Ctrl-C received.')
    #a.mraa_gpio_close()
    #a.close()
