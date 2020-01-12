A few buttons and LEDs
=====================

I tried it, too. Many did before. To connect a few buttons to a µC with an ADC
on one pin, and the button-in-parallel-to-LED magic (two in this case). This
makes one pin for a 4x dip switch + another two pins for two LEDs and one
button.

Thanks to the guys from mikrocontroller.net for the idea and Peter Dannegger for
trying it before me (he came up with the analog comparator approach, I think).
Have a look at their forum, they have incredible stuff there (i.e. Peter's key
debounce routine): https://www.mikrocontroller.net/topic/77617 ,
https://www.mikrocontroller.net/topic/77863 .

The ADC approach can actually be found all over the place ;-) .
I did a small python script for computing the resistors, feel free to use it
(sorry I did not assign a license or something, just too lazy ...).

 \- Thomas Erbesdobler <t.erbesdobler@gmx.de>
