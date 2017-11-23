#!/usr/bin/env python

import subprocess, gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk

class BrightnessScale:
    def __init__(self):
        # get active monitor and current brightness
        self.monitors = self.getActiveMonitors()
        self.currBs = self.getCurrentBrightnesses()

    def initUI(self):
        # initliaze and configure window 
        window = Gtk.Window()
        window.connect("destroy", lambda w: Gtk.main_quit())
        window.set_title('pyRandr Brightness Adjuster          --by DrCat')
        window.set_position(Gtk.WindowPosition.CENTER)
        window.set_border_width(10)

        grid = Gtk.Grid()
        window.add(grid)
        sizer = Gtk.Label(label="                                                                                                        ");
        grid.attach(sizer, 1, 0, 1, 2);

        for k, monitor in enumerate(self.monitors):
            grid.attach(Gtk.Label(label=monitor), 0, k+1, 1, 1);
            scale = Gtk.HScale();
            scale = Gtk.HScale();
            scale.connect("value-changed", self.scale_moved, scale, k)

            adjustment = Gtk.Adjustment(self.currBs[k], 20, 200, 1, 10, 0)
            scale.set_adjustment(adjustment)
            grid.attach(scale, 1, k+1, 1, 1);

        # close Gtk thread on closing window
        window.connect("destroy", lambda w: Gtk.main_quit())

        window.show_all()

        # close window on pressing escape key
        accGroup = Gtk.AccelGroup()
        key, modifier = Gtk.accelerator_parse('Escape')
        accGroup.connect(key, modifier, Gtk.AccelFlags.VISIBLE, Gtk.main_quit)
        window.add_accel_group(accGroup)

    def scale_moved(self, event, *data):
        monitor = self.monitors[data[1]];
        scale = data[0];
        #Change brightness
        newBrightness = float(scale.get_value())/100
        cmd = "xrandr --output %s --brightness %.2f" % (monitor, newBrightness)
        cmdStatus = subprocess.check_output(cmd, shell=True)

    def showErrDialog(self):
        self.errDialog = Gtk.MessageDialog(None, 
                                           Gtk.DialogFlags.MODAL,
                                           Gtk.MessageType.ERROR,
                                           Gtk.ButtonsType.OK,
                                           "Unable to detect active monitor, run 'xrandr --verbose' on command-line for more info")
        self.errDialog.set_title("brightness control error")
        self.errDialog.run()
        self.errDialog.destroy()

    def initStatus(self):
        if(self.monitors == "" or self.currBs == ""):
            return False
        return True

    def getActiveMonitor(self):
        #Find display monitor
        monitor = subprocess.check_output("xrandr -q | grep ' connected' | cut -d ' ' -f1", shell=True)
        if(monitor != ""):
            monitor = monitor.split('\n')[0]
        return monitor

    def getActiveMonitors(self):
        #Find display monitor
        monitors = subprocess.check_output("xrandr -q | grep ' connected' | cut -d ' ' -f1", shell=True)
        if(monitors != ""):
            monitors = monitors.split('\n')
            while monitors[len(monitors) -1] == '': monitors.pop();

        return monitors


    def getCurrentBrightnesses(self):
        #Find current brightness
        currB = subprocess.check_output("xrandr --verbose | grep -i brightness | cut -f2 -d ' '", shell=True)
        if(currB != ""):
            currB = currB.split('\n')
            for i, val in enumerate(currB):
                if (val != ""):
                    currB[i] = int(float(val) * 100)
        else:
            currB = ""

        return currB

    def getCurrentBrightness(self):
        #Find current brightness
        currB = subprocess.check_output("xrandr --verbose | grep -i brightness | cut -f2 -d ' '", shell=True)
        if(currB != ""):
            currB = currB.split('\n')[0]
            currB = int(float(currB) * 100)
        else:
            currB = ""
        return currB

if __name__ == "__main__":
    # new instance of BrightnessScale
    brcontrol = BrightnessScale()
    if(brcontrol.initStatus()):
        # if everything ok, invoke UI and start Gtk thread loop
        brcontrol.initUI()
        Gtk.main()
    else:
        # show error dialog
        brcontrol.showErrDialog()
