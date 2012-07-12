OctoPack.MigratorDotnet
=======================

The package is used to create an migrations project that is ready for Octopus Deploy. I gave it the name OctoPack.MigratorDotnet to make it easy to find even though it is not part based on the other OctoPack packages. I have "borrowed" some of the powershell code from the OctoPack project to get this one up and running faster.
To use the finished package install from [http://www.nuget.org](nuget.org), used the package manager console so the install script is run. The script will configure the items added so they are copied to output and create a nuspec file for you if you don't already have one.