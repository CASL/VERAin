Welcome to the VERAIN directory!

Here are some instructions to help find your way.

1. Run the parser

  The parser is a perl script and is located in the scripts directory.  
  Run the parser with a command line like the following:

    $PATH/scripts/react2xml.pl --init $CASE.inp $CASE.xml

  where $PATH is the path to the directory and $CASE is base name of your
  input file.

2. Look for example cases

   Look in the following directories:

     Progression_Problems - sample input decks

3. Add additional input parameters to input

   For most cases, you only need to modify the template files found in:
      scripts/Templates

   You will generally need to modify two files.

     Directory.yml  gives a description of how to read the input cards
     BLOCK.yml      gives a description of how to convert input cards to
                     parameter names for a particular BLOCK


4. If this file is not useful to you, please modify it to make it better.


