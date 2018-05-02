<h1 align="center"><img src="http://i.imgur.com/zlPQGJ4.jpg" alt="JCAP" align="center"></h1>

<hr>

<p align="center"><b>Check out the <a href="https://github.com/cspang1/JCAP/wiki">Project Wiki</a> for the development log</b></p> 

<hr>

<p><b><u>JCAP</u></b> is a project with the goal of developing a <a href="https://www.jammaboards.com/jcenter_jammaFAQ.html">JAMMA arcade standard</a> compatible game board using the <a href="https://www.parallax.com/product/p8x32a-q44">Parallax Propeller 1 (P8X32A) microcontroller</a> upon which a user can implement their own custom arcade game, either from scratch or by using the library of graphics, sound, input, and other drivers developed under the project. Ultimately, the project will provide:</p>

<ul>
  <li>VGA video driver</li>
  <li>Sprite/tile based graphics driver</li>
  <li>PWM sound driver</li>
  <li>Serialized input driver</li>
  <li>Game engine</li>
  <li>PCB schematic and CAD files</li>
</ul>

<p>in such a way that a user has everything they need to implement their own arcade game and have a PCB printed to build it on.</p>

<h1 align="center">The JAMMA Standard</h1>

<p>The JAMMA standard itself is defined by a specific pinout, however the use of some or all of the signals is dependant on a given game board's configuration:</p>

<p align="center"><img src="http://www.coinplaysa.com/images/Gamma.jpg" alt="JAMMA pinout" align="center"></p>

<h1 align="center">The Propeller 1</h1>

<p>The P8X32A is an impressive 8-core microcontroller programmed using either a high-level proprietary language called <a href="http://learn.parallax.com/projects/propeller-spin-language">Spin</a>, or a form of assembly called <a href="https://lamestation.atlassian.net/wiki/display/PASM/Propeller+Assembly+Manual+Home">PASM</a>. A very large array of standard programming languages are also able to be compiled for the Propeller, most notably <a href="http://learn.parallax.com/tutorials/propeller-c">C</a>.</p>

<p>The P8X32A works by implementing a round-robin exlusive resource access methodology via a rotating "hub", which switches shared resource access between each of the 8 individual processors, called "cogs":</p>

<p align="center"><img src="http://demin.ws/blog/english/2012/11/22/personal-mini-computer-on-parallax-propeller/propeller-block-large.jpg" alt="P8X32A" align="center"></p>

<p>The most significant benefit of using the Propeller as the backbone for JCAP is its implementation of video generation hardware within each cog. This reduces development time, and introduces a level of security and confidence in the hardware concerning the ablity to generate a VGA and/or composite TV video signal:</p>

<p align="center"><img src="https://i.stack.imgur.com/MErlN.jpg" align="center"></p>

<h1 align="center">Dependencies</h1>
<p>The following items are required to develop on the JCAP framework:</p>

<ul>
  <li><a href="https://www.parallax.com/downloads/propeller-tool-software-windows">Propeller Tool IDE</a></li>
  <li><a href="https://www.parallax.com/product/32201">Propeller Plug</a> (or a serial data circuit of your own making)</li>
</ul>

<p>The following items are useful but not necessary for development:</p>

<ul>
  <li><a href="http://www.terasic.com.tw/cgi-bin/page/archive.pl?Language=English&No=593">DE0-Nano FPGA Development and Education Board</a></li>
  <li><a href="https://www.altera.com/downloads/download-center.html">Quartus Prime</a> (for programming DE0-Nano with open-source P8X32A design)</li>
  <li><a href="http://store.digilentinc.com/analog-discovery-100msps-usb-oscilloscope-logic-analyzer-limited-time/">Analog Discovery logic analyzer</a> and <a href="http://store.digilentinc.com/waveforms-2015-download-only/">WaveForms software</a></li>
</ul>

<h1 align="center">Documentation</h1>
<p>The source code documentation for JCAP is written in-line and strives to be extensively detailed. There are however several external documents useful to developing for JCAP (all are included in the Docs/ directory):</p>

<ul>
  <li><a href="https://www.parallax.com/sites/default/files/downloads/P8X32A-Web-PropellerManual-v1.2.pdf">Propeller 1 (P8X32A) Manual</a></li>
  <li><a href="https://cdn.sparkfun.com/datasheets/Dev/Propeller/Propeller-P8X32A-Datasheet-v1.4.0_1.pdf">Propeller 1 (P8X32A) Datasheet</a></li>
  <li><a href="https://www.terasic.com.tw/cgi-bin/page/archive_download.pl?Language=English&No=593&FID=75023fa36c9bf8639384f942e65a46f3">DE0-Nano Manual</a></li>
  <li><a href="https://www.parallax.com/sites/default/files/downloads/60056-Setup-the-Propeller-1-Design-on-a-DE0-Nano-v1.2.pdf">Loading P8X32A onto DE0-Nano</a></li>
  <li><a href="https://www.parallax.com/sites/default/files/downloads/32360-Hydra-Game-Dev-Manual-v1.0.1.pdf">HYDRA Game Development Manual</a> (inspiration for majority of JCAP hardware and drivers)</li>
</ul>

<h1 align="center">Contribution Guidelines</h1>
<p>On the off chance anyone is interested in contributing to JCAP, there are some basic standards which should be ahered to:</p>

<ol>
  <li>Document everything! For code documentation, use existing code (e.g. Dev/Input/Software/input.spin) as an example. PASM should be documented somewhat anal-retentively, line-by-line, with block comments for routines and subroutines. Header comments should follow the same standard established by existing code as well.</li>
  <li>Any discovered problems/concerns/features that you won't be addressing with your current commit need to have an issue created and assigned to the appropriate person(s), tag, milestone, and project. This eliminates the risk of development amnesia. Additionally, when a commit has satisfied an issue, the commit hash should be referenced in the closing comment of the issue.</li>
  <li>Commit messages need to at a minimum broadly describe each change made to the repository. Whether it's fixing a bug, adding a feature, adding a new datasheet, or updating some indentation, one should be able to read the commit message and understand immediately what's been done to the repo.</li>
  <li>Any documents (manuals, datasheets, tutorials) which are critical to your contributions should be placed in their appropriate subdirectories in /Docs. For similarly important generic links, place them in "Useful Links.txt" in /Docs.</li>
</ol>

<p>Pull requests that don't follow these guidelines will be rejected until corrections have been made. While this all may seem like an over-processed waste of time, an auxiliary goal for JCAP is to create a project which maintains the highest possible standards to prevent headache down the road and belay confusion to anyone on the outside looking in.</p>

<h1 align="center">Current Contributors</h1>
<p>The following individuals have contributed to JCAP:</p>

<ul>
  <li>Connor Spangler (cspang1): cspang1@vt.edu</li>
  <li>Marko Lukat (konimaru)</li>
</ul>
