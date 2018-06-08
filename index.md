![](/images/HED_connected_logo_100.png)

HED tags are assigned to event codes (also known as triggers or event numbers) in EEG recordings and allow humans and computers to better understand what these codes represent (e.g. code #5 -> Target detection in an RSVP paradigm). [Click here](/interactive) to see an interactive visualization of HED hierarchy (note: it shows an an older version of HED schema). The latest version of the schema is available [here](http://www.hedtags.org/schema) in wiki format.

<a href="http://netdb1.cs.utsa.edu/hed"> <button name="button">Online HED validator</button></a>

[<img src="/images/HED_tree_brief.png">](/interactive)
===

## Why tags?

In the same way that we tag a picture on Flicker, or a video clip on Youtube (e.g. cat, cute, funny), we can tag EEG experimental event types used in event-related EEG research. Hierarchical Event Descriptors (HED) is a set of descriptor tags partially adopted from BrainMap/NeuroLex ontologies and organized hierarchically. HED tags can be used to describe many types of EEG experiment events in a uniform, extensible, and machine readable manner.

## How do I start?
Follow these steps:

1. Read [HED Schema](http://www.hedtags.org/schema). It contains all tags in the HED hierarchy.  
2. Read [HED reference paper](http://journal.frontiersin.org/article/10.3389/fninf.2016.00042/full).  
3. Read [HED Tagging Strategy Guide](http://www.hedtags.org/downloads/HED%20Tagging%20Strategy%20Guide.pdf)
4. Read about CTAGGER GUI-based HED tagging ([MATLAB](https://github.com/VisLab/HEDTools/blob/master/matlab/documentation/HEDToolsUserManual.pdf)).  

## Tools

1.Tools supporting HED tagging can be found at: [HED Tools](https://github.com/VisLab/HEDTools). The repository organizes the tools by language, so the [matlab](https://github.com/VisLab/HEDTools/tree/master/matlab) subdirectory contains HED tools for MATLAB. This repository also contains a zip file ready for installation as an EEGLAB plugin in the [eeglabplugin](https://github.com/VisLab/HEDTools/tree/master/EEGLABPlugin) directory.  
2. [rERP Toolbox](http://sccn.ucsd.edu/wiki/EEGLAB/RERP) is an open source Matlab toolbox for calculating overlapping Event Related Potentials (ERP) by multiple regression (an alternative to averaging). It can also perform regression on HED tags.  
3. [Interactive visualization of HED hierarchy](/interactive) in your web browser.

## Who is using HED tags?

* [National Database for Autism Research (NDAR)](http://ndar.nih.gov/)
* [CaN-CTA project of Army Research Labaratory](http://cancta.net)
* [EEG Study Schema (ESS)](http://www.eegstudy.org)
* [HeadIT.org](http://HeadIT.org)

## People

* Nima Bigdely-Shamlo ([Qusp](http://www.qusp.io))
* Kay Robbins ([University of Texas San Antonio](https://www.utsa.edu/))
* Scott Makeig ([Swartz Center, UCSD](http://sccn.ucsd.edu)).
* Jeremy Cockfield ([University of Texas San Antonio](https://www.utsa.edu/))
* Christian Kothe ([Qusp](http://www.qusp.io)).
* Makoto Miyakoshi ([Swartz Center, UCSD](http://sccn.ucsd.edu)).

and many others.

## Institutions

<div width = "100%"  align = "center" style="float:center">
<img src="http://bigeegconsortium.github.io/combined_logos_2.png" align="center" >
</div>

- [Intheon Labs](https://intheon.io)
- [University of Texas at San Antonio](http://visual.cs.utsa.edu/)
- [Swartz Center for Computational Neuroscience, University of California, San Diego](http://sccn.ucsd.edu)

***

HED was originally developed under HeadIT project at Swartz Center for Computational Neuroscience (SCCN) of the University of California, San Diego and funded by U.S. National Institutes of Health grants R01-MH084819 (Makeig, Grethe PIs) and R01-NS047293 (Makeig PI). HED development is now supported by The Cognition and Neuroergonomics Collaborative Technology Alliance (CaN CTA) program of U.S Army Research Laboratory (ARL).
<div width = "100%">
<div width = "100%" align = "center" style="float:left">
<a href="http://www.arl.army.mil/"  align="center"><img src="/images/ARL_logo.png" align="centeer" height="50px" ></a>
</div>
</div>
<p/>
