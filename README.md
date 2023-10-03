<h1 align="center"><img src="http://i.imgur.com/zlPQGJ4.jpg" alt="JCAP" align="center"></h1>

<p align="center"><b>Check out the <a href="https://github.com/cspang1/JCAP/wiki">Project Wiki</a> for the development log</b></p> 
<p align="center"><b>A custom game resource creation software suite <a href="https://github.com/cspang1/jide">is being developed</a> for the inaugural JCAP release!</b></p> 

<hr>

<p>JCAP is a project with the goal of developing a <a href="https://www.mikesarcade.com/cgi-bin/spies.cgi?action=url&type=pinout&page=Jamma.html">JAMMA arcade standard</a> compatible game board using the <a href="https://www.parallax.com/product/p8x32a-q44">Parallax Propeller 1 (P8X32A) microcontroller</a> upon which a user can implement their own custom arcade game, either from scratch or by using the library of graphics, sound, input, and other drivers developed under the project. Ultimately, the project will provide all of the following in such a way that a user has everything they need to implement their own arcade game and have a PCB printed to build it on:</p>

<ul>
  <li>VGA video driver</li>
  <li>Sprite/tile based graphics driver</li>
  <li>PWM sound driver</li>
  <li>Serialized input driver</li>
  <li>Game engine</li>
  <li>Board schematic</li>
  <li>PCB .gerber files</li>
  <li>PCB BOM</li>
</ul>

<p align="center"><img src="https://i.imgur.com/MyBgdcr.png" alt="JCAP Dev PCB" align="center"></p>

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
  <li>Connor Spangler (cspang1)</li>
  <li>Marko Lukat (konimaru)</li>
</ul>
