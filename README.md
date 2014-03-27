# behavd

A MacOS X utility to make the Android Emulator behave correctly.

The idea appeared when discovering that a commute that used to consume 25% of the battery had turned into a nightmare depleting it.

After checking the Activity Monitor and finding the culprit I had to scratch that itch in a manner that didn't imply having to close the emulator or managing it from the command line.

behavd resides in your menubar and detects when the Android Emulator loses focus. In that moment it sends it a SIGSTOP. When Android Emulator gains focus again it sends it a SIGCONT.

Future versions will probably implement an AVD manager of sorts.

---

## behave /bɪˈheɪv/

vb

*behave* (third-person singular simple present _behaves_, present participle _behaving_, simple past and past participle _behaved_)

1. (reflexive) To conduct (oneself) well, or in a given way.
2. (intransitive) To act, conduct oneself in a specific manner; used with an adverbial of manner.
3. (obsolete, transitive) To conduct, manage, regulate (something).
4. (intransitive) To act in a polite or proper way.

Source: [Wiktionary](http://en.wiktionary.org/wiki/behave)

---

## AVD

ABBREVIATION FOR

> Android Virtual Devices

An Android Virtual Device (AVD) is an emulator configuration that lets you model an actual device by defining hardware and software options to be emulated by the Android Emulator.

Source: [Android Developer Reference](http://developer.android.com/tools/devices/index.html)
