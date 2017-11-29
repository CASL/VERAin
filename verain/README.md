Welcome to the VERAIN directory!

Here are some instructions to help find your way.

1. Run the parser

  The parser is a perl script and is located in the scripts directory.  
  Run the parser with a command line like the following:

    $PATH/scripts/react2xml.pl $CASE.inp $CASE.xml

  where $PATH is the path to the directory and $CASE is base name of your
  input file.

2. Look for example cases

   Look in the following directories:

     test           - main example directory

3. Add additional input parameters to input

   For most cases, you only need to modify the template files found in:
      scripts/Templates

   You will generally need to modify two files.

     Directory.yml  gives a description of how to read the input cards
     BLOCK.yml      gives a description of how to convert input cards to
                     parameter names for a particular BLOCK

4. Add or modify test cases

   Whenever you add new input cards, you must add a test case!!!

   To add a test case, either modify an existing test case or add a new one.
   It is preferable to modify an existing case, just make sure you don't
      screw up another test that might use the case.

   There is a special input deck called "misc_options.inp" that contains a
   bunch of random input variables.  The only purpose of this test is to make
   sure something gets written to the XML file correctly.  Try to use this test
   case if you can instead of creating something new.

   Once you add or modify a test case, add a "gold" xml file to go along with it.

   Modify the CMakeLists.txt file in this directory and add another entry to
   the long list of "ADD_REACTOR_AWARE_INPUT_PARSER_TEST" cases.

   Make sure you run the checkin test script to commit the changes!



5. If this file is not useful to you, please modify it to make it better.


