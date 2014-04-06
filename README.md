# FDockHx

At the begining it was a tutorial written for [Flash&Flex Developper's magazine](http://www.ffdmag.com/) in 2008 :

![Magazine](http://mromecki.fr/blog/post/35/pic2.jpg)

It's a dock written in [Haxe](http://haxe.org) that uses [SWHX](http://haxe.org/com/libs/swhx) but it can be built alone for the Flash player or thanks to [openFL](http://www.openfl.org/) for HTML5, Windows, Linux, Mac, iOS, Android
	
![Screenshot 1](http://mromecki.fr/blog/post/35/pic1.jpg)
	
## fdockhx.xml file

An input xml file looks like that :
	
	<fdock>
		<config minSize="32" maxSize="128" spread="3" delay="250" spacing="2" fontSize="20" location="top" hidden="true" />
		<shortcuts>
			<shortcut name="My Application 1" path="C:\path_to_my_app1\myApp1.exe" icon="data\icons\myApp1Icon.png" />
			<shortcut name="My Application 2" path="C:\path_to_my_app2\myApp2.exe" icon="data\icons\myApp2Icon.png" />
		</shortcuts>
	</fdock>
	
## Building from sources

You'll need these modified libs in order to build from Haxe 3 compatibles sources using SWHX :

 * [SWHX](https://github.com/filt3rek/swhx)
 * [Systools](https://github.com/filt3rek/systools)
