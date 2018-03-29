# battery-historian-docker

A docker image to run battery-historian, a tool to monitor your Android battery usage.

To run, execute:
`docker run -d -p 9999:9999 schumyhao/battery-historian`

You can then go to `http://localhost:9999` on your browser and upload your Android bugreports.

# How to take a bug report

To take a bug report from your Android device, you will need to enable USB debugging under `Settings > System > Developer Options`. On Android 4.2 and higher, the Developer options screen is hidden by default. You can enable this by following the instructions [here](<http://developer.android.com/tools/help/adb.html#Enabling>).

To obtain a bug report from your development device running Android 7.0 and
higher:

```
$ adb bugreport bugreport.zip
```

For devices 6.0 and lower:

```
$ adb bugreport > bugreport.txt
```

# Start analyzing!

You are all set now. Run `historian` and visit <http://localhost:9999> and
upload the `bugreport.txt` file to start analyzing.

# Advanced

To reset aggregated battery stats and history:

```
adb shell dumpsys batterystats --reset
```

## Wakelock analysis

By default, Android does not record timestamps for application-specific
userspace wakelock transitions even though aggregate statistics are maintained
on a running basis. If you want Historian to display detailed information about
each individual wakelock on the timeline, you should enable full wakelock
reporting using the following command before starting your experiment:

```
adb shell dumpsys batterystats --enable full-wake-history
```

Note that by enabling full wakelock reporting the battery history log overflows
in a few hours. Use this option for short test runs (3-4 hrs).

## Kernel trace analysis

To generate a trace file which logs kernel wakeup source and kernel wakelock
activities:

First, connect the device to the desktop/laptop and enable kernel trace logging:

```
$ adb root
$ adb shell

# Set the events to trace.
$ echo "power:wakeup_source_activate" >> /d/tracing/set_event
$ echo "power:wakeup_source_deactivate" >> /d/tracing/set_event

# The default trace size for most devices is 1MB, which is relatively low and might cause the logs to overflow.
# 8MB to 10MB should be a decent size for 5-6 hours of logging.

$ echo 8192 > /d/tracing/buffer_size_kb

$ echo 1 > /d/tracing/tracing_on
```

Then, use the device for intended test case.

Finally, extract the logs:

```
$ echo 0 > /d/tracing/tracing_on
$ adb pull /d/tracing/trace <some path>

# Take a bug report at this time.
$ adb bugreport > bugreport.txt
```

Note:

Historian plots and relates events in real time (PST or UTC), whereas kernel
trace files logs events in jiffies (seconds since boot time). In order to relate
these events there is a script which approximates the jiffies to utc time. The
script reads the UTC times logged in the dmesg when the system suspends and
resumes. The scope of the script is limited to the amount of timestamps present
in the dmesg. Since the script uses the dmesg log when the system suspends,
there are different scripts for each device, with the only difference being
the device-specific dmesg log it tries to find. These scripts have been
integrated into the Battery Historian tool itself.

## Power monitor analysis

Lines in power monitor files should have one of the following formats, and the
format should be consistent throughout the entire file:

```
<timestamp in epoch seconds, with a fractional component> <amps> <optional_volts>
```

OR

```
<timestamp in epoch milliseconds> <milliamps> <optional_millivolts>
```

Entries from the power monitor file will be overlaid on top of the timeline
plot.

To ensure the power monitor and bug report timelines are somewhat aligned,
please reset the batterystats before running any power monitor logging:

```
adb shell dumpsys batterystats --reset
```

And take a bug report soon after stopping power monitor logging.

If using a Monsoon:

Download the AOSP Monsoon Python script from <https://android.googlesource.com/platform/cts/+/master/tools/utils/monsoon.py>

```
# Run the script.
$ monsoon.py --serialno 2294 --hz 1 --samples 100000 -timestamp | tee monsoon.out

# ...let device run a while...

$ stop monsoon.py
```

## Modifying the proto files

If you want to modify the proto files (pb/\*/\*.proto), first download the
additional tools necessary:

Install the standard C++ implementation of protocol buffers from <https://github.com/google/protobuf/blob/master/src/README.md>

Download the Go proto compiler:

```
$ go get -u github.com/golang/protobuf/protoc-gen-go
```

The compiler plugin, protoc-gen-go, will be installed in $GOBIN, which must be
in your $PATH for the protocol compiler, protoc, to find it.

Make your changes to the proto files.

Finally, regenerate the compiled Go proto output files using `regen_proto.sh`.

## Other command line tools

```
# System stats
$ go run cmd/checkin-parse/local_checkin_parse.go --input=bugreport.txt

# Timeline analysis
$ go run cmd/history-parse/local_history_parse.go --summary=totalTime --input=bugreport.txt

# Diff two bug reports
$ go run cmd/checkin-delta/local_checkin_delta.go --input=bugreport_1.txt,bugreport_2.txt
```
