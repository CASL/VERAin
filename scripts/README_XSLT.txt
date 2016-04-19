Viewer for Parameter List files
 
The Parameter List (PL) XML files can be formatted for an easier
viewing in your browser by their internal XSLT engines using the XSLT
file:

PL9.xsl

The reformatting/transformation occurs automatically when you open the
PL XML file in the browser due to header entry in the PL XML file:

<?xml-stylesheet version="1.0" type="text/xsl" href="PL9.xsl"?>

This line makes the browser use PL9.xsl for the transformation of the
XML file. If you want to see the actual PL XML file content, use
'View Source' option in the browser. The same approach will work if you
download the PL XML files and the XSLT file, PL9.xsl, to your computer
and then open the PL XML files using e.g. Firefox:
right-click on the file->Open with->Firefox.
PL9.xsl has to be in the same folder as the PL XML files.

Verified browsers/system:

Safari - mac
Chrome - mac
Firefox - mac/windows/linux(ubuntu)
Opera - mac/ios

Try Firefox first.

Chrome requires switch:
--allow-file-access-from-files
Run Chrome in Mac OS X as:
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --allow-file-access-from-files
