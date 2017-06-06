<p align="center"><img src="http://i.imgur.com/zlPQGJ4.jpg" alt="JCAP" align="center"></p>

<h1>What is it?</h1>
<p>The purpose of JCAP is to develop a <a href="https://www.jammaboards.com/jcenter_jammaFAQ.html">JAMMA arcade standard</a> compatible game board using the <a href="https://www.parallax.com/product/p8x32a-q44">Parallax Propeller 1 (P8A32X) microcontroller</a> upon which a user can implement their own custom arcade game, either from scratch or by using the library of graphics, sound, input, and other drivers developed under the project. Ultimately, the project will provide:</p>

* VGA video driver
* Sprite/tile based graphics driver
* PWM sound driver
* Serialized input driver
* Game engine
* PCB schematic and CAD files

in such a way that a user has everything they need to implement their own arcade game and have a PCB printed to build it on.

<h1>The JAMMA Standard</h1>

<p>The JAMMA standard itself is defined by a specific pinout, however the use of some or all of the signals is dependant on a given game board's configuration:</p>

<p align="center"><img src="http://www.coinplaysa.com/images/Gamma.jpg" alt="JAMMA pinout" align="center"></p>

<h1>The Propeller 1</h1>

<p>The P8X32A is an impressive 8-core microcontroller programmed using either a high-level proprietary language called <a href="http://learn.parallax.com/projects/propeller-spin-language">Spin<a>, or a form of assembly called <a href="https://lamestation.atlassian.net/wiki/display/PASM/Propeller+Assembly+Manual+Home">PASM</a>. A very large array of standard programming languages are also able to be compiled for the Propeller, most notably <a href="http://learn.parallax.com/tutorials/propeller-c">C</a>. 

The P8X32A works by implementing a round-robin exlusive resource access methodology via a rotating "hub", which switches shared resource access between each of the 8 individual processors, called "cogs":

<p align="center"><img src="http://demin.ws/blog/english/2012/11/22/personal-mini-computer-on-parallax-propeller/propeller-block-large.jpg" alt="P8X32A" align="center"></p>

The most significant benefit of using the Propeller as the backbone for JCAP is its implementation of video generation hardware within each cog. This reduces development time, and introduces a level of security and confidence in the hardware concerning the ablity to generate a VGA and/or composite TV video signal:

<p align="center"><img src="https://i.stack.imgur.com/MErlN.jpg" align="center"></p>
</p>
